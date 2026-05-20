import SwiftUI
import Charts

struct CategoryDataPoint: Identifiable {
    let id = UUID()
    let category: Subscription.Category
    let amount: Decimal
    let percentage: Double
}

struct CategoryDonutView: View {
    let subscriptions: [Subscription]
    let currency: String
    let currencyService: CurrencyService

    @State private var selectedCategory: Subscription.Category? = nil

    private var dataPoints: [CategoryDataPoint] {
        let active = subscriptions.filter { $0.status != .inactive }
        let total = active.reduce(Decimal(0)) {
            $0 + currencyService.convert($1.monthlyEquivalent, from: $1.currency, to: currency)
        }
        guard total > 0 else { return [] }

        let grouped = Dictionary(grouping: active) { $0.category }
        return grouped.map { category, subs in
            let catTotal = subs.reduce(Decimal(0)) {
                $0 + currencyService.convert($1.monthlyEquivalent, from: $1.currency, to: currency)
            }
            let pct = NSDecimalNumber(decimal: catTotal / total).doubleValue * 100
            return CategoryDataPoint(category: category, amount: catTotal, percentage: pct)
        }
        .sorted { $0.amount > $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: String(localized: "analytics.byCategory"))

            GlassCard(padding: AppSpacing.base) {
                HStack(alignment: .center, spacing: AppSpacing.xl) {
                    // Donut chart
                    Chart(dataPoints) { point in
                        SectorMark(
                            angle: .value("Amount", NSDecimalNumber(decimal: point.amount).doubleValue),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(Color(hex: point.category.brandColor))
                        .opacity(selectedCategory == nil || selectedCategory == point.category ? 1 : 0.3)
                    }
                    .frame(width: 130, height: 130)
                    .accessibilityChartDescriptor(self)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedCategory)

                    // Legend
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(dataPoints.prefix(5)) { point in
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedCategory = selectedCategory == point.category ? nil : point.category
                                }
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    Circle()
                                        .fill(Color(hex: point.category.brandColor))
                                        .frame(width: 8, height: 8)
                                    Text(point.category.displayName)
                                        .font(.appCaption)
                                        .foregroundStyle(.appTextPrimary)
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text(String(format: "%.0f%%", point.percentage))
                                            .font(.appCaption.weight(.semibold))
                                            .foregroundStyle(.appTextPrimary)
                                        Text(currencyService.formatAmount(point.amount, currency: currency))
                                            .font(Font.system(size: 9, weight: .regular))
                                            .foregroundStyle(.appTextMuted)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

extension CategoryDonutView: AXChartDescriptorRepresentable {
    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXCategoricalDataAxisDescriptor(
            title: "Category",
            categoryOrder: dataPoints.map(\.category.displayName)
        )
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Percentage",
            range: 0...100,
            gridlinePositions: []
        ) { "\($0)%" }
        let series = AXDataSeriesDescriptor(
            name: "Categories",
            isContinuous: false,
            dataPoints: dataPoints.map {
                AXDataPoint(x: $0.category.displayName, y: $0.percentage)
            }
        )
        return AXChartDescriptor(
            title: "Spending by category",
            summary: nil,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}
