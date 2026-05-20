import Foundation
import Observation

@Observable
final class DashboardViewModel {
    var isRefreshing = false
    var selectedSubscription: Subscription?
    var showAddSubscription = false
    var previousMonthTotal: Decimal = 0

    // MARK: - Refresh
    func refresh(
        repository: SubscriptionRepository,
        currencyService: CurrencyService,
        userId: UUID?
    ) async {
        guard let userId else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        async let _ = repository.fetchAll(userId: userId)
        async let _ = currencyService.fetchRates()
    }

    // MARK: - Previous month total
    /// Calculates last month's total using subscription startDates.
    /// Subscriptions with no startDate are assumed to have always been active.
    func estimatePreviousMonth(subscriptions: [Subscription], currency: String, using service: CurrencyService) -> Decimal {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return subscriptions
            .filter { sub in
                guard sub.status != .inactive else { return false }
                guard let start = sub.startDate else { return true }
                return start <= lastMonth
            }
            .reduce(Decimal.zero) { sum, sub in
                sum + service.convert(sub.monthlyEquivalent, from: sub.currency, to: currency)
            }
    }

    func updatePreviousMonth(subscriptions: [Subscription], currency: String, using service: CurrencyService) {
        previousMonthTotal = estimatePreviousMonth(subscriptions: subscriptions, currency: currency, using: service)
    }
}
