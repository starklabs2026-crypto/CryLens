import SwiftUI
import GoogleSignIn

enum AppConfig {
    private static let defaultSupportEmail = "starklabs2026@gmail.com"
    private static let defaultSupportURL = "https://starklabs2026-crypto.github.io/CryLens/support.html"
    private static let defaultPrivacyPolicyURL = "https://starklabs2026-crypto.github.io/CryLens/privacy.html"
    private static let defaultTermsOfUseURL = "https://starklabs2026-crypto.github.io/CryLens/terms.html"

    private static func infoString(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return ""
        }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isPlaceholder(_ value: String) -> Bool {
        value.isEmpty || value.contains("YOUR_") || value.contains("REPLACE_WITH")
    }

    static let googleClientID = infoString("GoogleClientID")
    static let revenueCatAPIKey = infoString("RevenueCatAPIKey")
    static let supportEmail = infoString("SupportEmail").isEmpty ? defaultSupportEmail : infoString("SupportEmail")
    static let supportURLString = infoString("SupportURL").isEmpty ? defaultSupportURL : infoString("SupportURL")
    static let privacyPolicyURLString = infoString("PrivacyPolicyURL").isEmpty ? defaultPrivacyPolicyURL : infoString("PrivacyPolicyURL")
    static let termsOfUseURLString = infoString("TermsOfUseURL").isEmpty ? defaultTermsOfUseURL : infoString("TermsOfUseURL")

    static let isGoogleSignInConfigured = !isPlaceholder(googleClientID)
    static let isRevenueCatConfigured = !isPlaceholder(revenueCatAPIKey)
    static let supportURL = URL(string: supportURLString)
    static let privacyPolicyURL = URL(string: privacyPolicyURLString)
    static let termsOfUseURL = URL(string: termsOfUseURLString)
}

@main
struct CryLensApp: App {
    @StateObject private var appState = AppState()

    init() {
        SubscriptionService.shared.configure()
        if AppConfig.isGoogleSignInConfigured {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: AppConfig.googleClientID)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isLoggedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}
