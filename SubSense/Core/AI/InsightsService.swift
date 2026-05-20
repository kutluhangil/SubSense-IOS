import Foundation
import Supabase

final class InsightsService {
    private let client = SupabaseClientManager.shared

    struct InsightsRequest: Encodable {
        let subscriptions: [SubscriptionSummary]
        let baseCurrency: String
        let language: String

        struct SubscriptionSummary: Encodable {
            let name: String
            let category: String
            let price: Double
            let currency: String
            let cycle: String
        }
    }

    struct InsightsResponse: Decodable {
        let insights: [AIInsightRaw]

        struct AIInsightRaw: Decodable {
            let type: String
            let title: String
            let description: String
            let estimatedSavings: Double?
            let relatedServices: [String]
        }
    }

    func fetchInsights(
        subscriptions: [Subscription],
        baseCurrency: String,
        language: String
    ) async throws -> [AIInsight] {
        let summaries = subscriptions.map { sub in
            InsightsRequest.SubscriptionSummary(
                name: sub.name,
                category: sub.category.rawValue,
                price: NSDecimalNumber(decimal: sub.price).doubleValue,
                currency: sub.currency,
                cycle: sub.cycle.rawValue
            )
        }

        let request = InsightsRequest(
            subscriptions: summaries,
            baseCurrency: baseCurrency,
            language: language
        )

        let response: InsightsResponse = try await client.functions
            .invoke("ai-insights", options: .init(body: request))
            .value

        return response.insights.map { raw in
            AIInsight(
                id: UUID(),
                userId: UUID(),
                insightType: raw.type == "redundancy" ? .redundancy : .cycleSwap,
                title: raw.title,
                description: raw.description,
                estimatedSavings: raw.estimatedSavings.map { Decimal($0) },
                relatedSubIds: [],
                generatedAt: Date(),
                dismissed: false
            )
        }
    }
}
