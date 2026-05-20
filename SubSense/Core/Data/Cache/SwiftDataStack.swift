import SwiftData
import Foundation

// SwiftData is used as a local cache only.
// Supabase is the source of truth.
@Model
final class CachedSubscription {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var name: String
    var categoryRaw: String
    var price: Double
    var currency: String
    var cycleRaw: String
    var nextDate: Date
    var statusRaw: String
    var brandColor: String?
    var updatedAt: Date

    init(from sub: Subscription) {
        id = sub.id
        userId = sub.userId
        name = sub.name
        categoryRaw = sub.category.rawValue
        price = NSDecimalNumber(decimal: sub.price).doubleValue
        currency = sub.currency
        cycleRaw = sub.cycle.rawValue
        nextDate = sub.nextDate
        statusRaw = sub.status.rawValue
        brandColor = sub.brandColor
        updatedAt = sub.updatedAt
    }

    func toSubscription() -> Subscription? {
        guard let category = Subscription.Category(rawValue: categoryRaw),
              let cycle    = Subscription.Cycle(rawValue: cycleRaw),
              let status   = Subscription.Status(rawValue: statusRaw)
        else { return nil }
        return Subscription(
            id: id, userId: userId, name: name,
            category: category, serviceType: nil, logoURL: nil,
            brandColor: brandColor,
            price: Decimal(price), currency: currency,
            cycle: cycle, startDate: nil,
            nextDate: nextDate, trialEndDate: nil, billingDay: nil,
            status: status, nickname: nil, notes: nil,
            reminderEnabled: true,
            createdAt: updatedAt, updatedAt: updatedAt
        )
    }
}

@MainActor
var sharedModelContainer: ModelContainer = {
    let schema = Schema([CachedSubscription.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: false)
    do {
        return try ModelContainer(for: schema, configurations: config)
    } catch {
        fatalError("SwiftData container failed: \(error)")
    }
}()
