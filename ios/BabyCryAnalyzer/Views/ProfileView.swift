import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @Environment(CryHistoryStore.self) private var historyStore
    @State private var showSignOutAlert: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.accentColor)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(authService.currentUserEmail ?? "Account")
                                .font(.subheadline.bold())
                            Text("Member")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Your Stats") {
                    LabeledContent("Total Analyses", value: "\(historyStore.analyses.count)")
                    LabeledContent("This Week", value: "\(historyStore.analysesThisWeek)")
                    LabeledContent("Most Common", value: historyStore.mostCommonReason)
                }

                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
        }
        .alert("Sign Out?", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task { await authService.signOut() }
            }
        } message: {
            Text("You will be signed out of your account.")
        }
    }
}
