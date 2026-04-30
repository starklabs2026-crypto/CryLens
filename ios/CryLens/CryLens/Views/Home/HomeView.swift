import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selection: HomeTab = .record
    @State private var showPaywall = false

    enum HomeTab: Hashable {
        case record
        case history
        case profile
        case settings
    }

    var body: some View {
        TabView(selection: $selection) {
            RecordView()
                .tag(HomeTab.record)
                .tabItem { Label("Record", systemImage: "waveform") }

            HistoryView()
                .tag(HomeTab.history)
                .tabItem { Label("History", systemImage: "clock") }

            ProfileView()
                .tag(HomeTab.profile)
                .tabItem { Label("Profile", systemImage: "person") }

            SettingsView()
                .tag(HomeTab.settings)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Color(hex: "FF6B6B"))
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            #if DEBUG
            guard DebugLaunchOptions.isScreenshotMode else { return }

            selection = screenshotTabSelection
            if DebugLaunchOptions.showPaywall {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showPaywall = true
                }
            }
            #endif
        }
    }

    private var screenshotTabSelection: HomeTab {
        switch DebugLaunchOptions.screenshotTab {
        case "history":
            return .history
        case "profile":
            return .profile
        case "settings":
            return .settings
        default:
            return .record
        }
    }
}
