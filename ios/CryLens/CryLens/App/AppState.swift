import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var analysisCount: Int = 0
    @Published var freeAnalysisLimit: Int = 5

    var remainingFreeAnalyses: Int {
        max(0, freeAnalysisLimit - analysisCount)
    }

    var hasFreeAnalysisAccess: Bool {
        SubscriptionService.shared.isPro || analysisCount < freeAnalysisLimit
    }

    init() {
        #if DEBUG
        if DebugLaunchOptions.isScreenshotMode {
            KeychainService.deleteToken()
            currentUser = DebugLaunchOptions.screenshotUser
            isLoggedIn = true
            return
        }
        #endif

        if let token = KeychainService.getToken(), !token.isEmpty {
            isLoggedIn = true
            Task { await restoreUser() }
        }
    }

    func login(with response: AuthResponse) {
        KeychainService.saveToken(response.token)
        currentUser = response.user
        isLoggedIn = true
        SubscriptionService.shared.login(userId: response.user.id)
        Task { await refreshAnalysisUsage() }
    }

    func logout() {
        KeychainService.deleteToken()
        currentUser = nil
        isLoggedIn = false
        analysisCount = 0
        SubscriptionService.shared.logout()
    }

    func refreshAnalysisUsage() async {
        guard isLoggedIn else {
            analysisCount = 0
            freeAnalysisLimit = 5
            return
        }

        do {
            let usage = try await APIService.shared.getFreeAnalysisUsage()
            analysisCount = usage.freeAnalysesUsed
            freeAnalysisLimit = usage.freeAnalysisLimit
        } catch {
            // Keep the last known count if the network is temporarily unavailable.
        }
    }

    // Restore user object from the server after a cold launch.
    // If the token has expired, the 401 triggers a clean logout.
    private func restoreUser() async {
        do {
            let response: MeResponse = try await APIService.shared.me()
            currentUser = response.user
            SubscriptionService.shared.login(userId: response.user.id)
            await refreshAnalysisUsage()
        } catch APIError.unauthorized {
            logout()
        } catch {
            // Network offline on launch — keep logged-in state, user loads lazily
        }
    }
}
