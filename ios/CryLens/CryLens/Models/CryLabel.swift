import SwiftUI

enum CryLabel: String, CaseIterable, Codable {
    case hungry
    case tired
    case pain
    case burping
    case discomfort

    var emoji: String {
        switch self {
        case .hungry:     return "🍼"
        case .tired:      return "😴"
        case .pain:       return "😢"
        case .burping:    return "💨"
        case .discomfort: return "😣"
        }
    }

    var symbolName: String {
        switch self {
        case .hungry:     return "fork.knife.circle.fill"
        case .tired:      return "moon.zzz.fill"
        case .pain:       return "heart.circle.fill"
        case .burping:    return "wind.circle.fill"
        case .discomfort: return "exclamationmark.triangle.fill"
        }
    }

    var displayName: String {
        switch self {
        case .hungry:     return "Hungry"
        case .tired:      return "Tired"
        case .pain:       return "Pain"
        case .burping:    return "Needs Burping"
        case .discomfort: return "Discomfort"
        }
    }

    var color: Color {
        switch self {
        case .hungry:     return .orange
        case .tired:      return .indigo
        case .pain:       return .red
        case .burping:    return .green
        case .discomfort: return .purple
        }
    }

    var description: String {
        switch self {
        case .hungry:
            return "Your baby is likely hungry — it may be time to feed them."
        case .tired:
            return "Your baby sounds tired and may need to be put down for a nap or sleep."
        case .pain:
            return "Your baby may be in pain or discomfort — check for any obvious causes such as colic or injury."
        case .burping:
            return "Your baby probably needs to be burped — try holding them upright and patting their back."
        case .discomfort:
            return "Your baby seems uncomfortable — check their nappy, clothing, or environment for irritants."
        }
    }
}
