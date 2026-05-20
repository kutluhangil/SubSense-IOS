import Foundation

struct Profile: Identifiable, Codable {
    let id: UUID
    var email: String
    var displayName: String?
    var avatarURL: URL?
    var baseCurrency: String
    var preferredLanguage: Language
    var region: String
    var themePref: ThemePref
    var analyticsOptOut: Bool
    let createdAt: Date
    var updatedAt: Date

    enum Language: String, Codable, CaseIterable {
        case en = "en"
        case tr = "tr"

        var displayName: String {
            switch self {
            case .en: return "English"
            case .tr: return "Türkçe"
            }
        }
    }

    enum ThemePref: String, Codable, CaseIterable {
        case light  = "light"
        case dark   = "dark"
        case system = "system"

        var displayName: String {
            switch self {
            case .light:  return "Light"
            case .dark:   return "Dark"
            case .system: return "System"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName  = "display_name"
        case avatarURL    = "avatar_url"
        case baseCurrency = "base_currency"
        case preferredLanguage = "preferred_lang"
        case region
        case themePref    = "theme_pref"
        case analyticsOptOut = "analytics_opt_out"
        case createdAt    = "created_at"
        case updatedAt    = "updated_at"
    }

    var initials: String {
        let name = displayName ?? email
        let parts = name.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)).uppercased() }.joined()
    }
}
