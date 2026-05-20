import Foundation

struct UserPlan: Codable {
    let userId: UUID
    var tier: Tier
    var status: Status
    var productId: String?
    var originalTransactionId: String?
    var purchasedAt: Date?
    var expiresAt: Date?
    var autoRenew: Bool?
    var updatedAt: Date

    enum Tier: String, Codable {
        case free = "free"
        case pro  = "pro"
    }

    enum Status: String, Codable {
        case active      = "active"
        case trial       = "trial"
        case expired     = "expired"
        case gracePeriod = "grace_period"
        case revoked     = "revoked"
    }

    var isPro: Bool {
        tier == .pro && [.active, .trial, .gracePeriod].contains(status)
    }

    var isExpired: Bool {
        guard let exp = expiresAt else { return false }
        return exp < Date()
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id", tier, status
        case productId = "product_id"
        case originalTransactionId = "original_transaction_id"
        case purchasedAt = "purchased_at"
        case expiresAt   = "expires_at"
        case autoRenew   = "auto_renew"
        case updatedAt   = "updated_at"
    }
}
