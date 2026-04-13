import SwiftUI
import GoogleSignIn

enum AppConfig {
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

    static let isGoogleSignInConfigured = !isPlaceholder(googleClientID)
    static let isRevenueCatConfigured = !isPlaceholder(revenueCatAPIKey)
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
