import SwiftUI

struct SectionHeader: View {
    let title: String
    var trailingAction: (() -> Void)? = nil
    var trailingLabel: String? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.appCaption)
                .foregroundStyle(Color.appTextMuted)
                .tracking(0.5)

            Spacer()

            if let action = trailingAction, let label = trailingLabel {
                Button {
                    action()
                } label: {
                    Text(label)
                        .font(.appCaption)
                        .foregroundStyle(Color.brand)
                }
            }
        }
        .padding(.horizontal, AppSpacing.base)
    }
}
