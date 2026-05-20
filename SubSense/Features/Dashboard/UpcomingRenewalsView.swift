import SwiftUI

// MARK: - Container
struct UpcomingRenewalsView: View {
    let subscriptions: [Subscription]
    let currency: String
    let currencyService: CurrencyService
    let onTapSubscription: (Subscription) -> Void

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(subscriptions.prefix(5)) { sub in
                UpcomingRenewalRow(
                    subscription: sub,
                    currency: currency,
                    currencyService: currencyService
                )
                .onTapGesture { onTapSubscription(sub) }
                .contextMenu {
                    Button {
                        onTapSubscription(sub)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        // Delete handled by parent via onTapSubscription → detail sheet
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

// MARK: - Row
struct UpcomingRenewalRow: View {
    let subscription: Subscription
    let currency: String
    let currencyService: CurrencyService

    @State private var pulsing = false

    private var statusDotColor: Color {
        switch subscription.daysUntilRenewal {
        case 0...1:  return .appDanger
        case 2...5:  return .appWarning
        default:     return .appSuccess
        }
    }

    private var renewalLabel: String {
        switch subscription.daysUntilRenewal {
        case 0:     return String(localized: "renewal.today")
        case 1:     return String(localized: "renewal.tomorrow")
        default:    return "in \(subscription.daysUntilRenewal) days"
        }
    }

    private var convertedAmount: Decimal {
        currencyService.convert(
            subscription.monthlyEquivalent,
            from: subscription.currency,
            to: currency
        )
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {

            // Brand icon
            BrandIcon(
                name: subscription.name,
                brandColor: Color(hex: subscription.effectiveBrandColor),
                size: 44
            )

            // Name + cycle
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(subscription.name)
                    .font(.appCallout)
                    .foregroundStyle(.appTextPrimary)
                    .lineLimit(1)
                Text(subscription.cycle.displayName)
                    .font(.appCaption)
                    .foregroundStyle(.appTextMuted)
            }

            Spacer()

            // Renewal badge + price
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(statusDotColor)
                            .frame(width: 7, height: 7)

                        // Pulse ring for urgent renewals
                        if subscription.daysUntilRenewal <= 1 {
                            Circle()
                                .fill(statusDotColor.opacity(0.3))
                                .frame(width: 14, height: 14)
                                .scaleEffect(pulsing ? 1.6 : 1.0)
                                .opacity(pulsing ? 0 : 0.7)
                                .animation(
                                    .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                                    value: pulsing
                                )
                        }
                    }

                    Text(renewalLabel)
                        .font(.appCaption)
                        .foregroundStyle(statusDotColor)
                }

                Text(currencyService.formatAmount(convertedAmount, currency: currency))
                    .font(.appFootnote.weight(.semibold))
                    .foregroundStyle(.appTextPrimary)
                    .contentTransition(.numericText())
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
        .onAppear {
            if subscription.daysUntilRenewal <= 1 {
                pulsing = true
            }
        }
    }
}

#Preview {
    UpcomingRenewalsView(
        subscriptions: Subscription.mockList,
        currency: "USD",
        currencyService: CurrencyService(),
        onTapSubscription: { _ in }
    )
    .padding()
    .background(Color.appBackground)
}
