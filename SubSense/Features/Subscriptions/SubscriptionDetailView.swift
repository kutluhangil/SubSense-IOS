import SwiftUI

// MARK: - Detail View
struct SubscriptionDetailView: View {
    let subscription: Subscription

    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionRepository.self) private var repository
    @Environment(CurrencyService.self) private var currencyService
    @State private var profileRepo = ProfileRepository()
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var deleteTrigger = false
    @State private var inactivateTrigger = false

    private var baseCurrency: String { profileRepo.profile?.baseCurrency ?? "USD" }

    private func formatted(_ amount: Decimal) -> String {
        let converted = currencyService.convert(amount, from: subscription.currency, to: baseCurrency)
        return currencyService.formatAmount(converted, currency: baseCurrency)
    }

    private var monthsActive: Int {
        guard let start = subscription.startDate else { return 1 }
        return max(1, Calendar.current.dateComponents([.month], from: start, to: Date()).month ?? 1)
    }

    private var lifetimeTotal: Decimal {
        Decimal(monthsActive) * subscription.monthlyEquivalent
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                // Ambient brand color wash
                LinearGradient(
                    colors: [
                        Color(hex: subscription.effectiveBrandColor).opacity(0.08),
                        Color.appBackground
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl2) {
                        heroSection
                        priceCard
                        statsRow
                        notesSection
                        actionButtons
                        Spacer().frame(height: AppSpacing.xl3)
                    }
                    .padding(.top, AppSpacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showEdit = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button {
                            Task {
                                try? await repository.markInactive(id: subscription.id)
                                inactivateTrigger.toggle()
                                dismiss()
                            }
                        } label: {
                            Label("Mark Inactive", systemImage: "pause.circle")
                        }
                        Divider()
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.brand)
                    }
                }
            }
            .sheet(isPresented: $showEdit) {
                EditSubscriptionView(subscription: subscription)
            }
            .confirmationDialog(
                String(format: String(localized: "subscription.delete.confirm"), subscription.name),
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(String(localized: "general.delete"), role: .destructive) {
                    Task {
                        try? await repository.delete(id: subscription.id)
                        deleteTrigger.toggle()
                        dismiss()
                    }
                }
                Button(String(localized: "general.cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "subscription.delete.permanent"))
            }
            .sensoryFeedback(.impact, trigger: deleteTrigger)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: inactivateTrigger)
            .task {
                if let uid = profileRepo.profile?.id { _ = uid } // no-op
            }
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: AppSpacing.md) {
            BrandIcon(
                name: subscription.name,
                brandColor: Color(hex: subscription.effectiveBrandColor),
                size: 80,
                radius: 20
            )
            .shadow(
                color: Color(hex: subscription.effectiveBrandColor).opacity(0.30),
                radius: 20, x: 0, y: 8
            )

            VStack(spacing: AppSpacing.xs) {
                Text(subscription.name)
                    .font(.appTitle)
                    .foregroundStyle(Color.appTextPrimary)
                Text(subscription.category.displayName)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextMuted)
                StatusBadge(status: subscription.status)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Price Card
    private var priceCard: some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(formatted(subscription.monthlyEquivalent) + "/\(String(localized: "subscription.perMonth.short"))")
                            .font(.appTitle2)
                            .foregroundStyle(Color.appTextPrimary)
                            .contentTransition(.numericText())
                        Text(formatted(subscription.yearlyEquivalent) + "/\(String(localized: "subscription.perYear.short"))")
                            .font(.appFootnote)
                            .foregroundStyle(Color.appTextMuted)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                }
                Divider().background(Color.appBorder)
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.appTextMuted)
                        .font(.appFootnote)
                    Text("\(String(localized: "subscription.nextCharge")): \(subscription.nextDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.appFootnote)
                        .foregroundStyle(Color.appTextMuted)
                    Spacer()
                    let days = subscription.daysUntilRenewal
                    if days >= 0 {
                        Text(days == 0 ? "today" : days == 1 ? "tomorrow" : "in \(days) days")
                            .font(.appCaption.weight(.semibold))
                            .foregroundStyle(days <= 3 ? Color.appDanger : Color.appTextMuted)
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.base)
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 0) {
            detailStatCell(
                value: formatted(subscription.yearlyEquivalent),
                label: String(localized: "subscription.stats.thisYear")
            )
            Divider()
                .frame(height: 40)
            detailStatCell(
                value: "\(monthsActive)",
                label: String(localized: "subscription.stats.months")
            )
            Divider()
                .frame(height: 40)
            detailStatCell(
                value: formatted(lifetimeTotal),
                label: String(localized: "subscription.stats.lifetime")
            )
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
        .padding(.horizontal, AppSpacing.base)
    }

    // MARK: - Notes
    @ViewBuilder
    private var notesSection: some View {
        if let notes = subscription.notes, !notes.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(title: String(localized: "subscription.notes"))
                Text(notes)
                    .font(.appBody)
                    .foregroundStyle(Color.appTextMuted)
                    .padding(.horizontal, AppSpacing.base)
            }
        }
    }

    // MARK: - Actions
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            PrimaryButton(title: String(localized: "subscription.edit.title")) {
                showEdit = true
            }
            SecondaryButton(title: String(localized: "subscription.markInactive")) {
                Task {
                    try? await repository.markInactive(id: subscription.id)
                    inactivateTrigger.toggle()
                    dismiss()
                }
            }
            Button {
                showDeleteConfirm = true
            } label: {
                Text(String(localized: "subscription.delete"))
                    .font(.appCallout)
                    .foregroundStyle(Color.appDanger)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .fill(Color.appDanger.opacity(0.08))
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.button)
                                    .strokeBorder(Color.appDanger.opacity(0.20), lineWidth: 1)
                            }
                    }
            }
        }
        .padding(.horizontal, AppSpacing.base)
    }

    // MARK: - Stat Cell
    private func detailStatCell(value: String, label: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(.appCallout.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.appCaption)
                .foregroundStyle(Color.appTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: Subscription.Status

    private var badgeColor: Color {
        Color(hex: status.color)
    }

    var body: some View {
        Text(status.displayName)
            .font(.appCaption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background {
                Capsule()
                    .fill(badgeColor)
            }
    }
}

#Preview {
    SubscriptionDetailView(subscription: .mock)
        .environment(SubscriptionRepository())
        .environment(CurrencyService())
}
