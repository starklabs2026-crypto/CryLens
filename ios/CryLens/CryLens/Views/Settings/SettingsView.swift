import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var sub = SubscriptionService.shared

    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var isDeletingAccount = false
    @State private var deleteError: String?
    @State private var didApplyScreenshotFocus = false

    private let coral = Color(hex: "FF6B6B")

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
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
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("7-day trial")
                                            .font(.caption.bold())
                                            .foregroundStyle(coral)
                                        Text("Yearly saves 90%")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            HStack {
                                Text("Free analyses remaining")
                                Spacer()
                                Text("\(appState.remainingFreeAnalyses) of \(appState.freeAnalysisLimit)")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background((appState.remainingFreeAnalyses > 0 ? coral : Color.red).opacity(0.15))
                                    .foregroundStyle(appState.remainingFreeAnalyses > 0 ? coral : .red)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    // MARK: Sign In Options
                    Section(header: Text("Sign-In Methods")) {
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
                    }

                    // MARK: Account
                    Section {
                        if let err = deleteError {
                            Text(err).foregroundStyle(.red).font(.caption)
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete Account")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                        .id("settings-account-delete")
                    } footer: {
                        Text("Account deletion is permanent and removes your profile, babies, and cry history.")
                            .font(.caption2)
                    }
                }
                .navigationTitle("Settings")
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
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
                .task {
                    if sub.isConfigured {
                        await sub.refreshStatus()
                    }
                    await appState.refreshAnalysisUsage()
                }
                .onAppear {
                    #if DEBUG
                    guard DebugLaunchOptions.isScreenshotMode,
                          DebugLaunchOptions.screenshotTab == "settings",
                          DebugLaunchOptions.screenshotSettingsFocus == "account",
                          !didApplyScreenshotFocus else { return }

                    didApplyScreenshotFocus = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        proxy.scrollTo("settings-account-delete", anchor: .bottom)
                    }
                    #endif
                }
            }
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
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
