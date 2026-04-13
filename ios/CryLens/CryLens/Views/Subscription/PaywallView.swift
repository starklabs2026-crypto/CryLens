import SwiftUI
import RevenueCat

struct PaywallView: View {
    @StateObject private var sub = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: Plan = .annual
    @State private var isLoading = false
    @State private var errorMessage: String?

    enum Plan { case monthly, annual }

    private let coral = Color(hex: "FF6B6B")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // Hero
                    VStack(spacing: 8) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(coral)
                        Text("CryLens Pro")
                            .font(.largeTitle.bold())
                        Text("Understand every cry, unlimited.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Benefits
                    VStack(alignment: .leading, spacing: 14) {
                        BenefitRow(icon: "infinity",         text: "Unlimited cry analyses")
                        BenefitRow(icon: "clock.fill",       text: "Full history & trends")
                        BenefitRow(icon: "brain.fill",       text: "AI-powered audio analysis")
                        BenefitRow(icon: "square.and.arrow.up", text: "Import audio files")
                        BenefitRow(icon: "chart.bar.fill",   text: "Weekly & monthly stats")
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Plan cards
                    VStack(spacing: 12) {
                        planCard(.annual,
                                 title: "Annual",
                                 price: "$19.99 / year",
                                 sub: "Only $1.67/month · Save 67%",
                                 badge: "BEST VALUE")
                        planCard(.monthly,
                                 title: "Monthly",
                                 price: "$4.99 / month",
                                 sub: "Billed monthly, cancel anytime",
                                 badge: nil)
                    }

                    // CTA
                    Button(action: subscribe) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(coral)
                                .frame(height: 52)
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Start Free Trial")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .disabled(isLoading)

                    if let msg = errorMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button("Restore Purchases") {
                        Task { await restore() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Legal links
                    HStack(spacing: 8) {
                        Link("Privacy Policy",
                             destination: URL(string: "https://starklabs2026-crypto.github.io/CryLens/privacy")!)
                        Text("·").foregroundStyle(.secondary)
                        Link("Terms of Use",
                             destination: URL(string: "https://starklabs2026-crypto.github.io/CryLens/terms")!)
                        Text("·").foregroundStyle(.secondary)
                        Link("EULA",
                             destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task { await sub.fetchOffering() }
    }

    // MARK: - Plan Card

    @ViewBuilder
    private func planCard(_ plan: Plan, title: String, price: String,
                          sub: String, badge: String?) -> some View {
        let selected = selectedPlan == plan
        Button { selectedPlan = plan } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title).font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(coral).foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(sub).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(price).font(.subheadline.bold())
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? coral : Color(.systemGray3))
                    .font(.title3)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selected ? coral : Color(.systemGray4),
                                    lineWidth: selected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func subscribe() {
        Task {
            isLoading = true
            errorMessage = nil

            if let offering = sub.currentOffering {
                let identifier = selectedPlan == .annual ? "$rc_annual" : "$rc_monthly"
                let pkg = offering.package(identifier: identifier)
                    ?? (selectedPlan == .annual ? offering.annual : offering.monthly)
                    ?? offering.availablePackages.first

                if let pkg {
                    do {
                        try await sub.purchase(package: pkg)
                        if sub.isPro { dismiss() }
                    } catch {
                        if (error as NSError).code != 2 {
                            errorMessage = error.localizedDescription
                        }
                    }
                } else {
                    errorMessage = "No packages available. Check App Store Connect."
                }
            } else {
                errorMessage = "Subscription unavailable. Set your RevenueCat API key and App Store products."
            }

            isLoading = false
        }
    }

    private func restore() async {
        isLoading = true
        errorMessage = nil
        do {
            try await sub.restorePurchases()
            if sub.isPro { dismiss() }
            else { errorMessage = "No active subscription found." }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let text: String
    private let coral = Color(hex: "FF6B6B")

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(coral)
                .frame(width: 24)
            Text(text).font(.subheadline)
            Spacer()
        }
    }
}
