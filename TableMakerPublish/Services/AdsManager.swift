//
//  AdsManager.swift
//  TableMakerPublish
//

import Foundation
import UIKit
#if canImport(GoogleMobileAds)
import GoogleMobileAds
import AppTrackingTransparency

@MainActor
final class AdsManager: NSObject, FullScreenContentDelegate {
    static let shared = AdsManager()
    private override init() {}

    // MARK: - Configuration helpers
    private static let testAppId = "ca-app-pub-3940256099942544~1458002511"
    private static let testInterstitialUnitId = "ca-app-pub-3940256099942544/4411468910"
    private static var productionInterstitialUnitId: String? {
        // Provide your real interstitial unit id in Info.plist under key `GADInterstitialAdUnitId`
        return Bundle.main.object(forInfoDictionaryKey: "GADInterstitialAdUnitId") as? String
    }

    private(set) var isConfigured: Bool = false
    private var interstitial: InterstitialAd?
    private var interstitialSuppressedUntil: Date?
    private var lastInterstitialPresentationDate: Date?
    private let minimumInterstitialInterval: TimeInterval = 150 // 2 minutes 30 seconds
    private var pendingCompletion: (() -> Void)?
    private var isPresentingInterstitial: Bool = false

    func configure() {
        guard !isConfigured else { return }
        isConfigured = true

        // Do not prompt for tracking at launch. Apple prefers prompting at a user-relevant time.

        print("[Ads] Starting Google Mobile Ads SDK")
        
        // Disable mediation to speed up initialization
        MobileAds.shared.disableMediationInitialization()
        
        // Start the SDK with minimal completion handler and warm an interstitial ASAP
        MobileAds.shared.start(completionHandler: { [weak self] status in
            print("[Ads] SDK started successfully")
            // Kick off a first load immediately once the SDK is ready
            self?.preloadInterstitial()
        })

        #if !DEBUG
        // Guardrail to avoid shipping with the Google sample App ID
        if let appId = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String,
           appId == Self.testAppId {
            print("[Ads][WARNING] Info.plist GADApplicationIdentifier is the Google test App ID. Replace with your real AdMob App ID before release.")
        }
        #endif
        // Backup preload shortly after startup in case the first call raced with other setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.preloadInterstitial()
        }
    }

    func preloadInterstitial() {
        // Determine at runtime whether ads should be shown. FORCE_ADS=1 can override for diagnostics.
        let shouldShowAds = canShowAds() || ProcessInfo.processInfo.environment["FORCE_ADS"] == "1"
        #if DEBUG
        print("[Ads] preloadInterstitial shouldShowAds=\(shouldShowAds) pro=\(RevenueCatManager.shared.state.hasPro) removeAds=\(RevenueCatManager.shared.state.hasRemoveAds)")
        #endif
        if !shouldShowAds {
            interstitial = nil
            return
        }
        // Avoid spamming loads if an ad is already ready
        if interstitial != nil {
            return
        }
        let request = Request()
        if #available(iOS 14, *) {
            if ATTrackingManager.trackingAuthorizationStatus != .authorized {
                let extras = Extras()
                extras.additionalParameters = ["npa": "1"]
                request.register(extras)
            }
        }
        // Select ad unit id per build configuration
        #if DEBUG
        let adUnitId = Self.testInterstitialUnitId
        #else
        guard let adUnitId = Self.productionInterstitialUnitId, adUnitId.isEmpty == false, adUnitId != Self.testInterstitialUnitId else {
            print("[Ads] ERROR: Missing production interstitial ad unit id in Info.plist (key: GADInterstitialAdUnitId). Skipping load.")
            return
        }
        #endif
        print("[Ads] Loading interstitial…")
        InterstitialAd.load(with: adUnitId, request: request) { [weak self] ad, error in
            if let error = error {
                print("[Ads] Failed to load interstitial: \(error)")
                return
            }
            print("[Ads] Interstitial loaded")
            // Safely assign on main actor
            self?.interstitial = ad
            self?.interstitial?.fullScreenContentDelegate = self
        }
    }

    func showInterstitialIfReady() {
        // Backwards-compatible behavior (no completion). Prefer showInterstitialThen(_:).
        showInterstitialThen({})
    }

    /// Presents an interstitial if available, then calls completion after it is dismissed.
    /// If ads are disabled, suppressed, not ready, or cannot be presented, calls completion immediately.
    func showInterstitialThen(_ completion: @escaping () -> Void) {
        // Determine at runtime whether ads should be shown. FORCE_ADS=1 can override for diagnostics.
        let shouldShowAds = canShowAds() || ProcessInfo.processInfo.environment["FORCE_ADS"] == "1"
        // Respect temporary suppression
        let isSuppressed = (interstitialSuppressedUntil ?? .distantPast) > Date()

        // Frequency capping: limit to one interstitial every minimumInterstitialInterval
        let isFrequencyCapped: Bool = {
            guard let last = lastInterstitialPresentationDate else { return false }
            return Date().timeIntervalSince(last) < minimumInterstitialInterval
        }()

        // If ads shouldn't show or we are frequency capped, run completion now
        if !shouldShowAds {
            #if DEBUG
            print("[Ads] Skipping interstitial: ads disabled by gating")
            #endif
            DispatchQueue.main.async { completion() }
            return
        }
        if isSuppressed {
            #if DEBUG
            print("[Ads] Skipping interstitial: temporarily suppressed until \(interstitialSuppressedUntil?.description ?? "-")")
            #endif
            DispatchQueue.main.async { completion() }
            return
        }
        if isFrequencyCapped {
            #if DEBUG
            print("[Ads] Skipping interstitial: frequency capped (min interval = \(minimumInterstitialInterval)s)")
            #endif
            DispatchQueue.main.async { completion() }
            return
        }

        // If an interstitial is currently presenting, enqueue latest completion to run on dismissal
        if isPresentingInterstitial {
            pendingCompletion = completion
            return
        }

        // Helper to actually present a ready interstitial
        func presentReadyAd(_ ad: InterstitialAd) {
            guard let presenter = Self.topMostViewController() else {
                #if DEBUG
                print("[Ads] Cannot present interstitial: no presenter available")
                #endif
                DispatchQueue.main.async { completion() }
                return
            }
            // Ensure we're attached to a window; if not, retry once shortly
            guard presenter.view.window != nil else {
                #if DEBUG
                print("[Ads] Presenter not in window yet; retrying shortly")
                #endif
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    guard let self = self else {
                        DispatchQueue.main.async { completion() }
                        return
                    }
                    if let retryPresenter = Self.topMostViewController(), retryPresenter.view.window != nil {
                        self.pendingCompletion = completion
                        self.interstitial = nil
                        self.isPresentingInterstitial = true
                        ad.present(from: retryPresenter)
                        self.preloadInterstitial()
                    } else {
                        self.preloadInterstitial()
                        DispatchQueue.main.async { completion() }
                    }
                }
                return
            }
            pendingCompletion = completion
            self.interstitial = nil
            isPresentingInterstitial = true
            ad.present(from: presenter)
            preloadInterstitial()
        }

        // Request ATT (if needed) before loading/presenting
        let proceed: () -> Void = { [weak self] in
            guard let self = self else { return }
            if let ready = self.interstitial {
                presentReadyAd(ready)
            } else {
                // Load and present when ready; if load fails, continue the flow without blocking
                #if DEBUG
                print("[Ads] No interstitial ready; loading now and will present if it loads in time…")
                #endif
                let request = Request()
                if #available(iOS 14, *) {
                    if ATTrackingManager.trackingAuthorizationStatus != .authorized {
                        let extras = Extras()
                        extras.additionalParameters = ["npa": "1"]
                        request.register(extras)
                    }
                }
                #if DEBUG
                let adUnitId = Self.testInterstitialUnitId
                #else
                guard let adUnitId = Self.productionInterstitialUnitId, adUnitId.isEmpty == false, adUnitId != Self.testInterstitialUnitId else {
                    #if DEBUG
                    print("[Ads] ERROR: Missing production interstitial ad unit id in Info.plist (key: GADInterstitialAdUnitId). Skipping load.")
                    #endif
                    DispatchQueue.main.async { completion() }
                    return
                }
                #endif
                InterstitialAd.load(with: adUnitId, request: request) { [weak self] ad, error in
                    guard let self = self else { return }
                    if let ad = ad {
                        self.interstitial = ad
                        self.interstitial?.fullScreenContentDelegate = self
                        presentReadyAd(ad)
                    } else {
                        #if DEBUG
                        print("[Ads] Interstitial load-on-demand failed: \(error?.localizedDescription ?? "nil")")
                        #endif
                        DispatchQueue.main.async { completion() }
                    }
                }
            }
        }

        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async { proceed() }
            }
        } else {
            proceed()
        }
    }

    /// Cancels any pending completion scheduled to run after the current interstitial is dismissed.
    /// Use when the user changes flows (e.g., switches from Image share to QR) while an ad is up.
    func cancelPendingCompletion() {
        pendingCompletion = nil
    }

    /// Temporarily suppress interstitial presentation for the provided duration (seconds)
    func suppressInterstitials(for seconds: TimeInterval) {
        interstitialSuppressedUntil = Date().addingTimeInterval(seconds)
    }

    static func topMostViewController(base: UIViewController? = nil) -> UIViewController? {
        let starting = base ?? firstKeyWindow()?.rootViewController
        if let nav = starting as? UINavigationController { return topMostViewController(base: nav.visibleViewController) }
        if let tab = starting as? UITabBarController { return topMostViewController(base: tab.selectedViewController) }
        if let presented = starting?.presentedViewController { return topMostViewController(base: presented) }
        return starting
    }

    private static func firstKeyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    // MARK: - GADFullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("[Ads] Interstitial dismissed")
        isPresentingInterstitial = false
        let completion = pendingCompletion
        pendingCompletion = nil
        // Give UIKit a beat to finish dismissal animations before presenting next UI
        if let completion = completion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                completion()
            }
        }
    }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[Ads] Failed to present interstitial: \(error)")
        isPresentingInterstitial = false
        let completion = pendingCompletion
        pendingCompletion = nil
        if let completion = completion { DispatchQueue.main.async { completion() } }
    }
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("[Ads] Presenting interstitial")
        // Record presentation time for frequency capping
        lastInterstitialPresentationDate = Date()
        isPresentingInterstitial = true
    }
}
#else
// Fallback no-ads stub to allow building and testing without AdMob SDK present
final class AdsManager: NSObject {
    static let shared = AdsManager()
    private override init() {}
    func configure() {}
    func preloadInterstitial() {}
    func showInterstitialIfReady() {}
    func showInterstitialThen(_ completion: @escaping () -> Void) { completion() }
    func cancelPendingCompletion() {}
    func suppressInterstitials(for seconds: TimeInterval) {}
}
#endif

