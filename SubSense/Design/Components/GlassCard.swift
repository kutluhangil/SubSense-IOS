import SwiftUI

struct GlassCard<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let content: Content
    var padding: CGFloat = AppSpacing.base

    init(padding: CGFloat = AppSpacing.base, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: AppRadius.card)
                        .fill(Color.appSurface)
                } else {
                    RoundedRectangle(cornerRadius: AppRadius.card)
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.card)
                                .strokeBorder(Color.appBorder, lineWidth: 1)
                        }
                }
            }
    }
}

extension View {
    func glassCard(padding: CGFloat = AppSpacing.base) -> some View {
        GlassCard(padding: padding) { self }
    }
}
