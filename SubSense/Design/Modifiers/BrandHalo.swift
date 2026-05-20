import SwiftUI

struct BrandHaloModifier: ViewModifier {
    let color: Color
    var intensity: Double = 0.10
    var radius: CGFloat = 40

    func body(content: Content) -> some View {
        content
            .background {
                RadialGradient(
                    colors: [color.opacity(intensity), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
                .scaleEffect(1.5)
                .allowsHitTesting(false)
            }
    }
}

extension View {
    func brandHalo(color: Color, intensity: Double = 0.10) -> some View {
        modifier(BrandHaloModifier(color: color, intensity: intensity))
    }
}
