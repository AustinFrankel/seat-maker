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
        #if targetEnvironment(simulator)
        // New SDKs don't require setting a simulator test ID when using test ad unit IDs.
        #endif
        MobileAds.shared.start(completionHandler: { _ in
            print("[Ads] SDK started")
        })
        preloadInterstitial()
    }

    func preloadInterstitial() {
        let request = Request()
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
        // Do not show if temporarily suppressed (e.g., after Delete All Data or sensitive flows)
        if let until = interstitialSuppressedUntil, until > Date() {
            return
        }
        guard let presenter = Self.topMostViewController(), let interstitial = interstitial else {
            preloadInterstitial()
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


