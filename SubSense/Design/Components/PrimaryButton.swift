import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard !isLoading && !isDisabled else { return }
            action()
        }) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.appCallout)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.button)
                    .fill(LinearGradient(
                        colors: isDisabled
                            ? [.appTextMuted, .appTextMuted]
                            : [.brand, .brandDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(
                        color: isDisabled ? .clear : .brand.opacity(0.3),
                        radius: 12, x: 0, y: 4
                    )
            }
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
            .sensoryFeedback(.impact(.soft), trigger: configuration.isPressed)
    }
}
