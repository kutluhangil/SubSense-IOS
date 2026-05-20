import SwiftUI

struct StatsCardView: View {
    let monthlyTotal: Decimal
    let yearlyTotal: Decimal
    let activeCount: Int
    let currency: String
    let previousMonthTotal: Decimal

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isExpanded = false

    private var delta: Decimal { monthlyTotal - previousMonthTotal }
    private var deltaIsPositive: Bool { delta > 0 }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.base) {

                // Label
                Text(String(localized: "dashboard.thisMonth").uppercased())
                    .font(.appCaption)
                    .foregroundStyle(.appTextMuted)
                    .tracking(0.5)

                // Big amount
                Text(formatDecimal(monthlyTotal, currency: currency))
                    .font(.display)
                    .foregroundStyle(.appTextPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: monthlyTotal)

                // Delta
                if delta != 0 {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: deltaIsPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.appCaption)
                            .foregroundStyle(deltaIsPositive ? .appDanger : .appSuccess)
                        Text("\(formatDecimal(abs(delta), currency: currency)) \(String(localized: "dashboard.vsLastMonth"))")
                            .font(.appFootnote)
                            .foregroundStyle(.appTextMuted)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider()
                    .background(Color.appBorder)

                // Bottom stats row
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.appCaption)
                        .foregroundStyle(.appSuccess)
                    Text("\(activeCount) \(String(localized: "dashboard.active"))")
                        .font(.appFootnote)
                        .foregroundStyle(.appTextMuted)
                        .contentTransition(.numericText())
                    Text("·")
                        .foregroundStyle(.appTextMuted)
                        .font(.appFootnote)
                    Text("\(formatDecimal(yearlyTotal, currency: currency))/\(String(localized: "subscription.perYear.short"))")
                        .font(.appFootnote)
                        .foregroundStyle(.appTextMuted)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: yearlyTotal)
                }

                // Expanded breakdown
                if isExpanded {
                    Divider()
                        .background(Color.appBorder)

                    HStack(alignment: .top) {
                        StatChip(
                            value: formatDecimal(yearlyTotal, currency: currency),
                            label: String(localized: "dashboard.yearlyTotal"),
                            valueFont: .appCallout,
                            alignment: .leading
                        )
                        Spacer()
                        StatChip(
                            value: formatDecimal(monthlyTotal * 3, currency: currency),
                            label: "3 \(String(localized: "dashboard.months"))",
                            valueFont: .appCallout,
                            alignment: .trailing
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(AppSpacing.xl)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .fill(
                        reduceTransparency
                            ? AnyShapeStyle(Color.appSurface)
                            : AnyShapeStyle(.regularMaterial)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.card)
                            .strokeBorder(Color.brand.opacity(0.12), lineWidth: 1)
                    }
            }
            .shadow(color: .brand.opacity(0.08), radius: 20, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .brandHalo(color: .brand, intensity: 0.05)
        .accessibilityLabel(
            "Monthly total: \(formatDecimal(monthlyTotal, currency: currency)). \(activeCount) active subscriptions."
        )
    }

    private func formatDecimal(_ value: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(currency) \(value)"
    }
}

#Preview {
    StatsCardView(
        monthlyTotal: 142.97,
        yearlyTotal: 1715.64,
        activeCount: 12,
        currency: "USD",
        previousMonthTotal: 130.00
    )
    .padding()
    .background(Color.appBackground)
}
