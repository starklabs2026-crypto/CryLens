import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case unauthorized
    case serverError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .noData:
            return "No data was returned from the server."
        case .unauthorized:
            return "You are not authorised. Please sign in again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .decodingError:
            return "Failed to decode the server response."
        }
    }
}

final class APIService {
    static let shared = APIService()
    private init() {}

    private let baseURL = "https://crylens-api-production.up.railway.app"
    // Backend returns camelCase — use default key decoding
    private let decoder = JSONDecoder()

    // MARK: - Request Building

    private func makeRequest(_ path: String, method: String = "GET", body: (any Encodable)? = nil) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainService.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }

    private func fetch<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.noData
        }

        if http.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(message)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodeErr {
            // Log raw response for debugging
            #if DEBUG
            if let raw = String(data: data, encoding: .utf8) {
                print("[APIService] Decode error: \(decodeErr)\nRaw: \(raw)")
            }
            #endif
            throw APIError.decodingError
        }
    }

    // MARK: - Auth

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable { let name, email, password: String }
        let req = try makeRequest("/auth/register", method: "POST", body: Body(name: name, email: email, password: password))
        return try await fetch(req)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable { let email, password: String }
        let req = try makeRequest("/auth/login", method: "POST", body: Body(email: email, password: password))
        return try await fetch(req)
    }

    // MARK: - Babies

    func getBabies() async throws -> [Baby] {
        let req = try makeRequest("/babies")
        // Backend: { babies: [...] }
        let wrapper: BabiesResponse = try await fetch(req)
        return wrapper.babies
    }

    func createBaby(name: String, dob: String) async throws -> Baby {
        struct Body: Encodable { let name, dob: String }
        let req = try makeRequest("/babies", method: "POST", body: Body(name: name, dob: dob))
        // Backend: { baby: {...} }
        let wrapper: BabyResponse = try await fetch(req)
        return wrapper.baby
    }

    // MARK: - Analyses

    func logAnalysis(_ analysis: NewCryAnalysis) async throws -> CryAnalysis {
        let req = try makeRequest("/analysis", method: "POST", body: analysis)
        // Backend: { analysis: {...} }
        let wrapper: AnalysisResponse = try await fetch(req)
        return wrapper.analysis
    }

    func getHistory(babyId: String? = nil) async throws -> [CryAnalysis] {
        var path = "/analysis/history"
        if let babyId {
            path += "?babyId=\(babyId)"
        }
        let req = try makeRequest(path)
        // Backend: { data: [...], meta: { total, page, limit, totalPages } }
        let wrapper: HistoryResponse = try await fetch(req)
        return wrapper.data
    }

    func getStats(babyId: String? = nil, days: Int = 30) async throws -> CryStats {
        var path = "/analysis/stats?periodDays=\(days)"
        if let babyId {
            path += "&babyId=\(babyId)"
        }
        let req = try makeRequest(path)
        return try await fetch(req)
    }

    func deleteAnalysis(id: String) async throws {
        let req = try makeRequest("/analysis/\(id)", method: "DELETE")
        // 204 No Content — nothing to decode
        _ = try await URLSession.shared.data(for: req)
    }
}
