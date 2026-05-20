import SwiftUI

struct OnboardingView: View {
    @State private var vm = OnboardingViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSignIn = false
    @State private var showSignUp = false

    // Animation states
    @State private var symbolScale: CGFloat = 0.5
    @State private var symbolOpacity: Double = 0
    @State private var textOffset: CGFloat = 40
    @State private var textOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 60
    @State private var buttonsOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.3
    @State private var glowOpacity: Double = 0
    @State private var floatOffset: CGFloat = 0

    private var currentPage: OnboardingPage { vm.pages[vm.currentPage] }
    private var pageColor: Color { Color(hex: currentPage.accentColor) }

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 0) {
                Spacer()

                heroSymbolView
                    .padding(.bottom, AppSpacing.xl3)

                pageTextView
                    .padding(.horizontal, AppSpacing.xl2)

                Spacer()

                pageIndicatorView
                    .padding(.bottom, AppSpacing.xl)

                if vm.isLastPage {
                    lastPageButtons
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.xl4)
                } else {
                    continueButton
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.xl4)
                }
            }
        }
        .onAppear { animateIn() }
        .onChange(of: vm.currentPage) { _, _ in animatePageChange() }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // Primary ambient glow — tracks page accent colour
            Circle()
                .fill(
                    RadialGradient(
                        colors: [pageColor.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 520, height: 520)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)
                .offset(y: -80)
                .animation(Animation.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0), value: glowScale)
                .animation(Animation.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0), value: glowOpacity)
                .animation(Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: pageColor)

            // Top-right decorative orb
            Circle()
                .fill(pageColor.opacity(0.06))
                .frame(width: 220, height: 220)
                .offset(x: 130, y: -360)
                .blur(radius: 50)
                .animation(Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: pageColor)

            // Bottom-left decorative orb
            Circle()
                .fill(Color.brand.opacity(0.07))
                .frame(width: 180, height: 180)
                .offset(x: -140, y: 320)
                .blur(radius: 36)
        }
    }

    // MARK: - Hero Symbol

    private var heroSymbolView: some View {
        ZStack {
            // Diffuse outer glow
            Circle()
                .fill(pageColor.opacity(0.10))
                .frame(width: 210, height: 210)
                .blur(radius: 28)
                .scaleEffect(glowScale)
                .animation(Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: pageColor)

            // Glass card
            RoundedRectangle(cornerRadius: AppRadius.card * 2)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.card * 2)
                        .strokeBorder(
                            LinearGradient(
                                colors: [pageColor.opacity(0.35), pageColor.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .frame(width: 124, height: 124)
                .shadow(color: pageColor.opacity(0.28), radius: 32, x: 0, y: 12)
                .animation(Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: pageColor)

            Image(systemName: currentPage.symbol)
                .font(.system(size: 54, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(pageColor)
                .symbolEffect(.pulse, options: .repeating.speed(0.4))
                .animation(Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: currentPage.symbol)
                .animation(Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: pageColor)
        }
        .scaleEffect(symbolScale)
        .opacity(symbolOpacity)
        .offset(y: floatOffset)
    }

    // MARK: - Page Text

    private var pageTextView: some View {
        VStack(spacing: AppSpacing.md) {
            Text(currentPage.title)
                .font(.display)
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)
                .offset(y: textOffset)
                .opacity(textOpacity)

            Text(currentPage.subtitle)
                .font(.appBody)
                .foregroundStyle(Color.appTextMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .offset(y: textOffset + 10)
                .opacity(textOpacity)
        }
    }

    // MARK: - Page Indicator

    private var pageIndicatorView: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<vm.pages.count, id: \.self) { idx in
                Capsule()
                    .fill(idx == vm.currentPage ? pageColor : pageColor.opacity(0.2))
                    .frame(width: idx == vm.currentPage ? 26 : 8, height: 8)
                    .animation(Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: vm.currentPage)
                    .animation(Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: pageColor)
            }
        }
    }

    // MARK: - Buttons

    private var continueButton: some View {
        PrimaryButton(title: String(localized: "onboarding.continueButton")) {
            vm.nextPage()
        }
        .offset(y: buttonsOffset)
        .opacity(buttonsOpacity)
    }

    private var lastPageButtons: some View {
        VStack(spacing: AppSpacing.md) {
            PrimaryButton(title: String(localized: "auth.continueWithApple")) {
                showSignUp = true
            }

            SecondaryButton(title: String(localized: "auth.switchToSignIn")) {
                showSignIn = true
            }

            Button {
                withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                    hasSeenOnboarding = true
                }
            } label: {
                Text(String(localized: "onboarding.skip"))
                    .font(.appFootnote)
                    .foregroundStyle(Color.appTextMuted)
                    .padding(.vertical, AppSpacing.sm)
            }
        }
        .offset(y: buttonsOffset)
        .opacity(buttonsOpacity)
    }

    // MARK: - Animations

    private func animateIn() {
        withAnimation(.spring(response: 0.65, dampingFraction: 0.7, blendDuration: 0).delay(0.1)) {
            symbolScale = 1.0
            symbolOpacity = 1.0
            glowScale = 1.0
            glowOpacity = 1.0
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8, blendDuration: 0).delay(0.25)) {
            textOffset = 0
            textOpacity = 1.0
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8, blendDuration: 0).delay(0.42)) {
            buttonsOffset = 0
            buttonsOpacity = 1.0
        }

        // Kick off gentle floating loop after the entrance settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(Animation.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                floatOffset = -10
            }
        }
    }

    private func animatePageChange() {
        // Quick scale-down and fade on exit
        withAnimation(Animation.spring(response: 0.3, dampingFraction: 0.9, blendDuration: 0)) {
            symbolScale = 0.75
            symbolOpacity = 0.4
            textOffset = 18
            textOpacity = 0.2
        }

        // Spring back in on the new page
        withAnimation(.spring(response: 0.5, dampingFraction: 0.72, blendDuration: 0).delay(0.1)) {
            symbolScale = 1.0
            symbolOpacity = 1.0
            textOffset = 0
            textOpacity = 1.0
        }
    }
}
