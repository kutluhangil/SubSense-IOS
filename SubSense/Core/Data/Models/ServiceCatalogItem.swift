import Foundation

struct ServiceCatalogItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: String
    let type: String
    let brandColor: String
    let logoSymbol: String
    let defaultPricing: [String: RegionPricing]

    struct RegionPricing: Codable, Hashable {
        let currency: String
        let monthly: Double?
        let yearly: Double?
    }

    func toSubscriptionDraft(region: String = "US") -> SubscriptionDraft {
        let pricing = defaultPricing[region] ?? defaultPricing["US"]
        return SubscriptionDraft(
            name: name,
            category: Subscription.Category(rawValue: category) ?? .other,
            brandColor: brandColor,
            price: Decimal(pricing?.monthly ?? 0),
            currency: pricing?.currency ?? "USD",
            cycle: .monthly
        )
    }
}

struct SubscriptionDraft {
    var name: String
    var category: Subscription.Category
    var brandColor: String
    var price: Decimal
    var currency: String
    var cycle: Subscription.Cycle
}
