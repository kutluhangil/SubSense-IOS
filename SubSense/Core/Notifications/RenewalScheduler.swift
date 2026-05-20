import Foundation
import WidgetKit

final class RenewalScheduler {
    static let shared = RenewalScheduler()
    private let notificationService = LocalNotificationService.shared

    private init() {}

    func rescheduleAll(subscriptions: [Subscription]) {
        notificationService.cancelAll()
        let enabled = subscriptions.filter { $0.reminderEnabled && $0.status != .inactive }
        for sub in enabled {
            notificationService.scheduleRenewal(for: sub)
        }
        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()
    }

    func schedule(_ subscription: Subscription) {
        guard subscription.reminderEnabled else { return }
        notificationService.scheduleRenewal(for: subscription)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func cancel(_ subscription: Subscription) {
        notificationService.cancelRenewal(for: subscription.id)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
