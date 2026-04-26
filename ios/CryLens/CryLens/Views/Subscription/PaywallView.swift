import SwiftUI
import RevenueCat

struct PaywallView: View {
    @StateObject private var sub = SubscriptionService.shared
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: Plan = .yearly
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    enum Plan { case weekly, yearly }

    private let coral = Color(hex: "FF6B6B")
    private let weeklyPrice = 9.99
    private let yearlyPrice = 49.99

    private var annualizedWeeklyCost: Double { weeklyPrice * 52 }
    private var yearlyDiscountPercent: Int {
        let discount = ((annualizedWeeklyCost - yearlyPrice) / annualizedWeeklyCost) * 100
        return Int(discount.rounded())
    }
    private var yearlyEffectiveWeeklyPrice: String {
        String(format: "$%.2f/week", yearlyPrice / 52)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // Hero
                    VStack(spacing: 8) {
                        CryLensLogo(size: 92)
                        Text("CryLens Pro")
                            .font(.largeTitle.bold())
                        Text("Understand every cry, unlimited.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if !sub.isPro {
                            Text(appState.remainingFreeAnalyses > 0
                                 ? "\(appState.remainingFreeAnalyses) free analyses remaining"
                                 : "Your free analyses are used up")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(appState.remainingFreeAnalyses > 0 ? coral : .red)
                        }
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
                        planCard(.yearly,
                                 title: "Yearly",
                                 price: "$49.99 / year",
                                 sub: "7-day free trial · Save \(yearlyDiscountPercent)%",
                                 badge: "7-DAY TRIAL")
                        planCard(.weekly,
                                 title: "Weekly",
                                 price: "$9.99 / week",
                                 sub: "No trial · Cancel anytime",
                                 badge: nil)
                    }

                    Text("Yearly works out to \(yearlyEffectiveWeeklyPrice) instead of $9.99/week, a \(yearlyDiscountPercent)% discount versus paying weekly all year.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // CTA
                    Button(action: subscribe) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(coral)
                                .frame(height: 52)
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(selectedPlan == .yearly ? "Start 7-Day Free Trial" : "Subscribe Weekly")
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

                    Text(selectedPlan == .yearly
                         ? "After the 7-day trial, CryLens Pro renews at $49.99/year unless cancelled at least 24 hours before renewal."
                         : "CryLens Pro renews at $9.99/week unless cancelled at least 24 hours before renewal.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // Legal links
                    HStack(spacing: 8) {
                        if let privacyURL = AppConfig.privacyPolicyURL {
                            Link("Privacy Policy", destination: privacyURL)
                            Text("·").foregroundStyle(.secondary)
                        }
                        if let termsURL = AppConfig.termsOfUseURL {
                            Link("Terms of Use", destination: termsURL)
                            Text("·").foregroundStyle(.secondary)
                        }
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
        .task {
            if sub.isConfigured {
                await sub.refreshStatus()
                await sub.fetchOffering()
            }
        }
        .alert("Subscription Confirmed", isPresented: $showSuccessAlert) {
            Button("Continue") {
                dismiss()
            }
        } message: {
            Text("Enjoy CryLens Pro.")
        }
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
                let identifier = selectedPlan == .yearly ? "$rc_annual" : "$rc_weekly"
                let pkg = offering.package(identifier: identifier)
                    ?? (selectedPlan == .yearly ? offering.annual : offering.weekly)
                    ?? offering.availablePackages.first

                if let pkg {
                    do {
                        try await sub.purchase(package: pkg)
                        if sub.isPro {
                            showSuccessAlert = true
                        } else {
                            errorMessage = "Purchase completed, but Pro has not unlocked yet. Tap Restore Purchases or reopen the app in a few seconds."
                        }
                    } catch {
                        if (error as NSError).code != 2 {
                            errorMessage = error.localizedDescription
                        }
                    }
                } else {
                    errorMessage = "No packages available. Check App Store Connect."
                }
            } else {
                errorMessage = "Subscription unavailable. Add your RevenueCat iOS public SDK key and offerings."
            }

            isLoading = false
        }
    }

    private func restore() async {
        isLoading = true
        errorMessage = nil
        do {
            try await sub.restorePurchases()
            if sub.isPro { showSuccessAlert = true }
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
