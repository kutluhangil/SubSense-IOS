import Foundation

struct AIInsight: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var insightType: InsightType
    var title: String
    var description: String
    var estimatedSavings: Decimal?
    var relatedSubIds: [UUID]
    var generatedAt: Date
    var dismissed: Bool

    enum InsightType: String, Codable {
        case redundancy = "redundancy"
        case cycleSwap  = "cycle_swap"

        var symbol: String {
            switch self {
            case .redundancy: return "exclamationmark.triangle.fill"
            case .cycleSwap:  return "arrow.trianglehead.2.clockwise.rotate.90"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id"
        case insightType = "insight_type"
        case title, description
        case estimatedSavings = "estimated_savings"
        case relatedSubIds    = "related_sub_ids"
        case generatedAt      = "generated_at"
        case dismissed
    }
}
