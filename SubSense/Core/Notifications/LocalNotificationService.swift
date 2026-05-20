import UserNotifications
import Foundation

final class LocalNotificationService {
    static let shared = LocalNotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Schedule renewal reminder
    func scheduleRenewal(for subscription: Subscription, daysBefore: Int = 3) {
        let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBefore,
            to: subscription.nextDate
        ) ?? subscription.nextDate

        // Don't schedule in the past
        guard notificationDate > Date() else { return }

        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: notificationDate
        )
        dateComponents.hour = 9
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = subscription.name
        content.body = String(format: NSLocalizedString("notifications.renewal", comment: ""),
                              subscription.name, daysBefore)
        content.sound = .default
        content.userInfo = ["subscriptionId": subscription.id.uuidString]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "renewal-\(subscription.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelRenewal(for subscriptionId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["renewal-\(subscriptionId.uuidString)"])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func scheduledNotificationCount() async -> Int {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.count
    }

    func refreshBadge() async {
        let count = await scheduledNotificationCount()
        try? await UNUserNotificationCenter.current().setBadgeCount(count)
    }
}
