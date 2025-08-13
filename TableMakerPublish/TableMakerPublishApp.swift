//
//  TableMakerPublishApp.swift
//  TableMakerPublish
//
//  Created by Austin Frankel on 5/23/25.
//

import SwiftUI
import UIKit
import UserNotifications
#if canImport(FBAudienceNetwork)
import FBAudienceNetwork
#endif
 
// Integrate the launch overlay above home content.
struct RootWithLaunch: View {
    var body: some View {
        LaunchOverlayContainer { ContentView() }
    }
}

@main
struct TableMakerPublishApp: App {
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    @UIApplicationDelegateAdaptor(DeepLinkAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootWithLaunch()
                .environment(\.showingTutorialInitially, !hasSeenTutorial)
                .onAppear {
                    // Reset tutorial state for testing (remove in production)
                    // UserDefaults.standard.set(false, forKey: "hasSeenTutorial")
                    NotificationService.shared.configureOnLaunch()
                }
                .onOpenURL { url in
                    ShareLinkRouter.shared.handleIncomingURL(url)
                }
        }
    }
}

final class DeepLinkAppDelegate: NSObject, UIApplicationDelegate {
    // Some frameworks call `-[AppDelegate window]`. Provide it to avoid unrecognized selector crashes.
    @objc var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize Meta Audience Network SDK
        #if canImport(FBAudienceNetwork)
        FBAudienceNetworkAds.initialize(with: nil, completionHandler: nil)
        // For SDK < 6.15 on devices < iOS 17, pass advertiser tracking flag (ATE)
        if #available(iOS 17.0, *) {
            // Not required for iOS 17+
        } else {
            FBAdSettings.setAdvertiserTrackingEnabled(true)
        }
        #endif

        // Preload first interstitial early in app lifecycle
        InterstitialAdManager.shared.load()
        return true
    }
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            ShareLinkRouter.shared.handleIncomingURL(url)
            return true
        }
        return false
    }
}

// MARK: - Interstitial Ad Manager
#if canImport(FBAudienceNetwork)
final class InterstitialAdManager: NSObject, FBInterstitialAdDelegate {
    static let shared = InterstitialAdManager()

    private var interstitialAd: FBInterstitialAd?
    private var isLoading: Bool = false
     private var shouldPresentWhenReady: Bool = false
    private let placementID: String = "638038005985027_638039552651539"

    // Typed @objc protocol to form selectors without stringly-typed API
    @objc private protocol FBInterstitialAdBidLoading {
        @objc func loadAd(withBidPayload: String)
    }

    func load() {
        guard !isLoading, interstitialAd?.isAdValid != true else { return }
        isLoading = true
        let ad = FBInterstitialAd(placementID: placementID)
        ad.delegate = self
        // If you have a server-provided bid payload, place it here
        let bidPayload: String? = nil
        if let payload = bidPayload, !payload.isEmpty,
           ad.responds(to: #selector(FBInterstitialAdBidLoading.loadAd(withBidPayload:))) {
            _ = ad.perform(#selector(FBInterstitialAdBidLoading.loadAd(withBidPayload:)), with: payload)
        } else {
            // Legacy Objective‑C selector – call dynamically to tolerate SDK differences
            if ad.responds(to: NSSelectorFromString("loadAd")) {
                _ = ad.perform(NSSelectorFromString("loadAd"))
            } else {
                // As a last resort for older headers that bridged to Swift as `load()`
                _ = ad.perform(NSSelectorFromString("load"))
            }
        }
        interstitialAd = ad
    }

    func showIfReady() {
        guard let ad = interstitialAd, ad.isAdValid else {
            // Mark intent and load so we present immediately on next successful load
            shouldPresentWhenReady = true
            load()
            return
        }
        guard let rootVC = UIApplication.topMostViewController() else { return }
        ad.show(fromRootViewController: rootVC)
    }

    // MARK: FBInterstitialAdDelegate
    func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        isLoading = false
        print("[Ads] Interstitial loaded")
        if shouldPresentWhenReady {
            shouldPresentWhenReady = false
            if let rootVC = UIApplication.topMostViewController() {
                interstitialAd.show(fromRootViewController: rootVC)
            }
        }
    }

    func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {
        print("[Ads] Interstitial impression")
    }

    func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        print("[Ads] Interstitial clicked")
    }

    func interstitialAdWillClose(_ interstitialAd: FBInterstitialAd) {
        print("[Ads] Interstitial will close")
    }

    func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        print("[Ads] Interstitial did close")
        self.interstitialAd = nil
        isLoading = false
        shouldPresentWhenReady = false
        // Prepare the next ad
        load()
    }

    func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        print("[Ads] Interstitial failed: \(error.localizedDescription)")
        self.interstitialAd = nil
        isLoading = false
    }
}
#else
final class InterstitialAdManager {
    static let shared = InterstitialAdManager()
    func load() {}
    func showIfReady() {}
}
#endif

// MARK: - UIWindow / ViewController helpers
extension UIApplication {
    static func topMostViewController(base: UIViewController? = {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
        return keyWindow?.rootViewController
    }()) -> UIViewController? {
        if let nav = base as? UINavigationController { return topMostViewController(base: nav.visibleViewController) }
        if let tab = base as? UITabBarController { return topMostViewController(base: tab.selectedViewController) }
        if let presented = base?.presentedViewController { return topMostViewController(base: presented) }
        return base
    }
}
