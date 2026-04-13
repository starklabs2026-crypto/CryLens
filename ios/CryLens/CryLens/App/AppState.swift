import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?

    init() {
        if let token = KeychainService.getToken(), !token.isEmpty {
            isLoggedIn = true
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
}
