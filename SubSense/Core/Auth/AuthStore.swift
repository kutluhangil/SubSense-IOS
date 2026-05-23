import Foundation
import Supabase
import Observation

@Observable
final class AuthStore {
    var isAuthenticated = false
    var currentUser: User?
    var isLoading = true
    var profile: Profile?

    private let service = AuthService()
    private var authStateTask: Task<Void, Never>?

    init() {
        observeAuthState()
    }

    deinit {
        authStateTask?.cancel()
    }

    private func observeAuthState() {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "devAuthBypass") {
            isAuthenticated = true
            isLoading = false
            return
        }
        #endif
        authStateTask = Task {
            for await (event, session) in SupabaseClientManager.shared.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn, .tokenRefreshed, .userUpdated:
                        currentUser = session?.user
                        isAuthenticated = session != nil
                        isLoading = false
                    case .signedOut, .userDeleted:
                        currentUser = nil
                        isAuthenticated = false
                        profile = nil
                        isLoading = false
                    case .initialSession:
                        currentUser = session?.user
                        isAuthenticated = session != nil
                        isLoading = false
                    default:
                        isLoading = false
                    }
                }
            }
        }
    }

    // MARK: - Auth actions
    func signIn(email: String, password: String) async throws {
        try await service.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        try await service.signUp(email: email, password: password, displayName: displayName)
    }

    func signOut() async throws {
        try await service.signOut()
    }

    func resetPassword(email: String) async throws {
        try await service.resetPassword(email: email)
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        try await service.signInWithApple(idToken: idToken, nonce: nonce)
    }

    func deleteAccount() async throws {
        try await service.deleteAccount()
    }

    var userID: UUID? { currentUser?.id }
    var userEmail: String? { currentUser?.email }
}
