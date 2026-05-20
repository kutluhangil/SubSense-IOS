import Foundation

struct CurrencyInfo: Identifiable, Hashable {
    let id: String   // ISO code e.g. "USD"
    let name: String
    let flag: String
    let symbol: String
}

enum Currencies {
    static let all: [CurrencyInfo] = [
        CurrencyInfo(id: "USD", name: "US Dollar",         flag: "🇺🇸", symbol: "$"),
        CurrencyInfo(id: "EUR", name: "Euro",              flag: "🇪🇺", symbol: "€"),
        CurrencyInfo(id: "GBP", name: "British Pound",     flag: "🇬🇧", symbol: "£"),
        CurrencyInfo(id: "TRY", name: "Turkish Lira",      flag: "🇹🇷", symbol: "₺"),
        CurrencyInfo(id: "JPY", name: "Japanese Yen",      flag: "🇯🇵", symbol: "¥"),
        CurrencyInfo(id: "CAD", name: "Canadian Dollar",   flag: "🇨🇦", symbol: "CA$"),
        CurrencyInfo(id: "AUD", name: "Australian Dollar", flag: "🇦🇺", symbol: "A$"),
        CurrencyInfo(id: "CHF", name: "Swiss Franc",       flag: "🇨🇭", symbol: "Fr"),
        CurrencyInfo(id: "CNY", name: "Chinese Yuan",      flag: "🇨🇳", symbol: "¥"),
        CurrencyInfo(id: "INR", name: "Indian Rupee",      flag: "🇮🇳", symbol: "₹"),
        CurrencyInfo(id: "BRL", name: "Brazilian Real",    flag: "🇧🇷", symbol: "R$"),
        CurrencyInfo(id: "MXN", name: "Mexican Peso",      flag: "🇲🇽", symbol: "MX$"),
        CurrencyInfo(id: "KRW", name: "South Korean Won",  flag: "🇰🇷", symbol: "₩"),
        CurrencyInfo(id: "SGD", name: "Singapore Dollar",  flag: "🇸🇬", symbol: "S$"),
        CurrencyInfo(id: "HKD", name: "Hong Kong Dollar",  flag: "🇭🇰", symbol: "HK$"),
        CurrencyInfo(id: "NOK", name: "Norwegian Krone",   flag: "🇳🇴", symbol: "kr"),
        CurrencyInfo(id: "SEK", name: "Swedish Krona",     flag: "🇸🇪", symbol: "kr"),
        CurrencyInfo(id: "DKK", name: "Danish Krone",      flag: "🇩🇰", symbol: "kr"),
        CurrencyInfo(id: "AED", name: "UAE Dirham",        flag: "🇦🇪", symbol: "د.إ"),
        CurrencyInfo(id: "SAR", name: "Saudi Riyal",       flag: "🇸🇦", symbol: "ر.س"),
        CurrencyInfo(id: "PLN", name: "Polish Zloty",      flag: "🇵🇱", symbol: "zł"),
        CurrencyInfo(id: "RUB", name: "Russian Ruble",     flag: "🇷🇺", symbol: "₽"),
        CurrencyInfo(id: "THB", name: "Thai Baht",         flag: "🇹🇭", symbol: "฿"),
        CurrencyInfo(id: "IDR", name: "Indonesian Rupiah", flag: "🇮🇩", symbol: "Rp"),
        CurrencyInfo(id: "MYR", name: "Malaysian Ringgit", flag: "🇲🇾", symbol: "RM"),
    ]

    static func symbol(for code: String) -> String {
        all.first { $0.id == code }?.symbol ?? code
    }

    static func flag(for code: String) -> String {
        all.first { $0.id == code }?.flag ?? ""
    }

    static func info(for code: String) -> CurrencyInfo? {
        all.first { $0.id == code }
    }
}
