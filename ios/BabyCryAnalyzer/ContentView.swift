import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        Group {
            if authService.isCheckingSession {
                authenticationLoadingView
            } else if authService.isAuthenticated {
                mainTabs
            } else {
                SignInView()
            }
        }
        .animation(.smooth(duration: 0.3), value: authService.isCheckingSession)
        .animation(.smooth(duration: 0.3), value: authService.isAuthenticated)
    }

    private var mainTabs: some View {
        TabView {
            Tab("Listen", systemImage: "waveform") {
                ListenView()
            }

            Tab("History", systemImage: "clock") {
                HistoryView()
            }
        }
        .tint(Color(.label))
    }

    private var authenticationLoadingView: some View {
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
