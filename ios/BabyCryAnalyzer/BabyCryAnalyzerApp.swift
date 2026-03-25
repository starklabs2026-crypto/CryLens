import SwiftUI

@main
struct BabyCryAnalyzerApp: App {
    @State private var authService: AuthService = AuthService()

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isCheckingSession {
                    AuthenticationLoadingView()
                } else if authService.isAuthenticated {
                    AuthenticatedAppRootView(userId: authService.currentUserID ?? "local")
                        .id(authService.currentUserID ?? "local")
                } else {
                    SignInView()
                }
            }
            .environment(authService)
        }
    }
}

private struct AuthenticatedAppRootView: View {
    @State private var historyStore: CryHistoryStore

    init(userId: String) {
        _historyStore = State(initialValue: CryHistoryStore(userId: userId))
    }

    var body: some View {
        ContentView()
            .environment(historyStore)
    }
}

private struct AuthenticationLoadingView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)

                ProgressView()
                    .controlSize(.large)
                    .tint(.white)

                Text("Checking your session")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
