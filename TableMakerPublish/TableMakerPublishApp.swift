//
//  TableMakerPublishApp.swift
//  TableMakerPublish
//
//  Created by Austin Frankel on 5/23/25.
//

import SwiftUI
import UIKit
import UserNotifications
import GoogleMobileAds
import AppTrackingTransparency
 
// Integrate the launch overlay above home content.
struct RootWithLaunch: View {
    var body: some View {
        LaunchOverlayContainer {
            ZStack(alignment: .bottom) {
                ContentView()
                BannerAdView()
                    .frame(height: 50)
                    .background(Color.clear)
                    .ignoresSafeArea(edges: Edge.Set.bottom)
            }
        }
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
                    AdsManager.shared.configure()
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

// (Removed ad SDK and tracking code)

// Inline AdsManager and BannerAdView so they are included without project file changes
final class AdsManager: NSObject {
    static let shared = AdsManager()
    private override init() {}

    private(set) var isConfigured: Bool = false
    private var interstitial: InterstitialAd?

    func configure() {
        guard !isConfigured else { return }
        isConfigured = true

        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
        MobileAds.shared.start()
        preloadInterstitial()
    }

    func preloadInterstitial() {
        let request = Request()
        let testInterstitial = "ca-app-pub-3940256099942544/4411468910"
        InterstitialAd.load(with: testInterstitial, request: request, completionHandler: { [weak self] ad, error in
            guard error == nil else { return }
            self?.interstitial = ad
        })
    }

    func showInterstitialIfReady() {
        guard let presenter = Self.topMostViewController(), let interstitial = interstitial else {
            preloadInterstitial()
            return
        }
        interstitial.present(from: presenter)
        self.interstitial = nil
        preloadInterstitial()
    }

    private static func topMostViewController() -> UIViewController? {
        var base: UIViewController? = Self.firstKeyWindow()?.rootViewController
        while true {
            if let nav = base as? UINavigationController { base = nav.visibleViewController; continue }
            if let tab = base as? UITabBarController { base = tab.selectedViewController; continue }
            if let presented = base?.presentedViewController { base = presented; continue }
            break
        }
        return base
    }

    private static func firstKeyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
