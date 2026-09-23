import Foundation
import UserNotifications

/// Gửi macOS Notification Center alert khi hết giờ.
/// Tuỳ chọn `interruptionLevel = .timeSensitive` để bypass Focus Mode (Do Not Disturb).
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    /// Nếu true, dùng time-sensitive interruption (cần entitlement + capability).
    var bypassFocusMode: Bool = true

    private override init() {
        super.init()
    }

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("[NotificationService] Auth error: \(error.localizedDescription)")
            } else {
                print("[NotificationService] Permission granted: \(granted)")
            }
        }
    }

    func sendTimerFinished(title: String, timerID: UUID) {
        let content = UNMutableNotificationContent()
        content.title = "BattTimer"
        content.body = "\(title) — Time's up!"
        content.sound = .default

        // Time-sensitive giúp hiện alert dù đang Focus / DND (macOS 12+).
        if bypassFocusMode {
            content.interruptionLevel = .timeSensitive
        }

        content.userInfo = ["timerID": timerID.uuidString]

        let request = UNNotificationRequest(
            identifier: "timer-finished-\(timerID.uuidString)",
            content: content,
            trigger: nil // deliver ngay
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationService] Failed: \(error.localizedDescription)")
            }
        }
    }

    // Hiện banner ngay cả khi app đang foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
