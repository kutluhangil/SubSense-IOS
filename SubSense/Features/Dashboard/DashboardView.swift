import SwiftUI

// MARK: - DashboardView
struct DashboardView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(SubscriptionRepository.self) private var repository
    @Environment(CurrencyService.self) private var currencyService
    @State private var profileRepo = ProfileRepository()
    @State private var vm = DashboardViewModel()
    @State private var showDetail: Subscription?
    @State private var showAdd = false

    private var baseCurrency: String {
        profileRepo.profile?.baseCurrency ?? "USD"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {

                        // Error banner
                        if repository.error != nil {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.appWarning)
                                Text(String(localized: "dashboard.error"))
                                    .font(.appFootnote)
                                    .foregroundStyle(.appTextPrimary)
                                Spacer()
                            }
                            .padding(AppSpacing.md)
                            .background {
                                RoundedRectangle(cornerRadius: AppRadius.card)
                                    .fill(Color.appWarning.opacity(0.08))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: AppRadius.card)
                                            .strokeBorder(Color.appWarning.opacity(0.2), lineWidth: 1)
                                    }
                            }
                            .padding(.horizontal, AppSpacing.base)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Stats card
                        StatsCardView(
                            monthlyTotal: repository.monthlyTotal,
                            yearlyTotal: repository.yearlyTotal,
                            activeCount: repository.activeCount,
                            currency: baseCurrency,
                            previousMonthTotal: vm.previousMonthTotal
                        )
                        .padding(.horizontal, AppSpacing.base)
                        .shimmer(isLoading: repository.isLoading && repository.subscriptions.isEmpty)

                        // Up Next section
                        if !repository.upcomingRenewals.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                SectionHeader(title: String(localized: "dashboard.upNext"))

                                UpcomingRenewalsView(
                                    subscriptions: repository.upcomingRenewals,
                                    currency: baseCurrency,
                                    currencyService: currencyService,
                                    onTapSubscription: { sub in
                                        showDetail = sub
                                    }
                                )
                                .padding(.horizontal, AppSpacing.base)
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else if !repository.isLoading {
                            EmptyState(
                                symbol: "calendar.badge.plus",
                                title: String(localized: "dashboard.noRenewals.title"),
                                subtitle: String(localized: "dashboard.noRenewals.subtitle"),
                                action: { showAdd = true },
                                actionLabel: String(localized: "subscription.add.title")
                            )
                            .transition(.opacity)
                        }

                        // See all button
                        if repository.activeCount > 0 {
                            seeAllButton
                                .padding(.horizontal, AppSpacing.base)
                        }

                        // AI Insight teaser
                        AIInsightTeaserView(isPro: profileRepo.isPro)
                            .padding(.horizontal, AppSpacing.base)

                        // Bottom padding for tab bar + floating button
                        Spacer().frame(height: AppSpacing.xl4)
                    }
                    .padding(.top, AppSpacing.md)
                }
                .refreshable {
                    await vm.refresh(
                        repository: repository,
                        currencyService: currencyService,
                        userId: authStore.userID
                    )
                    vm.updatePreviousMonth(subscriptions: repository.subscriptions, currency: baseCurrency, using: currencyService)
                }
            }
            .navigationTitle(String(localized: "dashboard.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        avatarButton
                    }
                }
            }
            .sheet(item: $showDetail) { sub in
                SubscriptionDetailView(subscription: sub)
            }
            .sheet(isPresented: $showAdd) {
                AddSubscriptionView()
            }
            .task {
                guard let userId = authStore.userID else { return }
                try? await profileRepo.fetch(userId: userId)
                await vm.refresh(
                    repository: repository,
                    currencyService: currencyService,
                    userId: userId
                )
                vm.updatePreviousMonth(subscriptions: repository.subscriptions, currency: baseCurrency, using: currencyService)
            }
        }
    }

    // MARK: - Subviews
    private var avatarButton: some View {
        ZStack {
            Circle()
                .fill(Color.brand.opacity(0.12))
                .frame(width: 36, height: 36)
            Text(profileRepo.profile?.initials ?? "U")
                .font(.appCaption.weight(.semibold))
                .foregroundStyle(.brand)
        }
        .accessibilityLabel("Profile")
    }

    private var seeAllButton: some View {
        NavigationLink {
            SubscriptionListView()
        } label: {
            HStack {
                Text(String(format: String(localized: "dashboard.seeAll"), repository.activeCount))
                    .font(.appCallout)
                    .foregroundStyle(.brand)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.appCaption)
                    .foregroundStyle(.brand)
            }
            .padding(AppSpacing.base)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .fill(Color.brand.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.card)
                            .strokeBorder(Color.brand.opacity(0.10), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AI Insight Teaser
struct AIInsightTeaserView: View {
    let isPro: Bool
    @State private var showInsights = false
    @State private var showPaywall = false

    var body: some View {
        Button {
            if isPro {
                showInsights = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.accent.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(.appCallout)
                        .foregroundStyle(.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AppSpacing.sm) {
                        Text(String(localized: "dashboard.aiInsight"))
                            .font(.appCallout.weight(.semibold))
                            .foregroundStyle(.appTextPrimary)
                        if !isPro {
                            Text("PRO")
                                .font(.appCaption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.accent))
                        }
                    }
                    Text(String(localized: "dashboard.aiInsight.subtitle"))
                        .font(.appFootnote)
                        .foregroundStyle(.appTextMuted)
                }

                Spacer()

                Image(systemName: isPro ? "chevron.right" : "lock.fill")
                    .font(.appCaption)
                    .foregroundStyle(.appTextMuted)
            }
            .padding(AppSpacing.base)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .fill(Color.accent.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.card)
                            .strokeBorder(Color.accent.opacity(0.12), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(.soft), trigger: showInsights)
        .sensoryFeedback(.impact(.soft), trigger: showPaywall)
        .sheet(isPresented: $showInsights) {
            InsightsView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    DashboardView()
        .environment(AuthStore())
        .environment(SubscriptionRepository())
        .environment(CurrencyService())
}
