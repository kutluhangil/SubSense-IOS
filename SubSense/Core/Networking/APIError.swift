import Foundation

enum APIError: LocalizedError {
    case unauthenticated
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case duplicateSubscription
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthenticated: return "Please sign in to continue."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .decodingError(let e): return "Data error: \(e.localizedDescription)"
        case .serverError(let msg): return msg
        case .duplicateSubscription: return "This subscription already exists."
        case .unknown: return "An unexpected error occurred."
        }
    }
}
