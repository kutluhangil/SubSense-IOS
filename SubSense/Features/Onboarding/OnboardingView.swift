import SwiftUI

// MARK: - Subscription logo data

private struct SubscriptionLogo {
    let label: String
    let color: Color
    let xOffset: CGFloat
    let yOffset: CGFloat
    let phaseShift: Double
    let fontSize: CGFloat

    static let all: [SubscriptionLogo] = [
        // Row 1 — top
        SubscriptionLogo(label: "N",     color: Color(hex: "#E50914"), xOffset: -130, yOffset: -135, phaseShift: 0.00, fontSize: 24),
        SubscriptionLogo(label: "♪",     color: Color(hex: "#1DB954"), xOffset:    0, yOffset: -158, phaseShift: 0.70, fontSize: 22),
        SubscriptionLogo(label: "D+",    color: Color(hex: "#113CCF"), xOffset:  130, yOffset: -135, phaseShift: 1.40, fontSize: 18),
        // Row 2
        SubscriptionLogo(label: "TV+",   color: Color(hex: "#4A4A4A"), xOffset: -158, yOffset:  -58, phaseShift: 2.10, fontSize: 14),
        SubscriptionLogo(label: "▶",     color: Color(hex: "#FF0000"), xOffset:  -56, yOffset:  -72, phaseShift: 0.30, fontSize: 22),
        SubscriptionLogo(label: "max",   color: Color(hex: "#5822B4"), xOffset:   56, yOffset:  -72, phaseShift: 1.10, fontSize: 15),
        SubscriptionLogo(label: "prime", color: Color(hex: "#00A8E1"), xOffset:  158, yOffset:  -58, phaseShift: 1.80, fontSize: 12),
        // Row 3 — middle
        SubscriptionLogo(label: "hulu",  color: Color(hex: "#1CE783"), xOffset: -122, yOffset:   18, phaseShift: 2.50, fontSize: 13),
        SubscriptionLogo(label: "☁",     color: Color(hex: "#3693F3"), xOffset:    0, yOffset:    8, phaseShift: 0.50, fontSize: 22),
        SubscriptionLogo(label: "AI",    color: Color(hex: "#10A37F"), xOffset:  122, yOffset:   18, phaseShift: 1.50, fontSize: 17),
        // Row 4 — lower
        SubscriptionLogo(label: "Cc",    color: Color(hex: "#DA3025"), xOffset:  -92, yOffset:   95, phaseShift: 3.00, fontSize: 17),
        SubscriptionLogo(label: "G·",    color: Color(hex: "#4285F4"), xOffset:   18, yOffset:   92, phaseShift: 2.20, fontSize: 18),
        SubscriptionLogo(label: "X",     color: Color(hex: "#107C10"), xOffset:  135, yOffset:   92, phaseShift: 0.90, fontSize: 22),
    ]
}

// MARK: - Logo tile

private struct LogoTile: View {
    let logo: SubscriptionLogo

    var body: some View {
        Text(logo.label)
            .font(.system(size: logo.fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 58, height: 58)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(logo.color)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    }
            }
            .shadow(color: logo.color.opacity(0.55), radius: 16, x: 0, y: 6)
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSignIn = false
    @State private var showSignUp = false

    @State private var logoVisible: [Bool] = Array(repeating: false, count: SubscriptionLogo.all.count)
    @State private var badgeVisible = false
    @State private var heroVisible = false
    @State private var buttonsVisible = false
    @State private var glowPulsing = false

    private let logos = SubscriptionLogo.all

