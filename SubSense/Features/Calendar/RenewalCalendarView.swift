import SwiftUI

struct RenewalCalendarView: View {
    @Environment(SubscriptionRepository.self) private var repository
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date? = nil

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    private var daysInMonth: [Date?] {
        guard
            let range = calendar.range(of: .day, in: .month, for: displayedMonth),
            let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = Array(repeating: Optional<Date>.none, count: firstWeekday - 1)
        let days: [Date?] = range.map { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
        return leadingBlanks + days
    }

    private func renewals(for date: Date) -> [Subscription] {
        repository.subscriptions.filter { sub in
            calendar.isDate(sub.nextDate, inSameDayAs: date)
        }
    }

    private func dominantColor(for date: Date) -> Color? {
        let subs = renewals(for: date)
        guard !subs.isEmpty else { return nil }
        return Color(hex: subs.first?.effectiveBrandColor ?? "#6366F1")
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: AppSpacing.base) {
                // Month navigation
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            displayedMonth = calendar.date(
                                byAdding: .month, value: -1, to: displayedMonth
                            ) ?? displayedMonth
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.appCallout)
                            .foregroundStyle(.brand)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.appTitle2)
                        .foregroundStyle(.appTextPrimary)
                        .contentTransition(.opacity)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            displayedMonth = calendar.date(
                                byAdding: .month, value: 1, to: displayedMonth
                            ) ?? displayedMonth
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.appCallout)
                            .foregroundStyle(.brand)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, AppSpacing.base)

                // Weekday headers
                LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.appCaption.weight(.semibold))
                            .foregroundStyle(.appTextMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, AppSpacing.base)

                // Calendar grid
                LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                    ForEach(daysInMonth.indices, id: \.self) { idx in
                        if let date = daysInMonth[idx] {
                            calendarDayView(date: date)
                        } else {
                            Color.clear
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.base)

                // Selected date renewals list
                if let selected = selectedDate {
                    let dayRenewals = renewals(for: selected)
                    if !dayRenewals.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Divider().background(Color.appBorder)

                            SectionHeader(title: selected.formatted(date: .abbreviated, time: .omitted))
                                .padding(.horizontal, AppSpacing.base)

                            ScrollView {
                                VStack(spacing: AppSpacing.sm) {
                                    ForEach(dayRenewals) { sub in
                                        HStack(spacing: AppSpacing.md) {
                                            BrandIcon(
                                                name: sub.name,
                                                brandColor: Color(hex: sub.effectiveBrandColor),
                                                size: 36
                                            )
                                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                                Text(sub.name)
                                                    .font(.appCallout)
                                                    .foregroundStyle(.appTextPrimary)
                                                Text(sub.cycle.displayName)
                                                    .font(.appCaption)
                                                    .foregroundStyle(.appTextMuted)
                                            }
                                            Spacer()
                                            Text("\(sub.currency) \(sub.price)")
                                                .font(.appCallout.weight(.semibold))
                                                .foregroundStyle(.appTextPrimary)
                                        }
                                        .padding(AppSpacing.md)
                                        .background {
                                            RoundedRectangle(cornerRadius: AppRadius.card)
                                                .fill(Color.appSurface)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: AppRadius.card)
                                                        .strokeBorder(Color.appBorder, lineWidth: 1)
                                                }
                                        }
                                        .padding(.horizontal, AppSpacing.base)
                                    }
                                }
                            }
                            .frame(maxHeight: 220)
                        }
                    }
                }

                Spacer()
            }
            .padding(.top, AppSpacing.md)
        }
        .navigationTitle(String(localized: "analytics.calendar"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func calendarDayView(date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let dotColor = dominantColor(for: date)
        let renewalCount = renewals(for: date).count

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedDate = isSelected ? nil : date
            }
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle().fill(.brand).frame(width: 34, height: 34)
                    } else if isToday {
                        Circle().fill(.brand.opacity(0.12)).frame(width: 34, height: 34)
                    }
                    Text("\(calendar.component(.day, from: date))")
                        .font(.appCallout)
                        .foregroundStyle(
                            isSelected ? .white : isToday ? Color.brand : Color.appTextPrimary
                        )
                }

                // Renewal dots
                if let dotColor {
                    HStack(spacing: 2) {
                        ForEach(0..<min(renewalCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(dotColor)
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    Color.clear.frame(height: 4)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 46)
    }
}
