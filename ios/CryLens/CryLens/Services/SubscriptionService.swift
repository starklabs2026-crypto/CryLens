import Foundation
import RevenueCat

@MainActor
final class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()

    @Published var isPro: Bool = false
    @Published var currentOffering: Offering?
    @Published var isLoading: Bool = false

    static let proEntitlementID = "pro"
    static let proProductIDs: Set<String> = [
        "crysense_pro_monthly",
        "crysense_pro_yearly"
    ]
    static var isConfigured: Bool { AppConfig.isRevenueCatConfigured }
    var isConfigured: Bool { Self.isConfigured }

    private var hasConfiguredPurchases = false

    private override init() {
        super.init()
    }

    func configure() {
        guard Self.isConfigured, !hasConfiguredPurchases else { return }

        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey)
        Purchases.shared.delegate = self
        hasConfiguredPurchases = true
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
        guard Self.isConfigured else {
            applyFreeTierState()
            return
        }

        isLoading = true
        Purchases.shared.invalidateCustomerInfoCache()
        do {
            let info = try await Purchases.shared.customerInfo()
            apply(customerInfo: info)
        } catch {
            // Silently fail — keep last known tier if RevenueCat is temporarily unavailable.
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
            apply(customerInfo: result.customerInfo)
            do {
                let syncedInfo = try await Purchases.shared.syncPurchases()
                apply(customerInfo: syncedInfo)
            } catch {
                // The local purchase already succeeded. Keep the last known customer info.
            }
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
        apply(customerInfo: info)
    }

    /// Login user with RevenueCat (call after successful auth)
    func login(userId: String) {
        guard Self.isConfigured else { return }
        Task {
            do {
                let result = try await Purchases.shared.logIn(userId)
                apply(customerInfo: result.customerInfo)
            } catch {
                await refreshStatus()
            }
        }
    }

    /// Logout from RevenueCat (call on sign out)
    func logout() {
        guard Self.isConfigured else {
            applyFreeTierState()
            return
        }

        Task {
            do {
                let info = try await Purchases.shared.logOut()
                apply(customerInfo: info)
            } catch {
                applyFreeTierState()
            }
        }
    }

    private func apply(customerInfo: CustomerInfo) {
        let hasActiveEntitlement = customerInfo.entitlements[Self.proEntitlementID]?.isActive == true
        let hasKnownActiveSubscription = !customerInfo.activeSubscriptions.isDisjoint(with: Self.proProductIDs)
        let hasKnownUnexpiredProduct = Self.proProductIDs.contains { productID in
            guard let expirationDate = customerInfo.expirationDate(forProductIdentifier: productID) else {
                return false
            }
            return expirationDate > Date()
        }

        isPro = hasActiveEntitlement || hasKnownActiveSubscription || hasKnownUnexpiredProduct
    }

    private func applyFreeTierState() {
        isPro = false
        isLoading = false
    }
}

extension SubscriptionService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.apply(customerInfo: customerInfo)
        }
    }
}
