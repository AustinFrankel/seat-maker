//
//  AdsManager.swift
//  TableMakerPublish
//

import Foundation
import UIKit
import GoogleMobileAds
import AppTrackingTransparency

final class AdsManager: NSObject {
    static let shared = AdsManager()
    private override init() {}

    private(set) var isConfigured: Bool = false
    private var interstitial: GADInterstitialAd?

    func configure() {
        guard !isConfigured else { return }
        isConfigured = true

        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                // No-op. Ads serve regardless of authorization; this only affects IDFA usage.
            }
        }

        GADMobileAds.sharedInstance().start(completionHandler: nil)
        preloadInterstitial()
    }

    func preloadInterstitial() {
        let request = GADRequest()
        // Test interstitial ad unit ID from Google
        let testInterstitial = "ca-app-pub-3940256099942544/4411468910"
        GADInterstitialAd.load(withAdUnitID: testInterstitial, request: request) { [weak self] ad, error in
            guard error == nil else { return }
            self?.interstitial = ad
        }
    }

    func showInterstitialIfReady() {
        guard let presenter = Self.topMostViewController(), let interstitial = interstitial else {
            preloadInterstitial()
            return
        }
        interstitial.present(fromRootViewController: presenter)
        self.interstitial = nil
        preloadInterstitial()
    }

    static func topMostViewController(base: UIViewController? = Self.firstKeyWindow()?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController { return topMostViewController(base: nav.visibleViewController) }
        if let tab = base as? UITabBarController { return topMostViewController(base: tab.selectedViewController) }
        if let presented = base?.presentedViewController { return topMostViewController(base: presented) }
        return base
    }

    private static func firstKeyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}


