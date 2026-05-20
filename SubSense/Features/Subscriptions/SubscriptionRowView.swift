import SwiftUI

struct SubscriptionRowView: View {
    let subscription: Subscription
    let currency: String
    let currencyService: CurrencyService
    let onEdit: (() -> Void)?
    let onDelete: () -> Void
    let onMarkInactive: () -> Void

    @State private var showDeleteConfirm = false

    init(
        subscription: Subscription,
        currency: String,
        currencyService: CurrencyService,
        onEdit: (() -> Void)? = nil,
        onDelete: @escaping () -> Void,
        onMarkInactive: @escaping () -> Void
    ) {
        self.subscription = subscription
        self.currency = currency
        self.currencyService = currencyService
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onMarkInactive = onMarkInactive
    }

    private var convertedMonthly: Decimal {
        currencyService.convert(
            subscription.monthlyEquivalent,
            from: subscription.currency,
            to: currency
        )
    }

    private var renewalText: String {
        let days = subscription.daysUntilRenewal
        switch days {
        case ..<0:  return ""
        case 0:     return String(localized: "renewal.today")
        case 1:     return String(localized: "renewal.tomorrow")
        default:    return "in \(days) days"
        }
    }

    private var renewalColor: Color {
        let days = subscription.daysUntilRenewal
        if days <= 1 { return .appDanger }
        if days <= 5 { return .appWarning }
        return .appTextMuted
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {

            // Brand icon
            BrandIcon(
                name: subscription.name,
                brandColor: Color(hex: subscription.effectiveBrandColor),
                size: 44
            )

            // Name + meta
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(subscription.name)
                    .font(.appCallout)
                    .foregroundStyle(.appTextPrimary)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.xs) {
                    Text(subscription.category.displayName)
                        .font(.appCaption)
                        .foregroundStyle(.appTextMuted)

                    if subscription.daysUntilRenewal >= 0 {
                        Text("·")
                            .font(.appCaption)
                            .foregroundStyle(.appTextMuted)
                        Text(renewalText)
                            .font(.appCaption)
                            .foregroundStyle(renewalColor)
                    }
                }
            }

            Spacer()

            // Price + cycle
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text(currencyService.formatAmount(convertedMonthly, currency: currency))
                    .font(.appCallout.weight(.semibold))
                    .foregroundStyle(.appTextPrimary)
                    .contentTransition(.numericText())
                Text(subscription.cycle.displayName)
                    .font(.appCaption)
                    .foregroundStyle(.appTextMuted)
            }
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
        .brandHalo(color: Color(hex: subscription.effectiveBrandColor), intensity: 0.04)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onMarkInactive()
            } label: {
                Label("Deactivate", systemImage: "pause.circle")
            }
            .tint(.appTextMuted)
        }
        .contextMenu {
            if let onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            Button {
                onMarkInactive()
            } label: {
                Label("Mark Inactive", systemImage: "pause.circle")
            }
            Divider()
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete \(subscription.name)?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .sensoryFeedback(.impact(.soft), trigger: showDeleteConfirm)
    }
}

#Preview {
    SubscriptionRowView(
        subscription: .mock,
        currency: "USD",
        currencyService: CurrencyService(),
        onDelete: {},
        onMarkInactive: {}
    )
    .padding()
    .background(Color.appBackground)
}
