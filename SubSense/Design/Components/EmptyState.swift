import SwiftUI

struct EmptyState: View {
    let symbol: String
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.appTextMuted)
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(.appTitle2)
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.appBody)
                    .foregroundStyle(Color.appTextMuted)
                    .multilineTextAlignment(.center)
            }

            if let action, let label = actionLabel {
                PrimaryButton(title: label, action: action)
                    .frame(maxWidth: 240)
            }
        }
        .padding(AppSpacing.xl2)
    }
}
