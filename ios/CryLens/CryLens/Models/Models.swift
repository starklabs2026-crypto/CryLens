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

struct MeResponse: Codable {
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

struct FreeAnalysisUsageResponse: Codable {
    let freeAnalysesUsed: Int
    let freeAnalysisLimit: Int
    let remainingFreeAnalyses: Int
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

// MARK: - Date Helpers

enum AppDate {
    private static let isoFormatters: [ISO8601DateFormatter] = {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]

        return [fractional, standard]
    }()

    static func parse(_ value: String) -> Date? {
        for formatter in isoFormatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    static func babyAgeString(from value: String, now: Date = Date()) -> String {
        guard let date = parse(value) else { return value }

        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date, to: now)
        if let years = comps.year, years > 0 {
            return "\(years) yr\(years == 1 ? "" : "s") old"
        }
        if let months = comps.month, months > 0 {
            return "\(months) mo old"
        }
        if let days = comps.day {
            return "\(days) day\(days == 1 ? "" : "s") old"
        }
        return value
    }
}
