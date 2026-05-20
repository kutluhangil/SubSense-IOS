import SwiftUI

struct ShimmerModifier: ViewModifier {
    let isLoading: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isLoading {
            content
                .hidden()
                .overlay {
                    GeometryReader { geo in
                        let gradient = LinearGradient(
                            stops: [
                                .init(color: Color.appSurfaceAlt, location: 0),
                                .init(color: Color.appSurface.opacity(0.8), location: 0.4),
                                .init(color: Color.appSurfaceAlt, location: 1),
                            ],
                            startPoint: .init(x: phase - 0.5, y: 0),
                            endPoint: .init(x: phase + 0.5, y: 0)
                        )
                        RoundedRectangle(cornerRadius: AppRadius.card)
                            .fill(gradient)
                    }
                }
                .onAppear {
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                        phase = 1.5
                    }
                }
        } else {
            content
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        }
    }
}

extension View {
    func shimmer(isLoading: Bool) -> some View {
        modifier(ShimmerModifier(isLoading: isLoading))
    }
}
