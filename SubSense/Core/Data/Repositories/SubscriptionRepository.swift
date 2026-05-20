import Foundation
import Supabase
import Observation

@Observable
final class SubscriptionRepository {
    var subscriptions: [Subscription] = []
    var inactiveSubscriptions: [Subscription] = []
    var isLoading = false
    var error: APIError?

    private let client = SupabaseClientManager.shared

    // MARK: - Fetch

    func fetchAll(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            subscriptions = try await client.database
                .from("subscriptions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .neq("status", value: "Inactive")
                .order("next_date", ascending: true)
                .execute()
                .value
            error = nil
        } catch {
            self.error = .networkError(error)
        }
    }

    func fetchInactive(userId: UUID) async throws {
        inactiveSubscriptions = try await client.database
            .from("subscriptions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "Inactive")
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Create

    func add(_ sub: Subscription) async throws {
        guard !isDuplicate(sub) else { throw APIError.duplicateSubscription }
        try await insertToRemote(sub)
    }

    /// Bypasses duplicate check — used when user confirms "Add anyway".
    func forceAdd(_ sub: Subscription) async throws {
        try await insertToRemote(sub)
    }

    private func insertToRemote(_ sub: Subscription) async throws {
        try await client.database
            .from("subscriptions")
            .insert(sub)
            .execute()
        subscriptions.append(sub)
        subscriptions.sort { $0.nextDate < $1.nextDate }
    }

    // MARK: - Update

    func update(_ sub: Subscription) async throws {
        try await client.database
            .from("subscriptions")
            .update(sub)
            .eq("id", value: sub.id.uuidString)
            .execute()
        if let idx = subscriptions.firstIndex(where: { $0.id == sub.id }) {
            subscriptions[idx] = sub
        }
    }

    // MARK: - Delete

    func delete(id: UUID) async throws {
        try await client.database
            .from("subscriptions")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        subscriptions.removeAll { $0.id == id }
        inactiveSubscriptions.removeAll { $0.id == id }
    }

    func markInactive(id: UUID) async throws {
        try await client.database
            .from("subscriptions")
            .update(["status": "Inactive"])
            .eq("id", value: id.uuidString)
            .execute()
        if let sub = subscriptions.first(where: { $0.id == id }) {
            var updated = sub
            updated.status = .inactive
            inactiveSubscriptions.insert(updated, at: 0)
        }
        subscriptions.removeAll { $0.id == id }
    }

    // MARK: - Duplicate detection

    func isDuplicate(_ sub: Subscription) -> Bool {
        subscriptions.contains { $0.isDuplicate(of: sub) && $0.id != sub.id }
    }

    // MARK: - Computed analytics
    // NOTE: These sum raw amounts across currencies. Pass to CurrencyService.convert() in the view layer.

    var monthlyTotal: Decimal {
        subscriptions.filter { $0.status != .inactive }
            .reduce(0) { $0 + $1.monthlyEquivalent }
    }

    var yearlyTotal: Decimal { monthlyTotal * 12 }

    /// Returns monthly total converted to `baseCurrency` using the provided service.
    func convertedMonthlyTotal(to baseCurrency: String, using service: CurrencyService) -> Decimal {
        subscriptions
            .filter { $0.status != .inactive }
            .reduce(Decimal.zero) { sum, sub in
                sum + service.convert(sub.monthlyEquivalent, from: sub.currency, to: baseCurrency)
            }
    }

    func convertedYearlyTotal(to baseCurrency: String, using service: CurrencyService) -> Decimal {
        convertedMonthlyTotal(to: baseCurrency, using: service) * 12
    }

    var upcomingRenewals: [Subscription] {
        subscriptions
            .filter { $0.status == .active || $0.status == .trial }
            .filter { $0.daysUntilRenewal >= 0 }
            .sorted { $0.nextDate < $1.nextDate }
            .prefix(5)
            .map { $0 }
    }

    var byCategory: [Subscription.Category: [Subscription]] {
        Dictionary(grouping: subscriptions.filter { $0.status != .inactive }) { $0.category }
    }

    var activeCount: Int { subscriptions.filter { $0.status == .active }.count }
    var trialCount: Int  { subscriptions.filter { $0.status == .trial  }.count }
}
