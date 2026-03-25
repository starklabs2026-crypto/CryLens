import Foundation

enum AppConfig {
    static let supabaseURL: String = {
        let value = Config.allValues["EXPO_PUBLIC_SUPABASE_URL"] ?? ""
        return value.isEmpty ? "https://cmtlwxpqgrslnknlmraf.supabase.co" : value
    }()

    static let supabaseAnonKey: String = {
        let value = Config.allValues["EXPO_PUBLIC_SUPABASE_ANON_KEY"] ?? ""
        return value.isEmpty ? "sb_publishable_JrKkHoWXTDMfPmf0iuDwHA_KWrTfKXG" : value
    }()

    /// OpenAI API key — set EXPO_PUBLIC_OPENAI_API_KEY in Rork's Environment Variables panel
    static let openAIAPIKey: String = {
        let value = Config.allValues["EXPO_PUBLIC_OPENAI_API_KEY"] ?? ""
        return value
    }()
}
