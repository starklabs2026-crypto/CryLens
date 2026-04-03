import SwiftUI
import RevenueCat

@main
struct BabyCryAnalyzerApp: App {
    @State private var authService: AuthService = AuthService()

    init() {
        guard AppConfig.revenueCatEnabled else { return }

        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey)
    }

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
    @State private var storeVM: StoreViewModel = StoreViewModel()

    init(userId: String) {
        _historyStore = State(initialValue: CryHistoryStore(userId: userId))
    }

    var body: some View {
        ContentView(store: storeVM)
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
