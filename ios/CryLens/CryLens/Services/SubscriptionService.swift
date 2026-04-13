import Foundation
import RevenueCat

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var isPro: Bool = false
    @Published var currentOffering: Offering?
    @Published var isLoading: Bool = false

    static let proEntitlementID = "pro"
    static var isConfigured: Bool { AppConfig.isRevenueCatConfigured }
    var isConfigured: Bool { Self.isConfigured }

    private init() {}

    func configure() {
        guard Self.isConfigured else { return }

        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey)
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
        guard Self.isConfigured else {
            isPro = false
            isLoading = false
            return
        }

        isLoading = true
        do {
            let info = try await Purchases.shared.customerInfo()
            isPro = info.entitlements[Self.proEntitlementID]?.isActive == true
        } catch {
            // Silently fail — treat as free tier
        }
        isLoading = false
    }

    func fetchOffering() async {
        guard Self.isConfigured else {
            currentOffering = nil
            return
        }

        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
        } catch {
            // Offerings unavailable — static paywall will be shown
        }
    }

    func purchase(package: Package) async throws {
        guard Self.isConfigured else {
            throw NSError(domain: "SubscriptionService", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "RevenueCat is not configured."
            ])
        }

        let result = try await Purchases.shared.purchase(package: package)
        if !result.userCancelled {
            isPro = result.customerInfo.entitlements[Self.proEntitlementID]?.isActive == true
        }
    }

    func restorePurchases() async throws {
        guard Self.isConfigured else {
            throw NSError(domain: "SubscriptionService", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "RevenueCat is not configured."
            ])
        }

        isLoading = true
        defer { isLoading = false }
        let info = try await Purchases.shared.restorePurchases()
        isPro = info.entitlements[Self.proEntitlementID]?.isActive == true
    }

    /// Login user with RevenueCat (call after successful auth)
    func login(userId: String) {
        guard Self.isConfigured else { return }
        Purchases.shared.logIn(userId) { _, _, _ in }
    }

    /// Logout from RevenueCat (call on sign out)
    func logout() {
        guard Self.isConfigured else { return }
        Purchases.shared.logOut { _, _ in }
    }
}
