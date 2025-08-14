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
            ContentView()
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

// AdsManager and BannerAdView are defined in `Services/AdsManager.swift` and `views/BannerAdView.swift`.
