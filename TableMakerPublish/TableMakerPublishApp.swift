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
#if canImport(RevenueCat)
import RevenueCat
#endif
import Combine
 
// MARK: - Global Theme Utilities
// Convert a hex string like "#RRGGBB" or "RRGGBB" (optionally with AARRGGBB) to Color
func colorFromHex(_ hex: String) -> Color {
    var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if cleaned.hasPrefix("#") { cleaned.removeFirst() }
    var rgba: UInt64 = 0
    guard Scanner(string: cleaned).scanHexInt64(&rgba) else { return Color.blue }
    let r, g, b, a: UInt64
    switch cleaned.count {
    case 8: // AARRGGBB
        a = (rgba & 0xFF000000) >> 24
        r = (rgba & 0x00FF0000) >> 16
        g = (rgba & 0x0000FF00) >> 8
        b = (rgba & 0x000000FF)
    case 6: // RRGGBB
        a = 255
        r = (rgba & 0xFF0000) >> 16
        g = (rgba & 0x00FF00) >> 8
        b = (rgba & 0x0000FF)
    default:
        return Color.blue
    }
    return Color(.sRGB,
                 red: Double(r) / 255.0,
                 green: Double(g) / 255.0,
                 blue: Double(b) / 255.0,
                 opacity: Double(a) / 255.0)
}

// Convert a SwiftUI Color to hex string #RRGGBB (ignore alpha)
func hexFromColor(_ color: Color) -> String {
    let ui = UIColor(color)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return "#007AFF" }
    let rr = Int(round(r * 255)), gg = Int(round(g * 255)), bb = Int(round(b * 255))
    return String(format: "#%02X%02X%02X", rr, gg, bb)
}

// Mix two UIColors by t (0..1). t=0 returns a, t=1 returns b
func mix(_ a: UIColor, _ b: UIColor, t: CGFloat) -> UIColor {
    let t = max(0, min(1, t))
    var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
    var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
    a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
    b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
    return UIColor(red: ar * (1 - t) + br * t,
                   green: ag * (1 - t) + bg * t,
                   blue: ab * (1 - t) + bb * t,
                   alpha: aa * (1 - t) + ba * t)
}
 
// Integrate the launch overlay above home content and the onboarding overlay.
struct RootWithLaunch: View {
    var body: some View {
        LaunchOverlayContainer {
            ContentView()
                .overlayPreferenceValue(OnboardingAnchorPreferenceKey.self) { anchors in
                    GeometryReader { proxy in
                        let _ = updateAnchors(anchors: anchors, proxy: proxy)
                        CoachMarkOverlayView(controller: OnboardingController.shared)
                            .allowsHitTesting(OnboardingController.shared.isActive)
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Interactive tutorial")
                    }
                }
                .onAppear {
                    // Delay to ensure view hierarchy laid out and anchors resolvable
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        // Don't start interactive onboarding while in the empty "Create seating for events" screen.
                        if UserDefaults.standard.bool(forKey: "hasSeenTutorial") {
                            OnboardingController.shared.startIfNeeded(context: .mainTable)
                        }
                    }
                }
        }
    }

    private func updateAnchors(anchors: [String: Anchor<CGRect>], proxy: GeometryProxy) {
        OnboardingController.shared.updateResolvedAnchors { key in
            guard let a = anchors[key] else { return nil }
            return proxy[a]
        }
    }
}

@main
struct TableMakerPublishApp: App {
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    @AppStorage("hasCompletedInteractiveOnboarding") private var hasCompletedInteractiveOnboarding: Bool = false
    @AppStorage("appTheme") private var appTheme: String = "classic"
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("customAccentHex") private var customAccentHex: String = "#007AFF"
    @UIApplicationDelegateAdaptor(DeepLinkAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootWithLaunch()
                .environment(\.showingTutorialInitially, !hasSeenTutorial)
                .tint(resolveAccent(for: appTheme, customHex: customAccentHex))
                // Apply themed background across the app and ignore safe areas so it fills the whole screen
                .background(resolveThemeBackground(for: appTheme, customHex: customAccentHex, isDark: isDarkMode).ignoresSafeArea())
                // Respect the explicit dark mode toggle globally
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onAppear {
                    // Reset tutorial state for testing (remove in production)
                    // UserDefaults.standard.set(false, forKey: "hasSeenTutorial")
                    NotificationService.shared.configureOnLaunch()
                    // Configure RevenueCat before Ads so entitlements are known
                    RevenueCatManager.shared.configure()
                    AdsManager.shared.configure()
                    // If Part 1 finished and interactive onboarding not completed, ensure controller can start when main appears
                    if hasSeenTutorial && !hasCompletedInteractiveOnboarding {
                        // No-op here; start occurs in RootWithLaunch onAppear of Content
                    }
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

// MARK: - Theme resolver
private func resolveAccent(for theme: String, customHex: String) -> Color {
    switch theme {
    case "ocean": return .cyan
    case "sunset": return .orange
    case "forest": return .green
    case "midnight": return .indigo
    case "custom":
        return colorFromHex(customHex)
    default: return .blue // classic
    }
}

// MARK: - Background resolver
private func resolveThemeBackground(for theme: String, customHex: String, isDark: Bool) -> Color {
    switch theme {
    case "ocean":
        return isDark ? Color(red: 0.03, green: 0.10, blue: 0.15) : Color(red: 0.88, green: 0.96, blue: 1.00)
    case "sunset":
        return isDark ? Color(red: 0.12, green: 0.06, blue: 0.10) : Color(red: 1.00, green: 0.95, blue: 0.90)
    case "forest":
        return isDark ? Color(red: 0.06, green: 0.10, blue: 0.08) : Color(red: 0.93, green: 0.98, blue: 0.94)
    case "midnight":
        return isDark ? Color(red: 0.05, green: 0.05, blue: 0.08) : Color(red: 0.94, green: 0.95, blue: 0.98)
    case "custom":
        let accentUI = UIColor(colorFromHex(customHex))
        // Light mode: very subtle tint towards white; Dark mode: subtle tint towards black
        if isDark {
            return Color(mix(accentUI, .black, t: 0.85))
        } else {
            return Color(mix(accentUI, .white, t: 0.92))
        }
    default: // classic
        // Classic should be pure white in light mode and system background in dark mode
        return isDark ? Color(.systemBackground) : Color.white
    }
}

// AdsManager and BannerAdView are defined in `Services/AdsManager.swift` and `views/BannerAdView.swift`.
