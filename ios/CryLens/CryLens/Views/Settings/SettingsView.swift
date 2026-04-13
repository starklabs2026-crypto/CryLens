import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var sub = SubscriptionService.shared

    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var isDeletingAccount = false
    @State private var deleteError: String?

    private let coral = Color(hex: "FF6B6B")

    var body: some View {
        NavigationStack {
            List {
                // MARK: Subscription
                Section(header: Text("Subscription")) {
                    if sub.isPro {
                        HStack {
                            Label("CryLens Pro", systemImage: "crown.fill")
                                .foregroundStyle(coral)
                            Spacer()
                            Text("Active")
                                .font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    } else {
                        Button { showPaywall = true } label: {
                            HStack {
                                Label("Upgrade to Pro", systemImage: "crown.fill")
                                    .foregroundStyle(coral)
                                Spacer()
                                Text("$4.99/mo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // MARK: Sign In Options
                Section(header: Text("Linked Accounts")) {
                    Label("Apple ID", systemImage: "apple.logo")
                    Label("Google", systemImage: "g.circle.fill")
                        .foregroundStyle(.blue)
                }

                // MARK: Legal
                Section(header: Text("Legal")) {
                    NavigationLink(destination: LegalView(page: .privacy)) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    NavigationLink(destination: LegalView(page: .terms)) {
                        Label("Terms of Use", systemImage: "doc.text.fill")
                    }
                    NavigationLink(destination: LegalView(page: .support)) {
                        Label("Support", systemImage: "questionmark.circle.fill")
                    }
                    Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                        Label("EULA (Apple Standard)", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.primary)
                    }
                }

                // MARK: About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(buildNumber).foregroundStyle(.secondary)
                    }
                }

                // MARK: Account
                Section(header: Text("Account")) {
                    if let err = deleteError {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .confirmationDialog("Delete Account",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete My Account", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your account, all babies, and all cry history. This cannot be undone.")
            }
            .overlay {
                if isDeletingAccount {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Deleting account…").font(.subheadline)
                        }
                        .padding(24)
                        .background(.regularMaterial)
                        .cornerRadius(16)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private func deleteAccount() async {
        isDeletingAccount = true
        deleteError = nil
        do {
            try await APIService.shared.deleteAccount()
            sub.logout()
            await MainActor.run { appState.logout() }
        } catch {
            await MainActor.run {
                deleteError = error.localizedDescription
                isDeletingAccount = false
            }
        }
    }
}
