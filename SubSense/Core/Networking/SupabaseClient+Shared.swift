import Foundation
import Supabase

final class SupabaseClientManager {
    static let shared: SupabaseClient = {
        let url = URL(string: Secrets.supabaseURL)!
        return SupabaseClient(supabaseURL: url, supabaseKey: Secrets.supabaseAnonKey)
    }()
}
