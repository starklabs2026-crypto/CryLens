import Foundation
import RevenueCat

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var isPro: Bool = false
    @Published var currentOffering: Offering?
    @Published var isLoading: Bool = false

    /// Replace with your RevenueCat iOS public API key from https://app.revenuecat.com
    static let apiKey = "appl_REPLACE_WITH_YOUR_REVENUECAT_IOS_KEY"
    static let proEntitlementID = "pro"

    private init() {}

    func configure() {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: Self.apiKey)
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
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
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
        } catch {
            // Offerings unavailable — static paywall will be shown
        }
    }

    func purchase(package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        if !result.userCancelled {
            isPro = result.customerInfo.entitlements[Self.proEntitlementID]?.isActive == true
        }
    }

    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        let info = try await Purchases.shared.restorePurchases()
        isPro = info.entitlements[Self.proEntitlementID]?.isActive == true
    }

    /// Login user with RevenueCat (call after successful auth)
    func login(userId: String) {
        Purchases.shared.logIn(userId) { _, _, _ in }
    }

    /// Logout from RevenueCat (call on sign out)
    func logout() {
        Purchases.shared.logOut { _, _ in }
    }
}
