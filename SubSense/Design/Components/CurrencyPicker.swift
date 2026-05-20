import SwiftUI

struct CurrencyPickerSheet: View {
    @Binding var selectedCurrency: String
    @Binding var isPresented: Bool
    @State private var searchText = ""

    private let currencies: [(code: String, name: String, flag: String)] = [
        ("USD", "US Dollar", "🇺🇸"),
        ("EUR", "Euro", "🇪🇺"),
        ("GBP", "British Pound", "🇬🇧"),
        ("TRY", "Turkish Lira", "🇹🇷"),
        ("JPY", "Japanese Yen", "🇯🇵"),
        ("CAD", "Canadian Dollar", "🇨🇦"),
        ("AUD", "Australian Dollar", "🇦🇺"),
        ("CHF", "Swiss Franc", "🇨🇭"),
        ("CNY", "Chinese Yuan", "🇨🇳"),
        ("INR", "Indian Rupee", "🇮🇳"),
        ("BRL", "Brazilian Real", "🇧🇷"),
        ("MXN", "Mexican Peso", "🇲🇽"),
        ("KRW", "South Korean Won", "🇰🇷"),
        ("SGD", "Singapore Dollar", "🇸🇬"),
        ("HKD", "Hong Kong Dollar", "🇭🇰"),
        ("NOK", "Norwegian Krone", "🇳🇴"),
        ("SEK", "Swedish Krona", "🇸🇪"),
        ("DKK", "Danish Krone", "🇩🇰"),
        ("AED", "UAE Dirham", "🇦🇪"),
        ("SAR", "Saudi Riyal", "🇸🇦"),
        ("PLN", "Polish Złoty", "🇵🇱"),
        ("RUB", "Russian Ruble", "🇷🇺"),
    ]

    private var filtered: [(code: String, name: String, flag: String)] {
        guard !searchText.isEmpty else { return currencies }
        return currencies.filter {
            $0.code.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered, id: \.code) { currency in
                Button {
                    selectedCurrency = currency.code
                    isPresented = false
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        Text(currency.flag)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.code)
                                .font(.appCallout)
                                .foregroundStyle(Color.appTextPrimary)
                            Text(currency.name)
                                .font(.appFootnote)
                                .foregroundStyle(Color.appTextMuted)
                        }
                        Spacer()
                        if currency.code == selectedCurrency {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.brand)
                                .font(.appCallout.weight(.semibold))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search currencies")
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}
