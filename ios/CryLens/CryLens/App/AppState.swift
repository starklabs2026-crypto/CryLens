import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?

    init() {
        if let token = KeychainService.getToken(), !token.isEmpty {
            // Token exists; mark as logged in. User details will be loaded on demand.
            isLoggedIn = true
        }
    }

    func login(with response: AuthResponse) {
        KeychainService.saveToken(response.token)
        currentUser = response.user
        isLoggedIn = true
    }

    func logout() {
        KeychainService.deleteToken()
        currentUser = nil
        isLoggedIn = false
    }
}
