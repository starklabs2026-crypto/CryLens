import SwiftUI

struct ProfileView: View {
    var store: StoreViewModel
    @Environment(AuthService.self) private var authService
    @Environment(CryHistoryStore.self) private var historyStore
    @State private var showSignOutAlert: Bool = false
    @State private var showPaywall: Bool = false

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
                            Text(store.isPremium ? "Pro Member" : "Free Plan")
                                .font(.caption)
                                .foregroundStyle(store.isPremium ? .green : .secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                if !store.isPremium {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Pro")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                    Text("Unlimited analyses & full history")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                Section("Your Stats") {
                    LabeledContent("Total Analyses", value: "\(historyStore.analyses.count)")
                    LabeledContent("This Week", value: "\(historyStore.analysesThisWeek)")
                    LabeledContent("Most Common", value: historyStore.mostCommonReason)
                }

                if store.isPremium {
                    Section("Subscription") {
                        LabeledContent("Status", value: "Active")
                            .foregroundStyle(.green)
                        Button("Manage Subscription") {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
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
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out?", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task { await authService.signOut() }
            }
        } message: {
            Text("You will be signed out of your account.")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store)
        }
    }
}
