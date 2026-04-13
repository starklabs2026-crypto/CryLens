import Foundation

struct User: Codable {
    let id: String
    let name: String
    let email: String
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct Baby: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let dob: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case dob
    }
}

struct CryAnalysis: Codable, Identifiable {
    let id: String
    let babyId: String
    let label: String
    let confidence: Double
    let durationSec: Int
    let notes: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case label
        case confidence
        case durationSec = "duration_sec"
        case notes
        case createdAt = "created_at"
    }
}

struct NewCryAnalysis: Codable {
    let babyId: String
    let label: String
    let confidence: Double
    let durationSec: Int
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case babyId = "baby_id"
        case label
        case confidence
        case durationSec = "duration_sec"
        case notes
    }
}

struct CryStats: Codable {
    let totalAnalyses: Int
    let topLabel: String?
    let avgConfidence: Double
    let breakdown: [String: Int]

    enum CodingKeys: String, CodingKey {
        case totalAnalyses = "total_analyses"
        case topLabel = "top_label"
        case avgConfidence = "avg_confidence"
        case breakdown
    }
}

// Wrapper for paginated history response
struct HistoryResponse: Codable {
    let total: Int
    let analyses: [CryAnalysis]
}
