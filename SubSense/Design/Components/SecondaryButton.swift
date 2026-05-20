import SwiftUI

struct SecondaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.brand)
                } else {
                    Text(title)
                        .font(.appCallout)
                        .foregroundStyle(Color.brand)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.button)
                    .strokeBorder(Color.brand, lineWidth: 1.5)
            }
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: isPressed)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
        ._onButtonGesture(pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
