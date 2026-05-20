import Foundation
import Supabase

final class AssistantService {
    private let client = SupabaseClientManager.shared

    struct ChatMessage: Identifiable {
        let id = UUID()
        let role: Role
        var content: String
        let timestamp = Date()

        enum Role { case user, assistant }
    }

    struct ChatRequest: Encodable {
        let message: String
        let subscriptions: [[String: String]]
        let baseCurrency: String
        let language: String
    }

    func sendMessage(
        _ message: String,
        subscriptions: [Subscription],
        baseCurrency: String,
        language: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        let subData = subscriptions.map { sub -> [String: String] in
            [
                "name": sub.name,
                "price": "\(sub.price)",
                "currency": sub.currency,
                "cycle": sub.cycle.rawValue,
                "category": sub.category.rawValue,
            ]
        }

        let request = ChatRequest(
            message: message,
            subscriptions: subData,
            baseCurrency: baseCurrency,
            language: language
        )

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let response: String = try await client.functions
                        .invoke("ai-chat", options: .init(body: request))
                        .value
                    continuation.yield(response)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
