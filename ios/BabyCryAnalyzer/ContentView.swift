import SwiftUI

struct ContentView: View {
    var store: StoreViewModel

    var body: some View {
        TabView {
            Tab("Listen", systemImage: "waveform") {
                ListenView(store: store)
            }
            Tab("History", systemImage: "clock") {
                HistoryView()
            }
            Tab("Profile", systemImage: "person.circle") {
                ProfileView(store: store)
            }
        }
        .tint(Color(.label))
    }
}
