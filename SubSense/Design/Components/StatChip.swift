import SwiftUI

struct StatChip: View {
    let value: String
    let label: String
    var valueFont: Font = .appTitle2
    var alignment: HorizontalAlignment = .center

    var body: some View {
        VStack(alignment: alignment, spacing: AppSpacing.xs) {
            Text(value)
                .font(valueFont)
                .foregroundStyle(Color.appTextPrimary)
                .contentTransition(.numericText())

            Text(label)
                .font(.appCaption)
                .foregroundStyle(Color.appTextMuted)
        }
    }
}
