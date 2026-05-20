import Foundation
import Supabase
import AuthenticationServices

final class AuthService {
    private let client = SupabaseClientManager.shared

    // MARK: - Email / Password
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        try await client.auth.signUp(
            email: email,
            password: password,
            data: ["display_name": AnyJSON.string(displayName)]
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    func resendVerificationEmail(email: String) async throws {
        try await client.auth.resend(email: email, type: .signup)
    }

    func refreshSession() async throws {
        try await client.auth.refreshSession()
    }

    // MARK: - Apple Sign-In
    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    // MARK: - Current session
    var currentSession: Session? {
        get async { try? await client.auth.session }
    }

    var currentUserID: UUID? {
        get async { await currentSession?.user.id }
    }

    // MARK: - Account deletion (via edge function)
    func deleteAccount() async throws {
        guard let uid = await currentUserID else { throw APIError.unauthenticated }
        let _: Data = try await client.functions.invoke(
            "delete-account",
            options: .init(body: ["user_id": uid.uuidString])
        )
        try await signOut()
    }
}
