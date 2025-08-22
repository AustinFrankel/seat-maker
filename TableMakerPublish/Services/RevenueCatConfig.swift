import Foundation
import Combine
#if canImport(RevenueCat)
import RevenueCat
#endif

// MARK: - Replace with your Public API Key
// Dashboard → Project Settings → API Keys → iOS Public SDK Key
private let RC_API_KEY = "appl_pTIuJTReZxqyFzrdQLKoPDnHsKF"

// Entitlement identifiers from your RC dashboard
enum EntitlementID {
    static let pro = "pro"
    static let removeAds = "remove_ads"
}

final class PurchaseState: ObservableObject {
    @Published var hasPro: Bool = UserDefaults.standard.bool(forKey: "entitlement_hasPro")
    @Published var hasRemoveAds: Bool = UserDefaults.standard.bool(forKey: "entitlement_hasRemoveAds")

    var adsDisabled: Bool { hasPro || hasRemoveAds }
    var unlimitedFeatures: Bool { hasPro }

    fileprivate func update(from info: CustomerInfo?) {
        guard let info = info else { return }
        let e = info.entitlements
        let wasPro = hasPro
        var newHasPro = e[EntitlementID.pro]?.isActive == true
        var newHasRemoveAds = e[EntitlementID.removeAds]?.isActive == true
        // Fallback: infer from active subscriptions or purchased product identifiers if entitlements keys don't match
        if (!newHasPro || !newHasRemoveAds) {
            let activeProductIds: [String] = Array(info.activeSubscriptions) + info.nonSubscriptions.map { $0.productIdentifier }
            let lower = activeProductIds.map { $0.lowercased() }
            if !newHasPro {
                newHasPro = lower.contains { id in id.contains("pro") || id.contains("unlimited") || id.contains("lifetime_pro") || id == "com.seatmaker.pro.lifetime" }
            }
            if !newHasRemoveAds {
                newHasRemoveAds = lower.contains { id in id.contains("removeads") || id.contains("remove_ads") || id == "com.seatmaker.removeads_lifetime" }
            }
        }
        hasPro = newHasPro
        hasRemoveAds = newHasRemoveAds
        // Persist so paywall suppression works across cold starts / offline
        UserDefaults.standard.set(newHasPro, forKey: "entitlement_hasPro")
        UserDefaults.standard.set(newHasRemoveAds, forKey: "entitlement_hasRemoveAds")
        // Notify Ads layer to react immediately to entitlement changes
        DispatchQueue.main.async {
            AdsManager.shared.preloadInterstitial()
        }
        // Post unlock notification when Pro becomes active
        if !wasPro && hasPro {
            NotificationCenter.default.post(name: .didUnlockPro, object: nil)
        }
    }
}

final class RevenueCatManager: NSObject, ObservableObject {
    static let shared = RevenueCatManager()

    @Published var offering: Offering?
    // True while the paywall is presented to the user (any implementation/UI)
    @Published var isPaywallActive: Bool = false
    #if canImport(RevenueCat)
    // When Offerings aren't configured or cannot be fetched, we use direct product fetch as a fallback
    @Published var fallbackProducts: [StoreProduct] = []
    #endif
    #if DEBUG
    /// In DEBUG builds, prefer local StoreKit testing on both Simulator and physical devices.
    /// This guarantees the StoreKit purchase sheet appears while developing, using the
    /// `SeatMaker.storekit` configuration attached to the scheme.
    @Published var preferLocalStoreKit: Bool = true
    #else
    @Published var preferLocalStoreKit: Bool = false
    #endif
    let state = PurchaseState()

    #if canImport(RevenueCat)
    /// Public entry point for views to apply updated CustomerInfo without exposing internal state mutation
    func applyCustomerInfo(_ info: CustomerInfo?) {
        state.update(from: info)
    }
    #endif

