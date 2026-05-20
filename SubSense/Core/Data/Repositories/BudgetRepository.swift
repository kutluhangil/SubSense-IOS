import Foundation
import Supabase
import Observation

@Observable
final class BudgetRepository {
    var budgets: [Budget] = []

    private let client = SupabaseClientManager.shared

    func fetch(userId: UUID) async throws {
        budgets = try await client.database
            .from("budgets")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }

    func upsert(_ budget: Budget) async throws {
        try await client.database
            .from("budgets")
            .upsert(budget, onConflict: "user_id,category")
            .execute()
        if let idx = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[idx] = budget
        } else {
            budgets.append(budget)
        }
    }

    func delete(id: UUID) async throws {
        try await client.database
            .from("budgets")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        budgets.removeAll { $0.id == id }
    }
}
