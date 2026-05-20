import SwiftUI

struct GlassBackgroundModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var cornerRadius: CGFloat = AppRadius.card

    func body(content: Content) -> some View {
        content
            .background {
                Group {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.appSurface)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.regularMaterial)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.appBorder, lineWidth: 1)
                }
            }
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = AppRadius.card) -> some View {
        modifier(GlassBackgroundModifier(cornerRadius: cornerRadius))
    }
}
