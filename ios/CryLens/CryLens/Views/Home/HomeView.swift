import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            RecordView()
                .tabItem { Label("Record", systemImage: "waveform") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Color(hex: "FF6B6B"))
    }
}
