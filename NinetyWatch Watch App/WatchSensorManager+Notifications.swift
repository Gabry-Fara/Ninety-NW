import Foundation
import UserNotifications

enum WatchWakeNotificationConstants {
    static let wakeNotificationCategoryIdentifier = "NINETY_WAKE_ALARM"
    static let scheduledWakeNotificationIdentifier = "ninety.watch.wake.scheduled"
    static let immediateWakeNotificationIdentifier = "ninety.watch.wake.now"
}

extension WatchSensorManager {
    func configureWakeNotifications() {
        let category = UNNotificationCategory(
            identifier: WatchWakeNotificationConstants.wakeNotificationCategoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func requestWakeNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error {
                    self.replayStatusText = "Notification auth failed: \(error.localizedDescription)"
                } else if !granted {
                    self.replayStatusText = "Notifications not allowed"
                }
            }
        }
    }

    func scheduleWakeNotification(for targetDate: Date) {
        cancelScheduledWakeNotification()
        requestWakeNotificationAuthorization()

        let content = UNMutableNotificationContent()
        content.title = "Ninety"
        content.body = "Sveglia"
        content.sound = .default
        content.categoryIdentifier = WatchWakeNotificationConstants.wakeNotificationCategoryIdentifier
        content.userInfo = [
            "kind": "wakeAlarm",
            "targetDate": targetDate.timeIntervalSince1970
        ]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: WatchWakeNotificationConstants.scheduledWakeNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            guard let error else { return }
            DispatchQueue.main.async {
                self.replayStatusText = "Notification schedule failed: \(error.localizedDescription)"
            }
        }
    }

    func deliverWakeNotificationNow(reason: String) {
        requestWakeNotificationAuthorization()

        let content = UNMutableNotificationContent()
        content.title = "Ninety"
        content.body = reason
        content.sound = .default
        content.categoryIdentifier = WatchWakeNotificationConstants.wakeNotificationCategoryIdentifier
        content.userInfo = [
            "kind": "wakeAlarmNow",
            "reason": reason
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: WatchWakeNotificationConstants.immediateWakeNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            guard let error else { return }
            DispatchQueue.main.async {
                self.replayStatusText = "Notification delivery failed: \(error.localizedDescription)"
            }
        }
    }

    func cancelScheduledWakeNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [WatchWakeNotificationConstants.scheduledWakeNotificationIdentifier]
        )
    }
}
