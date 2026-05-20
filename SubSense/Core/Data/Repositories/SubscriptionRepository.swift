import Foundation
import Supabase
import Observation

@Observable
final class SubscriptionRepository {
    var subscriptions: [Subscription] = []
    var isLoading = false
    var error: APIError?

    private let client = SupabaseClientManager.shared
    private var realtimeChannel: RealtimeChannelV2?

    // MARK: - Fetch
    func fetchAll(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result: [Subscription] = try await client.database
                .from("subscriptions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .neq("status", value: "Inactive")
                .order("next_date", ascending: true)
                .execute()
                .value
            subscriptions = result
        } catch {
            self.error = .networkError(error)
        }
    }

    func fetchAll(includeInactive: Bool = false, userId: UUID) async throws -> [Subscription] {
        var query = client.database
            .from("subscriptions")
            .select()
            .eq("user_id", value: userId.uuidString)
        if !includeInactive {
            query = query.neq("status", value: "Inactive")
        }
        return try await query
            .order("next_date", ascending: true)
            .execute()
            .value
    }

    // MARK: - Create
    func add(_ sub: Subscription) async throws {
        guard !isDuplicate(sub) else { throw APIError.duplicateSubscription }
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
    }

    func markInactive(id: UUID) async throws {
        try await client.database
            .from("subscriptions")
            .update(["status": "Inactive"])
            .eq("id", value: id.uuidString)
            .execute()
        subscriptions.removeAll { $0.id == id }
    }

    // MARK: - Duplicate detection
    func isDuplicate(_ sub: Subscription) -> Bool {
        subscriptions.contains { $0.isDuplicate(of: sub) && $0.id != sub.id }
    }

    // MARK: - Computed analytics
    var monthlyTotal: Decimal {
        subscriptions.filter { $0.status != .inactive }
            .reduce(0) { $0 + $1.monthlyEquivalent }
    }

    var yearlyTotal: Decimal { monthlyTotal * 12 }

    var upcomingRenewals: [Subscription] {
        subscriptions
            .filter { $0.status != .inactive && $0.daysUntilRenewal >= 0 }
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
