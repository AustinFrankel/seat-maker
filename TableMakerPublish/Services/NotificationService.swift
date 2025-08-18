import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let dailyReminderId = "tm.daily.reminder"

    private override init() {
        super.init()
    }

    // Call from App or any early entry point
    func configureOnLaunch() {
        center.delegate = self
    }

    // Safe to call on views' onAppear as well
    func configureOnAppear() {
        center.delegate = self
        let enabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        if enabled {
            scheduleDailyReminder()
        }
    }

    func enableDailyReminder() {
        UserDefaults.standard.set(true, forKey: "notificationsEnabled")

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted {
                        self.scheduleDailyReminder()
                    } else {
                        UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                    }
                }
            case .denied:
                UserDefaults.standard.set(false, forKey: "notificationsEnabled")
            case .authorized, .provisional, .ephemeral:
                self.scheduleDailyReminder()
            @unknown default:
                break
            }
        }
    }

    func disableReminders() {
        UserDefaults.standard.set(false, forKey: "notificationsEnabled")
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderId])
    }

    func sendTestReminder() {
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted { self.scheduleTest() }
                }
            case .denied:
                break
            case .authorized, .provisional, .ephemeral:
                self.scheduleTest()
            @unknown default:
                break
            }
        }
    }

    private func scheduleTest() {
        let content = buildContent()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    private func scheduleDailyReminder() {
        // Idempotent: if a request with the same identifier already exists at 10:00, do nothing
        center.getPendingNotificationRequests { requests in
            let alreadyScheduled = requests.contains { $0.identifier == self.dailyReminderId }
            if alreadyScheduled {
                return
            }
            var dateComponents = DateComponents()
            dateComponents.hour = 10
            dateComponents.minute = 0
            let content = self.buildContent()
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: self.dailyReminderId, content: content, trigger: trigger)
            self.center.add(request, withCompletionHandler: nil)
        }
    }

    private func buildContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let name = (UserDefaults.standard.string(forKey: "userName") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        let lines = [
            "Ready to seat your crew in seconds? 🪑",
            "Plan smarter, shuffle faster. ✨",
            "Got an event coming up? Let's map those seats. 🎉",
            "Your table layout, made easy. 💡"
        ]
        let body = lines.randomElement() ?? "Plan smarter, shuffle faster. ✨"

        if name.isEmpty {
            content.title = "Good day 👋"
        } else {
            content.title = "Good day, \(name) 👋"
        }
        content.body = body
        content.sound = .default
        return content
    }

    // Foreground presentation
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

}
