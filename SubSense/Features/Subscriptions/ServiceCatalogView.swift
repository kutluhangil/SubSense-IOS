import SwiftUI

struct ServiceCatalogView: View {
    let onSelect: (ServiceCatalogItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var items: [ServiceCatalogItem] = []
    @State private var searchText = ""

    // MARK: - Grouped data
    private var grouped: [String: [ServiceCatalogItem]] {
        let source = searchText.isEmpty
            ? items
            : items.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        return Dictionary(grouping: source) { $0.category.capitalized }
    }

    private var sortedCategories: [String] { grouped.keys.sorted() }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if items.isEmpty {
                    VStack(spacing: AppSpacing.md) {
                        ProgressView()
                        Text(String(localized: "catalog.loading"))
                            .font(.appFootnote)
                            .foregroundStyle(.appTextMuted)
                    }
                } else if sortedCategories.isEmpty {
                    EmptyState(
                        symbol: "magnifyingglass",
                        title: String(localized: "catalog.noResults"),
                        subtitle: String(localized: "catalog.noResults.subtitle")
                    )
                } else {
                    catalog
                }
            }
            .navigationTitle(String(localized: "subscription.discover.title"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: String(localized: "catalog.search"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.cancel")) { dismiss() }
                }
            }
        }
        .onAppear { loadCatalog() }
    }

    // MARK: - Catalog Grid
    private var catalog: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.xl) {
                ForEach(sortedCategories, id: \.self) { category in
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        SectionHeader(title: category)

                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: AppSpacing.md),
                                count: 4
                            ),
                            spacing: AppSpacing.md
                        ) {
                            ForEach(grouped[category] ?? []) { item in
                                catalogCell(item: item)
                            }
                        }
                        .padding(.horizontal, AppSpacing.base)
                    }
                }
                Spacer().frame(height: AppSpacing.xl3)
            }
            .padding(.top, AppSpacing.sm)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: searchText)
        }
    }

    private func catalogCell(item: ServiceCatalogItem) -> some View {
        Button {
            onSelect(item)
            dismiss()
        } label: {
            VStack(spacing: AppSpacing.xs) {
                BrandIcon(
                    name: item.name,
                    brandColor: Color(hex: item.brandColor),
                    size: 56,
                    radius: AppRadius.icon
                )
                Text(item.name)
                    .font(.appCaption)
                    .foregroundStyle(.appTextMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 64)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(.soft), trigger: item.id)
    }

    // MARK: - Load
    private func loadCatalog() {
        guard
            let url   = Bundle.main.url(forResource: "ServiceCatalog", withExtension: "json"),
            let data  = try? Data(contentsOf: url),
            let items = try? JSONDecoder().decode([ServiceCatalogItem].self, from: data)
        else { return }
        self.items = items
    }
}

#Preview {
    ServiceCatalogView { _ in }
}
