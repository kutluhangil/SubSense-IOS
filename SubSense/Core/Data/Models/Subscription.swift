import Foundation

struct Subscription: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var name: String
    var category: Category
    var serviceType: String?
    var logoURL: URL?
    var brandColor: String?
    var price: Decimal
    var currency: String
    var cycle: Cycle
    var startDate: Date?
    var nextDate: Date
    var trialEndDate: Date?
    var billingDay: Int?
    var status: Status
    var nickname: String?
    var notes: String?
    var reminderEnabled: Bool
    let createdAt: Date
    var updatedAt: Date

    // MARK: - Nested Types
    enum Cycle: String, Codable, CaseIterable {
        case monthly = "Monthly"
        case yearly  = "Yearly"

        var displayName: String {
            switch self {
            case .monthly: return String(localized: "subscription.cycle.monthly")
            case .yearly:  return String(localized: "subscription.cycle.yearly")
            }
        }
    }

    enum Status: String, Codable, CaseIterable {
        case active   = "Active"
        case trial    = "Trial"
        case expiring = "Expiring"
        case inactive = "Inactive"

        var displayName: String { rawValue }

        var color: String {
            switch self {
            case .active:   return "#10B981"
            case .trial:    return "#F59E0B"
            case .expiring: return "#EF4444"
            case .inactive: return "#71717A"
            }
        }
    }

    enum Category: String, Codable, CaseIterable {
        case entertainment = "entertainment"
        case music         = "music"
        case gaming        = "gaming"
        case design        = "design"
        case ai            = "ai"
        case productivity  = "productivity"
        case business      = "business"
        case shopping      = "shopping"
        case storage       = "storage"
        case fitness       = "fitness"
        case news          = "news"
        case education     = "education"
        case other         = "other"

        var displayName: String {
            switch self {
            case .entertainment: return "Entertainment"
            case .music:         return "Music"
            case .gaming:        return "Gaming"
            case .design:        return "Design"
            case .ai:            return "AI"
            case .productivity:  return "Productivity"
            case .business:      return "Business"
            case .shopping:      return "Shopping"
            case .storage:       return "Storage"
            case .fitness:       return "Fitness"
            case .news:          return "News"
            case .education:     return "Education"
            case .other:         return "Other"
            }
        }

        var symbol: String {
            switch self {
            case .entertainment: return "play.tv.fill"
            case .music:         return "music.note"
            case .gaming:        return "gamecontroller.fill"
            case .design:        return "paintbrush.fill"
            case .ai:            return "cpu.fill"
            case .productivity:  return "doc.fill"
            case .business:      return "briefcase.fill"
            case .shopping:      return "bag.fill"
            case .storage:       return "externaldrive.fill"
            case .fitness:       return "figure.run"
            case .news:          return "newspaper.fill"
            case .education:     return "book.fill"
            case .other:         return "square.grid.2x2.fill"
            }
        }

        var brandColor: String {
            switch self {
            case .entertainment: return "#E50914"
            case .music:         return "#1DB954"
            case .gaming:        return "#107C10"
            case .design:        return "#FF0000"
            case .ai:            return "#6366F1"
            case .productivity:  return "#4285F4"
            case .business:      return "#0077B5"
            case .shopping:      return "#FF9900"
            case .storage:       return "#0061FF"
            case .fitness:       return "#FC4C02"
            case .news:          return "#1A1A1A"
            case .education:     return "#1F8EF1"
            case .other:         return "#71717A"
            }
        }
    }

    // MARK: - Computed Properties
    var monthlyEquivalent: Decimal {
        cycle == .yearly ? price / 12 : price
    }

    var yearlyEquivalent: Decimal {
        cycle == .monthly ? price * 12 : price
    }

    var daysUntilRenewal: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
    }

    var isRenewingSoon: Bool { daysUntilRenewal <= 3 }
    var isRenewingToday: Bool { daysUntilRenewal == 0 }

    var effectiveBrandColor: String {
        brandColor ?? category.brandColor
    }

    // MARK: - Duplicate detection
    func isDuplicate(of other: Subscription) -> Bool {
        name.lowercased() == other.name.lowercased() &&
        currency == other.currency &&
        price == other.price &&
        cycle == other.cycle &&
        status != .inactive &&
        other.status != .inactive
    }

    // MARK: - CodingKeys (snake_case <-> camelCase)
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", name, category
        case serviceType = "service_type"
        case logoURL = "logo_url"
        case brandColor = "brand_color"
        case price, currency, cycle
        case startDate = "start_date"
        case nextDate = "next_date"
        case trialEndDate = "trial_end_date"
        case billingDay = "billing_day"
        case status, nickname, notes
        case reminderEnabled = "reminder_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Mock data for previews
extension Subscription {
    static let mock = Subscription(
        id: UUID(),
        userId: UUID(),
        name: "Netflix",
        category: .entertainment,
        serviceType: "Streaming",
        logoURL: nil,
        brandColor: "#E50914",
        price: 15.99,
        currency: "USD",
        cycle: .monthly,
        startDate: Date().addingTimeInterval(-86400 * 365),
        nextDate: Date().addingTimeInterval(86400 * 2),
        trialEndDate: nil,
        billingDay: 28,
        status: .active,
        nickname: nil,
        notes: nil,
        reminderEnabled: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockList: [Subscription] = [
        .mock,
        Subscription(
            id: UUID(), userId: UUID(), name: "Spotify",
            category: .music, serviceType: "Music", logoURL: nil,
            brandColor: "#1DB954", price: 9.99, currency: "USD",
            cycle: .monthly, startDate: nil,
            nextDate: Date().addingTimeInterval(86400 * 5),
            trialEndDate: nil, billingDay: nil, status: .active,
            nickname: nil, notes: nil, reminderEnabled: true,
            createdAt: Date(), updatedAt: Date()
        ),
        Subscription(
            id: UUID(), userId: UUID(), name: "ChatGPT Plus",
            category: .ai, serviceType: "AI", logoURL: nil,
            brandColor: "#10B981", price: 20.00, currency: "USD",
            cycle: .monthly, startDate: nil,
            nextDate: Date().addingTimeInterval(86400 * 11),
            trialEndDate: nil, billingDay: nil, status: .active,
            nickname: nil, notes: nil, reminderEnabled: true,
            createdAt: Date(), updatedAt: Date()
        ),
    ]
}
