import Foundation

// Backend returns camelCase JSON — no custom CodingKeys needed.

// MARK: - Auth

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
    let dob: String
    let createdAt: String?
}

struct BabiesResponse: Codable { let babies: [Baby] }
struct BabyResponse: Codable   { let baby: Baby }

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

struct AnalysisResponse: Codable { let analysis: CryAnalysis }

struct HistoryMeta: Codable {
    let total, page, limit, totalPages: Int
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

// MARK: - Upload / AI Analysis

struct UploadURLResponse: Codable {
    let uploadUrl: String
    let path: String
    let token: String
}

struct AIAnalysisResult: Codable {
    let label: String
    let confidence: Double
    let notes: String?
}

struct AIAnalysisResponse: Codable {
    let analysis: CryAnalysis
    let aiResult: AIAnalysisResult
}
