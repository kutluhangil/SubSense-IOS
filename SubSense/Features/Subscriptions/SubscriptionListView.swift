import SwiftUI

struct SubscriptionListView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(SubscriptionRepository.self) private var repository
    @Environment(CurrencyService.self) private var currencyService
    @State private var profileRepo = ProfileRepository()
    @State private var selectedFilter: FilterOption = .all
    @State private var searchText = ""
    @State private var editTarget: Subscription?
    @State private var showAdd = false
    @State private var deleteTrigger = false
    @State private var inactivateTrigger = false
    @State private var isLoadingInactive = false

    // MARK: - Filter

    enum FilterOption: CaseIterable, Identifiable {
        case all, active, trial, inactive
        var id: Self { self }

        var localizedTitle: String {
            switch self {
            case .all:      return String(localized: "subscription.filter.all")
            case .active:   return String(localized: "subscription.status.active")
            case .trial:    return String(localized: "subscription.status.trial")
            case .inactive: return String(localized: "subscription.status.inactive")
            }
        }
    }

    private var baseCurrency: String { profileRepo.profile?.baseCurrency ?? "USD" }

    private var filtered: [Subscription] {
        let subs: [Subscription]
        switch selectedFilter {
        case .all:      subs = repository.subscriptions
        case .active:   subs = repository.subscriptions.filter { $0.status == .active }
        case .trial:    subs = repository.subscriptions.filter { $0.status == .trial }
        case .inactive: subs = repository.inactiveSubscriptions
        }
        guard !searchText.isEmpty else { return subs }
        return subs.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var sections: [(title: String, subs: [Subscription])] {
        if selectedFilter != .all {
            return [(title: selectedFilter.localizedTitle, subs: filtered)]
        }
        let expiring = filtered.filter { $0.status == .expiring }
        let active   = filtered.filter { $0.status == .active }
        let trial    = filtered.filter { $0.status == .trial }
        var result: [(String, [Subscription])] = []
        if !expiring.isEmpty {
            result.append((String(localized: "subscription.section.expiringSoon"), expiring))
        }
        if !active.isEmpty {
            result.append((String(format: String(localized: "subscription.section.active"), active.count), active))
        }
        if !trial.isEmpty {
            result.append((String(format: String(localized: "subscription.section.trial"), trial.count), trial))
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if repository.isLoading && repository.subscriptions.isEmpty {
                    skeletonView
                } else if filtered.isEmpty && !repository.isLoading && !isLoadingInactive {
                    EmptyState(
                        symbol: "creditcard.fill",
                        title: String(localized: "subscription.empty.title"),
                        subtitle: String(localized: "subscription.empty.subtitle"),
                        action: { showAdd = true },
                        actionLabel: String(localized: "subscription.add.title")
                    )
                } else {
                    listContent
                }
            }
            .navigationTitle(String(localized: "subscription.title"))
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: String(localized: "subscription.search"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.brand)
                    }
                }
                ToolbarItem(placement: .principal) {
                    filterPills
                }
            }
            .sheet(isPresented: $showAdd) { AddSubscriptionView() }
            .sheet(item: $editTarget) { sub in EditSubscriptionView(subscription: sub) }
            .sensoryFeedback(.impact, trigger: deleteTrigger)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: inactivateTrigger)
            .task {
                guard let uid = authStore.userID else { return }
                try? await profileRepo.fetch(userId: uid)
                await repository.fetchAll(userId: uid)
            }
            .onChange(of: selectedFilter) { _, new in
                if new == .inactive {
                    Task { await loadInactive() }
                }
            }
            .refreshable {
                guard let uid = authStore.userID else { return }
                await repository.fetchAll(userId: uid)
                if selectedFilter == .inactive { await loadInactive() }
            }
        }
    }

    // MARK: - List

    private var listContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(sections, id: \.title) { section in
                    SectionHeader(title: section.title)
                        .padding(.top, AppSpacing.md)

                    ForEach(section.subs) { sub in
                        NavigationLink {
                            SubscriptionDetailView(subscription: sub)
                        } label: {
                            SubscriptionRowView(
                                subscription: sub,
                                currency: baseCurrency,
                                currencyService: currencyService,
                                onEdit: { editTarget = sub },
                                onDelete: {
                                    Task {
                                        try? await repository.delete(id: sub.id)
                                        deleteTrigger.toggle()
                                    }
                                },
                                onMarkInactive: {
                                    Task {
                                        try? await repository.markInactive(id: sub.id)
                                        inactivateTrigger.toggle()
                                    }
                                }
                            )
                            .padding(.horizontal, AppSpacing.base)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer().frame(height: AppSpacing.xl4)
            }
        }
    }

    // MARK: - Filter Pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(FilterOption.allCases) { option in
                    FilterPill(
                        title: option.localizedTitle,
                        isSelected: selectedFilter == option
                    ) {
                        withAnimation(Animation.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                            selectedFilter = option
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xs)
        }
    }

    // MARK: - Skeleton

    private var skeletonView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.sm) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: AppRadius.card)
                        .fill(Color.appSurface)
                        .frame(height: 72)
                        .shimmer(isLoading: true)
                        .padding(.horizontal, AppSpacing.base)
                }
            }
            .padding(.top, AppSpacing.xl)
        }
    }

    // MARK: - Load inactive

    private func loadInactive() async {
        guard let uid = authStore.userID else { return }
        isLoadingInactive = true
        defer { isLoadingInactive = false }
        try? await repository.fetchInactive(userId: uid)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.appCaption.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.appTextMuted)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background {
                    Capsule()
                        .fill(isSelected ? Color.brand : Color.appSurface)
                        .overlay {
                            if !isSelected {
                                Capsule()
                                    .strokeBorder(Color.appBorder, lineWidth: 1)
                            }
                        }
                }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isSelected)
    }
}

#Preview {
    SubscriptionListView()
        .environment(AuthStore())
        .environment(SubscriptionRepository())
        .environment(CurrencyService())
}
