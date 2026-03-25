import Foundation

nonisolated struct CryAnalysis: Identifiable, Codable, Sendable {
    let id: UUID
    let date: Date
    let reason: CryReason
    let confidence: Double
    let tip: String
    let durationSeconds: Int
    let averageDecibels: Float
    let transcript: String?
    let transcriptLanguage: String?
    // Detailed report fields (nil for analyses from older app versions)
    let detailedAnalysis: String?
    let urgency: CryUrgency?
    let recommendations: [String]?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        reason: CryReason,
        confidence: Double,
        tip: String,
        durationSeconds: Int,
        averageDecibels: Float,
        transcript: String? = nil,
        transcriptLanguage: String? = nil,
        detailedAnalysis: String? = nil,
        urgency: CryUrgency? = nil,
        recommendations: [String]? = nil
    ) {
        self.id = id
        self.date = date
        self.reason = reason
        self.confidence = confidence
        self.tip = tip
        self.durationSeconds = durationSeconds
        self.averageDecibels = averageDecibels
        self.transcript = transcript
        self.transcriptLanguage = transcriptLanguage
        self.detailedAnalysis = detailedAnalysis
        self.urgency = urgency
        self.recommendations = recommendations
    }
}

nonisolated enum CryUrgency: String, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var label: String {
        switch self {
        case .low: return "Routine"
        case .medium: return "Attention Needed"
        case .high: return "Urgent"
        }
    }

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

nonisolated enum CryReason: String, Codable, CaseIterable, Sendable {
    case hungry = "Hungry"
    case tired = "Tired"
    case uncomfortable = "Uncomfortable"
    case needsAttention = "Needs Attention"
    case pain = "Pain"
    case gassy = "Gassy"
    case overstimulated = "Overstimulated"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .hungry: return "fork.knife"
        case .tired: return "moon.zzz.fill"
        case .uncomfortable: return "thermometer.medium"
        case .needsAttention: return "heart.fill"
        case .pain: return "bandage.fill"
        case .gassy: return "wind"
        case .overstimulated: return "sparkles"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .hungry: return "hungry"
        case .tired: return "tired"
        case .uncomfortable: return "uncomfortable"
        case .needsAttention: return "attention"
        case .pain: return "pain"
        case .gassy: return "gassy"
        case .overstimulated: return "overstimulated"
        case .unknown: return "unknown"
        }
    }
}
