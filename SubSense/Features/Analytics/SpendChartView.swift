import SwiftUI
import Charts

enum TimeRange: String, CaseIterable {
    case month30 = "30d"
    case month3  = "3m"
    case month6  = "6m"
    case month12 = "12m"

    var months: Int {
        switch self {
        case .month30: return 1
        case .month3:  return 3
        case .month6:  return 6
        case .month12: return 12
        }
    }

    var localizedTitle: String {
        switch self {
        case .month30: return String(localized: "analytics.range.30d")
        case .month3:  return String(localized: "analytics.range.3m")
        case .month6:  return String(localized: "analytics.range.6m")
        case .month12: return String(localized: "analytics.range.12m")
        }
    }
}

struct MonthlyDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Decimal
}

struct SpendChartView: View {
    let subscriptions: [Subscription]
    let currency: String
    let currencyService: CurrencyService
    @Binding var selectedRange: TimeRange

    private var dataPoints: [MonthlyDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        let monthsBack = selectedRange.months
        return (0..<monthsBack).reversed().map { offset in
            let date = calendar.date(byAdding: .month, value: -offset, to: today) ?? today
            let amount = subscriptions
                .filter { sub in
                    guard sub.status != .inactive else { return false }
                    guard let start = sub.startDate else { return true }
                    return start <= date
                }
                .reduce(Decimal(0)) { sum, sub in
                    sum + currencyService.convert(sub.monthlyEquivalent, from: sub.currency, to: currency)
                }
            return MonthlyDataPoint(date: date, amount: amount)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: String(localized: "analytics.spending.trend"))

            GlassCard(padding: AppSpacing.base) {
                Chart(dataPoints) { point in
                    AreaMark(
                        x: .value("Month", point.date, unit: .month),
                        y: .value("Amount", NSDecimalNumber(decimal: point.amount).doubleValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.brand.opacity(0.2), .brand.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Month", point.date, unit: .month),
                        y: .value("Amount", NSDecimalNumber(decimal: point.amount).doubleValue)
                    )
                    .foregroundStyle(.brand)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Month", point.date, unit: .month),
                        y: .value("Amount", NSDecimalNumber(decimal: point.amount).doubleValue)
                    )
                    .foregroundStyle(.brand)
                    .symbolSize(30)
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextMuted)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.appBorder)
                        AxisValueLabel()
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextMuted)
                    }
                }
                .accessibilityChartDescriptor(self)
            }
        }
    }
}

extension SpendChartView: AXChartDescriptorRepresentable {
    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXCategoricalDataAxisDescriptor(
            title: "Month",
            categoryOrder: dataPoints.map { $0.date.formatted(.dateTime.month()) }
        )
        let maxVal = dataPoints.map(\.amount).max() ?? 0
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Amount",
            range: 0...NSDecimalNumber(decimal: maxVal).doubleValue,
            gridlinePositions: []
        ) { value in "\(value)" }
        let series = AXDataSeriesDescriptor(
            name: "Monthly spend",
            isContinuous: true,
            dataPoints: dataPoints.map {
                AXDataPoint(
                    x: $0.date.formatted(.dateTime.month()),
                    y: NSDecimalNumber(decimal: $0.amount).doubleValue
                )
            }
        )
        return AXChartDescriptor(
            title: "Spending trend",
            summary: nil,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}
