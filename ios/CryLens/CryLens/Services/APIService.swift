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
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

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
        } catch {
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
        return try await fetch(req)
    }

    func createBaby(name: String, dob: String) async throws -> Baby {
        struct Body: Encodable { let name, dob: String }
        let req = try makeRequest("/babies", method: "POST", body: Body(name: name, dob: dob))
        return try await fetch(req)
    }

    // MARK: - Analyses

    func logAnalysis(_ analysis: NewCryAnalysis) async throws -> CryAnalysis {
        let req = try makeRequest("/analyses", method: "POST", body: analysis)
        return try await fetch(req)
    }

    func getHistory(babyId: String? = nil) async throws -> [CryAnalysis] {
        var path = "/analyses"
        if let babyId {
            path += "?baby_id=\(babyId)"
        }
        let req = try makeRequest(path)
        // Unwrap paginated response
        let wrapper: HistoryResponse = try await fetch(req)
        return wrapper.analyses
    }

    func getStats(babyId: String? = nil, days: Int = 30) async throws -> CryStats {
        var path = "/analyses/stats?days=\(days)"
        if let babyId {
            path += "&baby_id=\(babyId)"
        }
        let req = try makeRequest(path)
        return try await fetch(req)
    }

    func deleteAnalysis(id: String) async throws {
        let req = try makeRequest("/analyses/\(id)", method: "DELETE")
        // DELETE returns 204 No Content — use a dummy Decodable
        struct Empty: Decodable {}
        let _: Empty? = try? await fetch(req)
    }
}
