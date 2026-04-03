import Observation
import RevenueCat

@Observable
@MainActor
class StoreViewModel {
    let isAvailable: Bool
    var offerings: Offerings?
    var isPremium: Bool = false
    var isLoading: Bool = false
    var isPurchasing: Bool = false
    var error: String?

    init(isAvailable: Bool = AppConfig.revenueCatEnabled) {
        self.isAvailable = isAvailable

        guard isAvailable else { return }

        Task { await listenForUpdates() }
        Task { await fetchOfferings() }
        Task { await checkStatus() }
    }

    private func listenForUpdates() async {
        guard isAvailable else { return }

        for await info in Purchases.shared.customerInfoStream {
            self.isPremium = info.entitlements["premium"]?.isActive == true
        }
    }

    func fetchOfferings() async {
        guard isAvailable else {
            offerings = nil
            isLoading = false
            return
        }

        isLoading = true
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func purchase(package: Package) async {
        guard isAvailable else {
            error = "Subscriptions are not configured in this build."
            return
        }

        isPurchasing = true
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
            }
        } catch ErrorCode.purchaseCancelledError {
        } catch ErrorCode.paymentPendingError {
        } catch {
            self.error = error.localizedDescription
        }
        isPurchasing = false
    }

    func restore() async {
        guard isAvailable else {
            error = "Subscriptions are not configured in this build."
            return
        }

        do {
            let info = try await Purchases.shared.restorePurchases()
            isPremium = info.entitlements["premium"]?.isActive == true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func checkStatus() async {
        guard isAvailable else {
            isPremium = false
            return
        }

        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = info.entitlements["premium"]?.isActive == true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
