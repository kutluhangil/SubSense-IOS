import SwiftUI

struct SectionHeader: View {
    let title: String
    var trailingAction: (() -> Void)? = nil
    var trailingLabel: String? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.appCaption)
                .foregroundStyle(.appTextMuted)
                .tracking(0.5)

            Spacer()

            if let action = trailingAction, let label = trailingLabel {
                Button(action: action) {
                    Text(label)
                        .font(.appCaption)
                        .foregroundStyle(.brand)
                }
            }
        }
        .padding(.horizontal, AppSpacing.base)
    }
}
