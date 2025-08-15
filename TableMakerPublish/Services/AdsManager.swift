//
//  AdsManager.swift
//  TableMakerPublish
//

import Foundation
import UIKit
import GoogleMobileAds
import AppTrackingTransparency

final class AdsManager: NSObject, FullScreenContentDelegate {
    static let shared = AdsManager()
    private override init() {}

    private(set) var isConfigured: Bool = false
    private var interstitial: InterstitialAd?
    private var interstitialSuppressedUntil: Date?

    func configure() {
        guard !isConfigured else { return }
        isConfigured = true

        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                // No-op. Ads serve regardless of authorization; this only affects IDFA usage.
            }
        }

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
        // Do not show if user purchased remove_ads or pro
        let shouldShowAds = !RevenueCatManager.shared.state.adsDisabled
        if !shouldShowAds {
            interstitial = nil
            return
        }
        // Do not show if temporarily suppressed (e.g., after Delete All Data or sensitive flows)
        if let until = interstitialSuppressedUntil, until > Date() {
            return
        }
        guard let presenter = Self.topMostViewController(), let interstitial = interstitial else {
            preloadInterstitial()
            return
        }
        // Avoid presenting over any active modal/sheet or while not in the window hierarchy
        if presenter.presentedViewController != nil || presenter.view.window == nil {
            return
        }
        interstitial.present(from: presenter)
        self.interstitial = nil
        preloadInterstitial()
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
    }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[Ads] Failed to present interstitial: \(error)")
    }
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("[Ads] Presenting interstitial")
    }
}


