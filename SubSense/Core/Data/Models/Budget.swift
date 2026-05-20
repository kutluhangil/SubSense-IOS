import Foundation

struct Budget: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var category: String
    var monthlyLimit: Decimal
    var currency: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", category
        case monthlyLimit = "monthly_limit"
        case currency, createdAt = "created_at"
    }
}
