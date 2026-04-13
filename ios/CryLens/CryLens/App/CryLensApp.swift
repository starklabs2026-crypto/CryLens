import SwiftUI
import GoogleSignIn

@main
struct CryLensApp: App {
    @StateObject private var appState = AppState()

    init() {
        SubscriptionService.shared.configure()
        // TODO: Replace with your iOS client ID from Google Cloud Console
        // https://console.cloud.google.com → APIs & Services → Credentials → iOS OAuth 2.0 Client
        let config = GIDConfiguration(clientID: "YOUR_GOOGLE_IOS_CLIENT_ID.apps.googleusercontent.com")
        GIDSignIn.sharedInstance.configuration = config
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
