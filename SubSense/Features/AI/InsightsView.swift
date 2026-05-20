import SwiftUI

struct InsightsView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(SubscriptionRepository.self) private var repository
    @State private var profileRepo = ProfileRepository()
    @State private var insights: [AIInsight] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var showAssistant = false
    @State private var showPaywall = false
    @State private var dismissedIds: Set<UUID> = []

    private let insightsService = InsightsService()

    private var visibleInsights: [AIInsight] {
        insights.filter { !dismissedIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if !profileRepo.isPro {
                    paywallTeaserView
                } else if isLoading {
                    loadingView
                } else if visibleInsights.isEmpty && !isLoading {
                    EmptyState(
                        symbol: "sparkles",
                        title: String(localized: "ai.insights.empty.title"),
                        subtitle: String(localized: "ai.insights.empty.subtitle"),
                        action: { Task { await loadInsights() } },
                        actionLabel: String(localized: "general.retry")
                    )
                } else {
                    insightsScrollView
                }
            }
            .navigationTitle(String(localized: "ai.insights.title"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAssistant) {
                AssistantChatView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .task {
                if let uid = authStore.userID {
                    try? await profileRepo.fetch(userId: uid)
                    if profileRepo.isPro && insights.isEmpty {
                        await loadInsights()
                    }
                }
            }
        }
    }

    // MARK: - Insights scroll view
    private var insightsScrollView: some View {
        ScrollView {
            insightsContent
        }
    }

    private var insightsContent: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.accent)
                Text(String(localized: "ai.poweredBy"))
                    .font(.appFootnote)
                    .foregroundStyle(Color.appTextMuted)
                Text("· \(visibleInsights.count) \(String(localized: "ai.insightsFound"))")
                    .font(.appFootnote)
                    .foregroundStyle(Color.appTextMuted)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.base)

            ForEach(visibleInsights) { insight in
                InsightCard(insight: insight) {
                    withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                        _ = dismissedIds.insert(insight.id)
                    }
                }
                .padding(.horizontal, AppSpacing.base)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }

            assistantCTAButton

            Spacer().frame(height: AppSpacing.xl4)
        }
        .padding(.top, AppSpacing.md)
    }

    private var assistantCTAButton: some View {
        Button {
            showAssistant = true
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.accent.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "message.fill")
                        .font(.appCallout)
                        .foregroundStyle(Color.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "ai.askAssistant"))
                        .font(.appCallout.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text(String(localized: "ai.assistant.subtitle"))
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextMuted)
            }
            .padding(AppSpacing.base)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .fill(Color.accent.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.card)
                            .strokeBorder(Color.accent.opacity(0.15), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.base)
    }

    // MARK: - Loading skeleton
    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .fill(Color.appSurface)
                    .frame(height: 120)
                    .shimmer(isLoading: true)
                    .padding(.horizontal, AppSpacing.base)
            }
        }
        .padding(.top, AppSpacing.xl)
    }

    // MARK: - Paywall teaser
    private var paywallTeaserView: some View {
        VStack(spacing: AppSpacing.xl2) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 56, weight: .thin))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accent)
                .symbolEffect(.pulse, options: .repeating.speed(0.5))

            VStack(spacing: AppSpacing.md) {
                Text(String(localized: "ai.insights.proRequired.title"))
                    .font(.appTitle)
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                Text(String(localized: "ai.insights.proRequired.subtitle"))
                    .font(.appBody)
                    .foregroundStyle(Color.appTextMuted)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(title: String(localized: "settings.upgrade")) {
                showPaywall = true
            }
            .frame(maxWidth: 280)

            Spacer()
        }
        .padding(AppSpacing.xl)
    }

    // MARK: - Data
    private func loadInsights() async {
        guard let profile = profileRepo.profile else { return }
        isLoading = true
        do {
            insights = try await insightsService.fetchInsights(
                subscriptions: repository.subscriptions,
                baseCurrency: profile.baseCurrency,
                language: profile.preferredLanguage.rawValue
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - InsightCard

struct InsightCard: View {
    let insight: AIInsight
    let onDismiss: () -> Void

    var body: some View {
        GlassCard(padding: AppSpacing.base) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(
                                insight.insightType == .redundancy
                                    ? Color.appWarning.opacity(0.12)
                                    : Color.brand.opacity(0.12)
                            )
                            .frame(width: 36, height: 36)
                        Image(systemName: insight.insightType.symbol)
                            .font(.appCallout)
                            .foregroundStyle(insight.insightType == .redundancy ? Color.appWarning : Color.brand)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(insight.title)
                            .font(.appCallout.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                    }
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextMuted)
                            .padding(AppSpacing.sm)
                    }
                }

                Text(insight.description)
                    .font(.appFootnote)
                    .foregroundStyle(Color.appTextMuted)
                    .lineSpacing(3)

                if let savings = insight.estimatedSavings {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.appSuccess)
                            .font(.appCaption)
                        Text("Estimated savings: $\(NSDecimalNumber(decimal: savings).stringValue)/year")
                            .font(.appCaption.weight(.semibold))
                            .foregroundStyle(Color.appSuccess)
                    }
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background {
                        Capsule().fill(Color.appSuccess.opacity(0.08))
                    }
                }
            }
        }
    }
}
