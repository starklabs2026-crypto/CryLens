import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?

    init() {
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
    }

    func logout() {
        KeychainService.deleteToken()
        currentUser = nil
        isLoggedIn = false
        SubscriptionService.shared.logout()
    }

    // Restore user object from the server after a cold launch.
    // If the token has expired, the 401 triggers a clean logout.
    private func restoreUser() async {
        do {
            let response: MeResponse = try await APIService.shared.me()
            currentUser = response.user
            SubscriptionService.shared.login(userId: response.user.id)
        } catch APIError.unauthorized {
            logout()
        } catch {
            // Network offline on launch — keep logged-in state, user loads lazily
        }
    }
}
