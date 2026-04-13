import Foundation

// Backend returns camelCase JSON — no custom CodingKeys needed for field mapping.
// All wrapper structs mirror the actual API envelope shapes.

struct User: Codable {
    let id: String
    let name: String
    let email: String?
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

// MARK: - Baby

struct Baby: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let dob: String          // ISO-8601 date string from Prisma
    let createdAt: String?
}

// API envelopes
struct BabiesResponse: Codable {
    let babies: [Baby]
}

struct BabyResponse: Codable {
    let baby: Baby
}

// MARK: - CryAnalysis

struct CryAnalysis: Codable, Identifiable {
    let id: String
    let babyId: String
    let label: String
    let confidence: Double
    let durationSec: Int
    let notes: String?
    let audioUrl: String?
    let createdAt: String
}

struct NewCryAnalysis: Codable {
    let babyId: String
    let label: String
    let confidence: Double
    let durationSec: Int
    let notes: String?
}

// API envelopes
struct AnalysisResponse: Codable {
    let analysis: CryAnalysis
}

// getHistory returns { data: [...], meta: { total, page, limit, totalPages } }
struct HistoryMeta: Codable {
    let total: Int
    let page: Int
    let limit: Int
    let totalPages: Int
}

struct HistoryResponse: Codable {
    let data: [CryAnalysis]
    let meta: HistoryMeta
}

// MARK: - Stats

struct CryStats: Codable {
    let totalAnalyses: Int
    let topLabel: String?
    let avgConfidence: Double
    let breakdown: [String: Int]
    let periodDays: Int?
}