    var body: some View {
        ZStack {
            backgroundLayer

            GeometryReader { geo in
                let cx = geo.size.width / 2
                let cy = geo.size.height * 0.37

                TimelineView(.animation) { context in
                    let t = context.date.timeIntervalSinceReferenceDate

                    ZStack {
                        ForEach(logos.indices, id: \.self) { idx in
                            let logo = logos[idx]
                            LogoTile(logo: logo)
                                .position(
                                    x: cx + logo.xOffset,
                                    y: cy + logo.yOffset + CGFloat(sin(t * 0.65 + logo.phaseShift)) * 9
                                )
                                .scaleEffect(logoVisible[idx] ? 1.0 : 0.25)
                                .opacity(logoVisible[idx] ? 1.0 : 0.0)
                                .animation(
                                    Animation.spring(response: 0.6, dampingFraction: 0.72, blendDuration: 0)
                                        .delay(Double(idx) * 0.07),
                                    value: logoVisible[idx]
                                )
                        }
                    }
                }
            }

            // Gradient fade — blends logo cloud into content area
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .clear, location: 0.36),
                    .init(color: Color.appBackground, location: 0.62),
                    .init(color: Color.appBackground, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Hero content pinned to bottom
            heroContent
        }
        .ignoresSafeArea()
        .onAppear { kickAnimations() }
        .sheet(isPresented: $showSignUp) { SignUpView() }
        .sheet(isPresented: $showSignIn) { SignInView() }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#07071A"), Color.appBackground],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.7)
            )
            .ignoresSafeArea()

            // Brand purple ambient glow — top center
            Circle()
                .fill(RadialGradient(
                    colors: [Color.brand.opacity(0.26), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 300
                ))
                .frame(width: 600, height: 600)
                .offset(y: -180)

            // Indigo secondary glow — top left
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "#818CF8").opacity(0.12), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                ))
                .frame(width: 400, height: 400)
                .offset(x: -130, y: -100)

            // Accent gold glow — right side
            Circle()
                .fill(RadialGradient(
                    colors: [Color.accent.opacity(0.09), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                ))
                .frame(width: 400, height: 400)
                .offset(x: 140, y: 60)
        }
    }

    // MARK: - Hero content

    private var heroContent: some View {
        VStack(spacing: 0) {
            Spacer()

            // App badge
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.brand, Color.brandDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 78, height: 78)
                    .shadow(
                        color: Color.brand.opacity(glowPulsing ? 0.7 : 0.25),
                        radius: glowPulsing ? 30 : 10,
                        x: 0,
                        y: 10
                    )
                    .animation(Animation.easeInOut(duration: 1.9).repeatForever(autoreverses: true), value: glowPulsing)

                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 34, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
            .scaleEffect(badgeVisible ? 1.0 : 0.4)
            .opacity(badgeVisible ? 1.0 : 0.0)
            .padding(.bottom, AppSpacing.xl)

            // Tagline
            let textWidth = UIScreen.main.bounds.width - AppSpacing.xl2 * 2
            VStack(spacing: AppSpacing.md) {
                Text(String(localized: "onboarding.landing.title"))
                    .font(.display)
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .frame(width: textWidth)

                Text(String(localized: "onboarding.landing.subtitle"))
                    .font(.appBody)
                    .foregroundStyle(Color.appTextMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(width: textWidth)
            }
            .offset(y: heroVisible ? 0 : 24)
            .opacity(heroVisible ? 1.0 : 0.0)
            .padding(.bottom, AppSpacing.xl2)

            // CTA buttons
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
            .padding(.horizontal, AppSpacing.xl)
            .offset(y: buttonsVisible ? 0 : 32)
            .opacity(buttonsVisible ? 1.0 : 0.0)
            .padding(.bottom, AppSpacing.xl4)
        }
    }

    // MARK: - Entrance animations

    private func kickAnimations() {
        let logoCount = logos.count

        for i in 0..<logoCount {
            withAnimation(
                Animation.spring(response: 0.6, dampingFraction: 0.72, blendDuration: 0)
                    .delay(Double(i) * 0.07 + 0.15)
            ) {
                logoVisible[i] = true
            }
        }

        let after = Double(logoCount) * 0.07 + 0.3

        withAnimation(.spring(response: 0.65, dampingFraction: 0.7, blendDuration: 0).delay(after)) {
            badgeVisible = true
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8, blendDuration: 0).delay(after + 0.18)) {
            heroVisible = true
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8, blendDuration: 0).delay(after + 0.36)) {
            buttonsVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + after + 0.5) {
            glowPulsing = true
        }
    }
}
