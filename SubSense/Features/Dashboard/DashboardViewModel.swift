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

    // MARK: - Previous month estimate
    /// Approximates last month's total as 92% of current active subscriptions.
    /// Replace with a real historical fetch when billing history is implemented.
    func estimatePreviousMonth(subscriptions: [Subscription]) -> Decimal {
        subscriptions
            .filter { $0.status != .inactive }
            .reduce(Decimal.zero) { $0 + $1.monthlyEquivalent }
            * Decimal(string: "0.92")!
    }

    func updatePreviousMonth(subscriptions: [Subscription]) {
        previousMonthTotal = estimatePreviousMonth(subscriptions: subscriptions)
    }
}
