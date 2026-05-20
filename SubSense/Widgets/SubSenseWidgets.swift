import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SubSenseEntry: TimelineEntry {
    let date: Date
    let monthlyTotal: Double
    let currency: String
    let nextRenewal: NextRenewal?

    struct NextRenewal {
        let name: String
        let daysUntil: Int
        let brandColor: Color
    }
}

// MARK: - Timeline Provider

struct SubSenseProvider: TimelineProvider {
    func placeholder(in context: Context) -> SubSenseEntry {
        SubSenseEntry(
            date: .now,
            monthlyTotal: 142.50,
            currency: "USD",
            nextRenewal: .init(name: "Netflix", daysUntil: 2, brandColor: .red)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SubSenseEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubSenseEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> SubSenseEntry {
        let defaults = UserDefaults(suiteName: "group.com.subsense.app")
        let monthly = defaults?.double(forKey: "widget_monthly_total") ?? 0
        let currency = defaults?.string(forKey: "widget_currency") ?? "USD"
        let nextName = defaults?.string(forKey: "widget_next_name")
        let nextDays = defaults?.integer(forKey: "widget_next_days") ?? 0
        let nextColor = defaults?.string(forKey: "widget_next_color") ?? "#6366F1"

        var nextRenewal: SubSenseEntry.NextRenewal?
        if let name = nextName {
            nextRenewal = .init(name: name, daysUntil: nextDays, brandColor: Color(hex: nextColor))
        }

        return SubSenseEntry(
            date: .now,
            monthlyTotal: monthly,
            currency: currency,
            nextRenewal: nextRenewal
        )
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: SubSenseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2.bold())
                    .foregroundStyle(.indigo)
                Spacer()
                Text("SubSense")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formattedTotal)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            Text("this month")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let next = entry.nextRenewal {
                Divider()
                    .padding(.vertical, 2)

                HStack(spacing: 4) {
                    Circle()
                        .fill(next.brandColor)
                        .frame(width: 6, height: 6)
                    Text(next.name)
                        .font(.caption2.bold())
                        .lineLimit(1)
                    Spacer()
                    Text("in \(next.daysUntil)d")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .containerBackground(.regularMaterial, for: .widget)
    }

    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = entry.currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: entry.monthlyTotal)) ?? "$0"
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: SubSenseEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption.bold())
                        .foregroundStyle(.indigo)
                    Text("SubSense")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(formattedTotal)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text("monthly spend")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("NEXT UP")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)

                if let next = entry.nextRenewal {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(next.brandColor)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Text(String(next.name.prefix(1)))
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(next.name)
                                .font(.subheadline.bold())
                                .lineLimit(1)
                            Text("in \(next.daysUntil) day\(next.daysUntil == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("No upcoming renewals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .containerBackground(.regularMaterial, for: .widget)
    }

    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = entry.currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: entry.monthlyTotal)) ?? "$0"
    }
}

// MARK: - Widget Configuration

struct SubSenseWidget: Widget {
    let kind = "SubSenseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubSenseProvider()) { entry in
            Group {
                SmallWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("SubSense")
        .description("Track your monthly subscription spend.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Widget Bundle

@main
struct SubSenseWidgetBundle: WidgetBundle {
    var body: some Widget {
        SubSenseWidget()
    }
}

// MARK: - Helpers

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    SubSenseWidget()
} timeline: {
    SubSenseEntry(
        date: .now,
        monthlyTotal: 142.50,
        currency: "USD",
        nextRenewal: .init(name: "Netflix", daysUntil: 2, brandColor: .red)
    )
}
