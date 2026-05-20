import SwiftUI
import Charts

struct AnalyticsView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(SubscriptionRepository.self) private var repository
    @Environment(CurrencyService.self) private var currencyService
    @State private var profileRepo = ProfileRepository()
    @State private var budgetRepo = BudgetRepository()
    @State private var selectedRange: TimeRange = .month12

    private var baseCurrency: String { profileRepo.profile?.baseCurrency ?? "USD" }

    private var topServices: [(sub: Subscription, yearly: Decimal)] {
        repository.subscriptions
            .filter { $0.status != .inactive }
            .map { sub in
                let yearly = currencyService.convert(sub.yearlyEquivalent, from: sub.currency, to: baseCurrency)
                return (sub: sub, yearly: yearly)
            }
            .sorted { $0.yearly > $1.yearly }
    }

    private var maxYearly: Decimal {
        topServices.first?.yearly ?? 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {

                        // Time range picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.sm) {
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    FilterPill(
                                        title: range.rawValue,
                                        isSelected: selectedRange == range
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedRange = range
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppSpacing.base)
                        }

                        // Summary stats
                        HStack(spacing: AppSpacing.sm) {
                            GlassCard(padding: AppSpacing.md) {
                                StatChip(
                                    value: currencyService.formatAmount(repository.monthlyTotal, currency: baseCurrency),
                                    label: String(localized: "dashboard.thisMonth")
                                )
                            }
                            .frame(maxWidth: .infinity)

                            GlassCard(padding: AppSpacing.md) {
                                StatChip(
                                    value: currencyService.formatAmount(repository.yearlyTotal, currency: baseCurrency),
                                    label: String(localized: "dashboard.yearlyTotal")
                                )
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, AppSpacing.base)

                        // Spending trend chart
                        SpendChartView(
                            subscriptions: repository.subscriptions,
                            currency: baseCurrency,
                            currencyService: currencyService,
                            selectedRange: $selectedRange
                        )
                        .padding(.horizontal, AppSpacing.base)

                        // Category donut
                        CategoryDonutView(
                            subscriptions: repository.subscriptions,
                            currency: baseCurrency,
                            currencyService: currencyService
                        )
                        .padding(.horizontal, AppSpacing.base)

                        // Top services bar chart
                        if !topServices.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                SectionHeader(title: String(localized: "analytics.topServices"))

                                GlassCard(padding: AppSpacing.base) {
                                    VStack(spacing: AppSpacing.md) {
                                        ForEach(topServices.prefix(6), id: \.sub.id) { item in
                                            HStack(spacing: AppSpacing.md) {
                                                BrandIcon(
                                                    name: item.sub.name,
                                                    brandColor: Color(hex: item.sub.effectiveBrandColor),
                                                    size: 32
                                                )
                                                Text(item.sub.name)
                                                    .font(.appCallout)
                                                    .foregroundStyle(.appTextPrimary)
                                                    .lineLimit(1)

                                                Spacer()

                                                GeometryReader { geo in
                                                    let ratio = maxYearly > 0
                                                        ? CGFloat(truncating: NSDecimalNumber(decimal: item.yearly / maxYearly))
                                                        : 0
                                                    let barWidth = ratio * (geo.size.width * 0.5)
                                                    HStack {
                                                        Spacer()
                                                        RoundedRectangle(cornerRadius: 3)
                                                            .fill(Color(hex: item.sub.effectiveBrandColor).opacity(0.6))
                                                            .frame(width: max(4, barWidth), height: 6)
                                                    }
                                                }
                                                .frame(width: 80, height: 6)

                                                Text(
                                                    currencyService.formatAmount(item.yearly, currency: baseCurrency) + "/yr"
                                                )
                                                .font(.appCaption.weight(.semibold))
                                                .foregroundStyle(.appTextMuted)
                                                .frame(width: 72, alignment: .trailing)
                                                .contentTransition(.numericText())
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppSpacing.base)
                        }

                        // Budget tracker
                        BudgetTrackerView(
                            subscriptions: repository.subscriptions,
                            budgets: budgetRepo.budgets,
                            currency: baseCurrency,
                            currencyService: currencyService
                        )
                        .padding(.horizontal, AppSpacing.base)

                        // Calendar link
                        NavigationLink {
                            RenewalCalendarView()
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.brand)
                                Text(String(localized: "analytics.viewCalendar"))
                                    .font(.appCallout)
                                    .foregroundStyle(.brand)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.appCaption)
                                    .foregroundStyle(.appTextMuted)
                            }
                            .padding(AppSpacing.base)
                            .background {
                                RoundedRectangle(cornerRadius: AppRadius.card)
                                    .fill(Color.appSurface)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: AppRadius.card)
                                            .strokeBorder(Color.appBorder, lineWidth: 1)
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppSpacing.base)

                        Spacer().frame(height: AppSpacing.xl4)
                    }
                    .padding(.top, AppSpacing.md)
                }
            }
            .navigationTitle(String(localized: "analytics.title"))
            .navigationBarTitleDisplayMode(.large)
            .task {
                if let uid = authStore.userID {
                    try? await profileRepo.fetch(userId: uid)
                    try? await budgetRepo.fetch(userId: uid)
                }
            }
        }
    }
}

#Preview {
    AnalyticsView()
        .environment(AuthStore())
        .environment(SubscriptionRepository())
        .environment(CurrencyService())
}
