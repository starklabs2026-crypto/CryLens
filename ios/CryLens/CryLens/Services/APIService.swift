import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case unauthorized
    case serverError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "The request URL was invalid."
        case .noData:                return "No data was returned from the server."
        case .unauthorized:          return "You are not authorised. Please sign in again."
        case .serverError(let msg):  return "Server error: \(msg)"
        case .decodingError:         return "Failed to decode the server response."
        }
    }
}

final class APIService {
    static let shared = APIService()
    private init() {}

    private let baseURL = "https://crylens-api-production.up.railway.app"
    private let decoder = JSONDecoder()  // Backend is camelCase — default decoding

    // MARK: - Request Building

    private func makeRequest(_ path: String,
                              method: String = "GET",
                              body: (any Encodable)? = nil) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainService.getToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body { req.httpBody = try JSONEncoder().encode(body) }
        return req
    }

    private func fetch<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.noData }

        if http.statusCode == 401 { throw APIError.unauthorized }

        guard (200..<300).contains(http.statusCode) else {
            throw APIError.serverError(String(data: data, encoding: .utf8) ?? "Unknown")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let e {
            #if DEBUG
            print("[APIService] Decode error: \(e)\nRaw: \(String(data: data, encoding: .utf8) ?? "")")
            #endif
            throw APIError.decodingError
        }
    }

    // MARK: - Auth

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable { let name, email, password: String }
        return try await fetch(try makeRequest("/auth/register", method: "POST",
                                               body: Body(name: name, email: email, password: password)))
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable { let email, password: String }
        return try await fetch(try makeRequest("/auth/login", method: "POST",
                                               body: Body(email: email, password: password)))
    }

    func loginWithApple(identityToken: String, name: String?) async throws -> AuthResponse {
        struct Body: Encodable { let identityToken: String; let name: String? }
        return try await fetch(try makeRequest("/auth/apple", method: "POST",
                                               body: Body(identityToken: identityToken, name: name)))
    }

    func loginWithGoogle(idToken: String) async throws -> AuthResponse {
        struct Body: Encodable { let idToken: String }
        return try await fetch(try makeRequest("/auth/google", method: "POST",
                                               body: Body(idToken: idToken)))
    }

    func me() async throws -> MeResponse {
        return try await fetch(try makeRequest("/auth/me"))
    }

    func deleteAccount() async throws {
        let req = try makeRequest("/auth/me", method: "DELETE")
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Babies

    func getBabies() async throws -> [Baby] {
        let r: BabiesResponse = try await fetch(try makeRequest("/babies"))
        return r.babies
    }

    func createBaby(name: String, dob: String) async throws -> Baby {
        struct Body: Encodable { let name, dob: String }
        let r: BabyResponse = try await fetch(try makeRequest("/babies", method: "POST",
                                                               body: Body(name: name, dob: dob)))
        return r.baby
    }

    func updateBaby(id: String, name: String, dob: String) async throws -> Baby {
        struct Body: Encodable { let name, dob: String }
        let r: BabyResponse = try await fetch(try makeRequest("/babies/\(id)", method: "PUT",
                                                               body: Body(name: name, dob: dob)))
        return r.baby
    }

    func deleteBaby(id: String) async throws {
        _ = try await URLSession.shared.data(for: try makeRequest("/babies/\(id)", method: "DELETE"))
    }

    // MARK: - Analyses

    func logAnalysis(_ analysis: NewCryAnalysis) async throws -> CryAnalysis {
        let r: AnalysisResponse = try await fetch(try makeRequest("/analysis", method: "POST", body: analysis))
        return r.analysis
    }

    func getHistory(babyId: String? = nil) async throws -> [CryAnalysis] {
        var path = "/analysis/history"
        if let babyId { path += "?babyId=\(babyId)" }
        let r: HistoryResponse = try await fetch(try makeRequest(path))
        return r.data
    }

    func getStats(babyId: String? = nil, days: Int = 30) async throws -> CryStats {
        var path = "/analysis/stats?periodDays=\(days)"
        if let babyId { path += "&babyId=\(babyId)" }
        return try await fetch(try makeRequest(path))
    }

    func deleteAnalysis(id: String) async throws {
        _ = try await URLSession.shared.data(for: try makeRequest("/analysis/\(id)", method: "DELETE"))
    }

    // MARK: - Audio Upload + AI Analysis

    func getUploadURL(babyId: String, fileName: String, mimeType: String) async throws -> UploadURLResponse {
        struct Body: Encodable { let babyId, fileName, mimeType: String }
        return try await fetch(try makeRequest("/analysis/upload-url", method: "POST",
                                               body: Body(babyId: babyId, fileName: fileName, mimeType: mimeType)))
    }

    func uploadAudioFile(to signedURL: String, fileURL: URL, mimeType: String) async throws {
        guard let url = URL(string: signedURL) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        let data = try Data(contentsOf: fileURL)
        let (_, response) = try await URLSession.shared.upload(for: req, from: data)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Audio upload failed")
        }
    }

    func analyzeAudio(babyId: String, audioPath: String, durationSec: Int) async throws -> CryAnalysis {
        struct Body: Encodable { let babyId, audioPath: String; let durationSec: Int }
        let r: AIAnalysisResponse = try await fetch(
            try makeRequest("/analysis/analyze", method: "POST",
                            body: Body(babyId: babyId, audioPath: audioPath, durationSec: durationSec)))
        return r.analysis
    }
}
