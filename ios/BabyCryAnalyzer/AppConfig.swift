import Foundation

enum AppConfig {
    private static func value(for keys: [String], default defaultValue: String = "") -> String {
        let environment = ProcessInfo.processInfo.environment

        for key in keys {
            if let envValue = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !envValue.isEmpty {
                return envValue
            }

            if let infoValue = Bundle.main.object(forInfoDictionaryKey: key) as? String {
                let trimmed = infoValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }

        return defaultValue
    }

    static let supabaseURL: String = {
        value(
            for: ["EXPO_PUBLIC_SUPABASE_URL", "SUPABASE_URL"],
            default: "https://cmtlwxpqgrslnknlmraf.supabase.co"
        )
    }()

    static let supabaseAnonKey: String = {
        value(
            for: ["EXPO_PUBLIC_SUPABASE_ANON_KEY", "SUPABASE_ANON_KEY"],
            default: "sb_publishable_JrKkHoWXTDMfPmf0iuDwHA_KWrTfKXG"
        )
    }()

    /// Set `EXPO_PUBLIC_OPENAI_API_KEY` or `OPENAI_API_KEY` in the Xcode scheme or environment.
    static let openAIAPIKey: String = {
        value(for: ["EXPO_PUBLIC_OPENAI_API_KEY", "OPENAI_API_KEY"])
    }()

    static let revenueCatAPIKey: String = {
        #if DEBUG
        return value(
            for: [
                "EXPO_PUBLIC_REVENUECAT_TEST_API_KEY",
                "REVENUECAT_TEST_API_KEY",
                "EXPO_PUBLIC_REVENUECAT_IOS_API_KEY",
                "REVENUECAT_IOS_API_KEY"
            ]
        )
        #else
        return value(
            for: [
                "EXPO_PUBLIC_REVENUECAT_IOS_API_KEY",
                "REVENUECAT_IOS_API_KEY",
                "EXPO_PUBLIC_REVENUECAT_TEST_API_KEY",
                "REVENUECAT_TEST_API_KEY"
            ]
        )
        #endif
    }()

    static let revenueCatEnabled: Bool = !revenueCatAPIKey.isEmpty
}
