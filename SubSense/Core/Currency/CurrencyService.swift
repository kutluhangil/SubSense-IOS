import Foundation
import Observation

@Observable
final class CurrencyService {
    var rates: [String: Double] = [:]
    var lastUpdated: Date?
    var isLoading = false

    private let cacheKey = "exchangeRates"
    private let cacheUpdatedKey = "exchangeRatesUpdatedAt"
    private let cacheMaxAge: TimeInterval = 86400 // 24h

    init() {
        loadCachedRates()
    }

    // MARK: - Fetch from Supabase edge function
    func fetchRates() async {
        guard shouldRefetch else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            struct RatesResponse: Decodable {
                let base: String
                let rates: [String: Double]
                let updated_at: String
            }

            let response: RatesResponse = try await SupabaseClientManager.shared.functions
                .invoke("exchange-rates")
                .value

            rates = response.rates
            lastUpdated = Date()
            cacheRates()
        } catch {
            // Use fallback rates if fetch fails
            rates = Self.fallbackRates
        }
    }

    // MARK: - Conversion
    func convert(_ amount: Decimal, from: String, to: String) -> Decimal {
        guard from != to else { return amount }
        let fromRate = rates[from] ?? Self.fallbackRates[from] ?? 1.0
        let toRate   = rates[to]   ?? Self.fallbackRates[to]   ?? 1.0
        let usdAmount = NSDecimalNumber(decimal: amount).doubleValue / fromRate
        return Decimal(usdAmount * toRate)
    }

    func formatAmount(_ amount: Decimal, currency: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(currency) \(amount)"
    }

    // MARK: - Cache
    private var shouldRefetch: Bool {
        guard let updated = lastUpdated else { return true }
        return Date().timeIntervalSince(updated) > cacheMaxAge
    }

    private func cacheRates() {
        UserDefaults.standard.set(rates, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: cacheUpdatedKey)
    }

    private func loadCachedRates() {
        if let cached = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: Double],
           let updated = UserDefaults.standard.object(forKey: cacheUpdatedKey) as? Date {
            rates = cached
            lastUpdated = updated
        } else {
            rates = Self.fallbackRates
        }
    }

    // MARK: - Fallback rates (approximate, vs USD)
    static let fallbackRates: [String: Double] = [
        "USD": 1.0, "EUR": 0.92, "GBP": 0.79, "TRY": 32.5,
        "JPY": 149.5, "CAD": 1.36, "AUD": 1.53, "CHF": 0.90,
        "CNY": 7.24, "INR": 83.1, "BRL": 4.97, "MXN": 17.2,
        "KRW": 1325.0, "SGD": 1.34, "HKD": 7.82, "NOK": 10.6,
        "SEK": 10.4, "DKK": 6.89, "AED": 3.67, "SAR": 3.75,
        "PLN": 4.0, "RUB": 91.0, "THB": 35.5, "IDR": 15700.0, "MYR": 4.72,
    ]
}
