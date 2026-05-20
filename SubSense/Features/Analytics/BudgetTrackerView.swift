import SwiftUI

struct BudgetTrackerView: View {
    let subscriptions: [Subscription]
    let budgets: [Budget]
    let currency: String
    let currencyService: CurrencyService

    private func spent(for category: String) -> Decimal {
        subscriptions
            .filter { $0.category.rawValue == category && $0.status != .inactive }
            .reduce(Decimal(0)) {
                $0 + currencyService.convert($1.monthlyEquivalent, from: $1.currency, to: currency)
            }
    }

    var body: some View {
        if !budgets.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader(title: String(localized: "analytics.budgets"))

                VStack(spacing: AppSpacing.sm) {
                    ForEach(budgets) { budget in
                        let spentAmount = spent(for: budget.category)
                        let progress = min(
                            NSDecimalNumber(decimal: spentAmount / budget.monthlyLimit).doubleValue,
                            1.0
                        )
                        let isOver = spentAmount > budget.monthlyLimit

                        GlassCard(padding: AppSpacing.md) {
                            VStack(spacing: AppSpacing.sm) {
                                HStack {
                                    Text(budget.category.capitalized)
                                        .font(.appCallout)
                                        .foregroundStyle(Color.appTextPrimary)
                                    Spacer()
                                    Text(
                                        "\(currencyService.formatAmount(spentAmount, currency: currency)) / \(currencyService.formatAmount(budget.monthlyLimit, currency: currency))"
                                    )
                                    .font(.appFootnote)
                                    .foregroundStyle(isOver ? Color.appDanger : Color.appTextMuted)
                                    .contentTransition(.numericText())
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.appSurfaceAlt)
                                            .frame(height: 6)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(isOver ? Color.appDanger : Color.appSuccess)
                                            .frame(width: geo.size.width * progress, height: 6)
                                            .animation(Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: progress)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                }
            }
        }
    }
}
