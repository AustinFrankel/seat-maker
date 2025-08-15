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
    @Published var hasPro: Bool = false
    @Published var hasRemoveAds: Bool = false

    var adsDisabled: Bool { hasPro || hasRemoveAds }
    var unlimitedFeatures: Bool { hasPro }

    fileprivate func update(from info: CustomerInfo?) {
        guard let e = info?.entitlements else { return }
        hasPro = e[EntitlementID.pro]?.isActive == true
        hasRemoveAds = e[EntitlementID.removeAds]?.isActive == true
    }
}

final class RevenueCatManager: NSObject, ObservableObject {
    static let shared = RevenueCatManager()

    @Published var offering: Offering?
    let state = PurchaseState()

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
                return
            }
            guard let current = offerings?.current else {
                print("RC offerings current is nil")
                return
            }
            print("RC offering: \(current.identifier) packages=\(current.availablePackages.count)")
            self?.offering = current
        }
        #endif
    }

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
    RevenueCatManager.shared.state.unlimitedFeatures
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
}


