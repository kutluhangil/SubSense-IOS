import Foundation

enum Secrets {
    private static var config: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any]
        else {
            fatalError("""
            Config.plist not found. Copy Config.plist.example to Config.plist
            and fill in your Supabase credentials.
            """)
        }
        return dict
    }()

    static var supabaseURL: String {
        config["SUPABASE_URL"] as? String ?? ""
    }

    static var supabaseAnonKey: String {
        config["SUPABASE_ANON_KEY"] as? String ?? ""
    }

    static var geminiAPIKey: String {
        config["GEMINI_API_KEY"] as? String ?? ""
    }
}