    func configure() {
        #if canImport(RevenueCat)
        // Reduce log verbosity in production
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .error
        #endif

        // Configure Purchases once at app start
        Purchases.configure(withAPIKey: RC_API_KEY)
        Purchases.shared.delegate = self

        // Fetch current customer info + offerings
        refreshCustomerInfo()
        refreshOfferings()

        // Always preload direct products so the Apple purchase sheet can be presented
        // even if Offerings fail to load or mapping heuristics miss.
        fetchFallbackProducts()

        #if DEBUG
        // Helpful runtime diagnostics in debug builds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            debugPrintRevenueCat()
        }
        #endif
        #else
        // RevenueCat not available yet (SPM not added). No-op to allow building.
        #endif
    }

    #if canImport(RevenueCat)
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        state.update(from: customerInfo)
    }
    #endif

    func refreshCustomerInfo() {
        #if canImport(RevenueCat)
        Purchases.shared.getCustomerInfo { [weak self] info, _ in
            self?.state.update(from: info)
        }
        #endif
    }

    func refreshOfferings() {
        #if canImport(RevenueCat)
        Purchases.shared.getOfferings { [weak self] offerings, error in
            if let error = error {
                print("RC getOfferings error:", error.localizedDescription)
            }
            if let current = offerings?.current {
                print("RC offering: \(current.identifier) packages=\(current.availablePackages.count)")
                self?.offering = current
                // Keep fallback products preloaded to guarantee purchase sheet availability
                if self?.fallbackProducts.isEmpty == true {
                    self?.fetchFallbackProducts()
                }
            } else {
                print("RC offerings current is nil — falling back to direct product fetch")
                self?.offering = nil
                self?.fetchFallbackProducts()
            }
        }
        #endif
    }

    #if canImport(RevenueCat)
    private func fetchFallbackProducts() {
        // Try both App Store Connect identifiers and local StoreKit test IDs
        // so fallback works in both production and local testing.
        let productIds = [
            // App Store Connect product identifiers
            "com.seatmaker.pro.lifetime",
            "com.seatmaker.removeads_lifetime",
            // Local StoreKit configuration identifiers (for Xcode testing)
            EntitlementID.pro,
            EntitlementID.removeAds
        ]
        Purchases.shared.getProducts(productIds) { [weak self] products in
            DispatchQueue.main.async {
                self?.fallbackProducts = products
                if products.isEmpty {
                    print("RevenueCat fallback products fetch returned 0 items. Check StoreKit configuration in the scheme.")
                } else {
                    print("RevenueCat fallback products loaded: \(products.map { $0.productIdentifier })")
                }
            }
        }
    }
    #endif

    // Restore flow
    func restore(completion: @escaping (Result<Void, Error>) -> Void) {
        #if canImport(RevenueCat)
        Purchases.shared.restorePurchases { info, error in
            if let error { completion(.failure(error)) }
            else {
                self.state.update(from: info)
                completion(.success(()))
            }
        }
        #else
        completion(.failure(NSError(domain: "RevenueCatUnavailable", code: -1)))
        #endif
    }

    // Optional helpers for future account systems
    func logIn(userId: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        #if canImport(RevenueCat)
        Purchases.shared.logIn(userId) { _, _, error in
            if let error = error { completion?(.failure(error)) }
            else { completion?(.success(())) }
        }
        #else
        completion?(.failure(NSError(domain: "RevenueCatUnavailable", code: -1)))
        #endif
    }

    func logOut(completion: ((Result<Void, Error>) -> Void)? = nil) {
        #if canImport(RevenueCat)
        Purchases.shared.logOut { _, error in
            if let error = error { completion?(.failure(error)) }
            else { completion?(.success(())) }
        }
        #else
        completion?(.failure(NSError(domain: "RevenueCatUnavailable", code: -1)))
        #endif
    }
}

#if canImport(RevenueCat)
extension RevenueCatManager: PurchasesDelegate {}
#endif

// MARK: - Feature gating convenience
func canShowAds() -> Bool {
    let s = RevenueCatManager.shared.state
    return !s.adsDisabled
}

func canUseUnlimitedFeatures() -> Bool {
    // Temporarily grant unlimited features to all users
    return true
}

// MARK: - Diagnostics
func debugPrintRevenueCat() {
    #if canImport(RevenueCat)
    Purchases.shared.getOfferings { offerings, error in
        if let o = offerings?.current {
            print("RC Offering:", o.identifier)
            o.availablePackages.forEach { pkg in
                let sp = pkg.storeProduct
                print("• pkg:", pkg.identifier,
                      "| product:", sp.productIdentifier,
                      "| price:", sp.localizedPriceString)
            }
        } else {
            print("RC getOfferings error:", error?.localizedDescription ?? "nil")
        }
    }

    Purchases.shared.getCustomerInfo { info, _ in
        let e = info?.entitlements
        print("Entitlements — pro:", e?[EntitlementID.pro]?.isActive == true,
              "remove_ads:", e?[EntitlementID.removeAds]?.isActive == true)
    }
    #endif
}

// MARK: - Paywall trigger notification
extension Notification.Name {
    static let showPaywall = Notification.Name("ShowPaywall")
    static let didUnlockPro = Notification.Name("DidUnlockPro")
}

// MARK: - Paywall presentation suppression helper
/// Returns true when the paywall should not be shown (e.g., user already has Pro)
func shouldSuppressPaywall() -> Bool {
    // Always suppress paywall presentation
    return true
}


