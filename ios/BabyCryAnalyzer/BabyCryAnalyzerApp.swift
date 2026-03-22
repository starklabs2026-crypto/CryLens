import SwiftUI

@main
struct BabyCryAnalyzerApp: App {
    @State private var historyStore = CryHistoryStore()
    @State private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(historyStore)
                .environment(authService)
        }
    }
}
