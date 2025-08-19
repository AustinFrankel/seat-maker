//
//  AdsManager.swift
//  TableMakerPublish
//

import Foundation
import UIKit
#if canImport(GoogleMobileAds)
import GoogleMobileAds
import AppTrackingTransparency

final class AdsManager: NSObject, FullScreenContentDelegate {
    static let shared = AdsManager()
    private override init() {}

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
        
        // Start the SDK with minimal completion handler
        MobileAds.shared.start(completionHandler: { status in
            print("[Ads] SDK started successfully")
        })
        
        // Always preload immediately after a short delay to ensure SDK is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.preloadInterstitial()
        }
    }

    func preloadInterstitial() {
        // Respect RevenueCat entitlements
        let shouldShowAds = !RevenueCatManager.shared.state.adsDisabled
        if !shouldShowAds {
            interstitial = nil
            return
        }
        // Avoid spamming loads if an ad is already ready
        if interstitial != nil {
            return
        }
        let request = Request()
        #if DEBUG
        // For device testing, you can add your device hash to enable test ads.
        // MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [ GADSimulatorID ]
        #endif
        // Test interstitial ad unit ID from Google
        let testInterstitial = "ca-app-pub-3940256099942544/4411468910"
        print("[Ads] Loading interstitial…")
        InterstitialAd.load(with: testInterstitial, request: request) { [weak self] ad, error in
            if let error = error {
                print("[Ads] Failed to load interstitial: \(error)")
                return
            }
            print("[Ads] Interstitial loaded")
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
        // Do not show if user purchased remove_ads or pro
        let shouldShowAds = !RevenueCatManager.shared.state.adsDisabled
        // Respect temporary suppression
        let isSuppressed = (interstitialSuppressedUntil ?? .distantPast) > Date()

        // Frequency capping: limit to one interstitial every minimumInterstitialInterval
        let isFrequencyCapped: Bool = {
            guard let last = lastInterstitialPresentationDate else { return false }
            return Date().timeIntervalSince(last) < minimumInterstitialInterval
        }()

        // If ads shouldn't show or we are frequency capped, run completion now
        if !shouldShowAds || isSuppressed || isFrequencyCapped {
            DispatchQueue.main.async { completion() }
            return
        }

        // If an interstitial is currently presenting, enqueue latest completion to run on dismissal
        if isPresentingInterstitial {
            pendingCompletion = completion
            return
        }

        guard let presenter = Self.topMostViewController(), let interstitial = interstitial else {
            // No ad ready → preload and continue immediately
            preloadInterstitial()
            DispatchQueue.main.async { completion() }
            return
        }

        // Avoid presenting over any active modal/sheet or while not in the window hierarchy
        if presenter.presentedViewController != nil || presenter.view.window == nil {
            // Cannot present now; run completion and try to preload for next time
            preloadInterstitial()
            DispatchQueue.main.async { completion() }
            return
        }

        // Present the ad and store completion for when it dismisses
        pendingCompletion = completion
        if #available(iOS 14, *) {
            // Request tracking authorization right before the first ad presentation
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    interstitial.present(from: presenter)
                }
            }
        } else {
            interstitial.present(from: presenter)
        }
        self.interstitial = nil
        isPresentingInterstitial = true
        preloadInterstitial()
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

