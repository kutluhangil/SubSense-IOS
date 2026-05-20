import Foundation
import Supabase
import Observation

@Observable
final class ProfileRepository {
    var profile: Profile?
    var userPlan: UserPlan?
    var isLoading = false

    private let client = SupabaseClientManager.shared

    func fetch(userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        profile = try await client.database
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        userPlan = try? await client.database
            .from("user_plans")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func update(_ profile: Profile) async throws {
        try await client.database
            .from("profiles")
            .update(profile)
            .eq("id", value: profile.id.uuidString)
            .execute()
        self.profile = profile
    }

    var isPro: Bool { userPlan?.isPro ?? false }
}
