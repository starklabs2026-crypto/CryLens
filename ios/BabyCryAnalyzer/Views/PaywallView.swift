import SwiftUI
import RevenueCat

struct PaywallView: View {
    var store: StoreViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackage: Package?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Group {
                    if !store.isAvailable {
                        ContentUnavailableView {
                            Label("Subscriptions Unavailable", systemImage: "creditcard.trianglebadge.exclamationmark")
                        } description: {
                            Text("RevenueCat keys are not configured for this build.")
                        } actions: {
                            Button("Close") {
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                        }
                        .foregroundStyle(.white)
                    } else if store.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else if let current = store.offerings?.current {
                        ScrollView {
                            VStack(spacing: 0) {
                                Spacer().frame(height: 40)

                                Image(systemName: "waveform.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(.white)
                                    .symbolRenderingMode(.hierarchical)

                                Spacer().frame(height: 20)

                                Text("Unlock CrySense Pro")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(.white)

                                Spacer().frame(height: 8)

                                Text("Unlimited cry analysis for your baby")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.6))

                                Spacer().frame(height: 32)

                                VStack(spacing: 12) {
                                    featureRow(icon: "waveform", text: "Unlimited cry recordings")
                                    featureRow(icon: "brain.head.profile", text: "AI-powered cry analysis")
                                    featureRow(icon: "clock.arrow.circlepath", text: "Full history access")
                                    featureRow(icon: "doc.text", text: "Detailed insights & tips")
                                }
                                .padding(.horizontal, 24)

                                Spacer().frame(height: 36)

                                VStack(spacing: 12) {
                                    ForEach(current.availablePackages, id: \.identifier) { package in
                                        packageCard(package: package)
                                    }
                                }
                                .padding(.horizontal, 20)

                                Spacer().frame(height: 24)

                                Button {
                                    guard let pkg = selectedPackage else { return }
                                    Task { await store.purchase(package: pkg) }
                                } label: {
                                    Group {
                                        if store.isPurchasing {
                                            ProgressView()
                                                .tint(.black)
                                        } else {
                                            Text("Continue")
                                                .font(.headline)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(.white)
                                    .foregroundStyle(.black)
                                    .clipShape(.rect(cornerRadius: 14))
                                }
                                .disabled(selectedPackage == nil || store.isPurchasing)
                                .opacity(selectedPackage == nil ? 0.5 : 1)
                                .padding(.horizontal, 20)

                                Spacer().frame(height: 16)

                                Button {
                                    Task { await store.restore() }
                                } label: {
                                    Text("Restore Purchases")
                                        .font(.footnote)
                                        .foregroundStyle(.white.opacity(0.5))
                                }

                                Spacer().frame(height: 12)

                                Text("Cancel anytime. Subscriptions auto-renew.")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.3))
                                    .multilineTextAlignment(.center)

                                Spacer().frame(height: 40)
                            }
                        }
                        .scrollIndicators(.hidden)
                    } else {
                        ContentUnavailableView {
                            Label("Unable to Load", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text("Please check your connection and try again.")
                        } actions: {
                            Button("Retry") {
                                Task { await store.fetchOfferings() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Error", isPresented: .init(
                get: { store.error != nil },
                set: { if !$0 { store.error = nil } }
            )) {
                Button("OK") { store.error = nil }
            } message: {
                Text(store.error ?? "")
            }
            .onChange(of: store.isPremium) { _, isPremium in
                if isPremium { dismiss() }
            }
            .onAppear {
                if selectedPackage == nil, let current = store.offerings?.current {
                    selectedPackage = current.availablePackages.first(where: { $0.identifier == "$rc_annual" })
                        ?? current.availablePackages.first
                }
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 28)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func packageCard(package: Package) -> some View {
        let isSelected = selectedPackage?.identifier == package.identifier
        let isAnnual = package.identifier == "$rc_annual"

        return Button {
            selectedPackage = package
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(package.storeProduct.localizedTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)

                        if isAnnual {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.white)
                                .clipShape(.rect(cornerRadius: 4))
                        }
                    }

                    if let intro = package.storeProduct.introductoryDiscount {
                        Text("\(intro.subscriptionPeriod.value)-\(unitLabel(intro.subscriptionPeriod.unit)) free trial")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)

                    Text(periodLabel(package))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(isSelected ? 0.12 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .white : .white.opacity(0.15), lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
    }

    private func unitLabel(_ unit: SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return ""
        }
    }

    private func periodLabel(_ package: Package) -> String {
        switch package.identifier {
        case "$rc_monthly": return "per month"
        case "$rc_annual": return "per year"
        default: return ""
        }
    }
}
