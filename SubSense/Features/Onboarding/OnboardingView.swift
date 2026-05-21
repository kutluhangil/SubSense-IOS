import SwiftUI

// MARK: - Logo data

private struct LogoItem {
    let asset: String
}

private let marqueeRow1: [LogoItem] = [
    LogoItem(asset: "Netflix"),
    LogoItem(asset: "spotify"),
    LogoItem(asset: "disney"),
    LogoItem(asset: "apple_tv_plus"),
    LogoItem(asset: "apple_music"),
    LogoItem(asset: "YouTube_Premium_logo"),
    LogoItem(asset: "amazon_prime"),
    LogoItem(asset: "HBO_Max_2025"),
    LogoItem(asset: "Paramount_Plus"),
    LogoItem(asset: "Hulu_logo_2018"),
]

private let marqueeRow2: [LogoItem] = [
    LogoItem(asset: "ChatGPT_Logo"),
    LogoItem(asset: "Adobe_Creative_Cloud_rainbow_icon"),
    LogoItem(asset: "Microsoft_365"),
    LogoItem(asset: "Notion_logo"),
    LogoItem(asset: "Figma_logo"),
    LogoItem(asset: "Slack_Technologies_Logo"),
    LogoItem(asset: "canva_seeklogo"),
    LogoItem(asset: "Zoom_Communications_Logo"),
    LogoItem(asset: "Claude_AI_logo"),
    LogoItem(asset: "discord"),
]

private let marqueeRow3: [LogoItem] = [
    LogoItem(asset: "twitch"),
    LogoItem(asset: "duolingo"),
    LogoItem(asset: "Dropbox_logo_2017"),
    LogoItem(asset: "Crunchyroll_Logo"),
    LogoItem(asset: "deezer"),
    LogoItem(asset: "audible"),
    LogoItem(asset: "Tidal_service_logo_only"),
    LogoItem(asset: "Grammarly_logo"),
    LogoItem(asset: "Perplexity_AI_logo"),
    LogoItem(asset: "amazon_music"),
]

// MARK: - Logo card

private struct LogoCard: View {
    let asset: String
    var size: CGFloat = 72

    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.white)
            .overlay {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .padding(11)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 6)
            .frame(width: size, height: size)
    }
}

// MARK: - Marquee row

private struct MarqueeRow: View {
    let logos: [LogoItem]
    let speed: Double
    let reversed: Bool

    private let cardSize: CGFloat = 72
    private let cardGap: CGFloat  = 14

    private var rowWidth: CGFloat {
        CGFloat(logos.count) * (cardSize + cardGap)
    }

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let scrolled = CGFloat(t * speed).truncatingRemainder(dividingBy: rowWidth)
            let xOff = reversed ? (scrolled - rowWidth) : -scrolled

            HStack(spacing: cardGap) {
                rowCards
                rowCards
            }
            .offset(x: xOff)
        }
        .frame(maxWidth: .infinity, minHeight: cardSize, maxHeight: cardSize)
        .clipped()
    }

    private var rowCards: some View {
        HStack(spacing: cardGap) {
            ForEach(logos.indices, id: \.self) { idx in
                LogoCard(asset: logos[idx].asset)
            }
        }
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSignIn  = false
    @State private var showSignUp  = false

    @State private var marqueeFade:   Double = 0
    @State private var badgeVisible  = false
    @State private var heroVisible   = false
    @State private var buttonsVisible = false
    @State private var glowPulsing   = false

    var body: some View {
        ZStack {
            backgroundLayer

            // ── Marquee logo section ──────────────────────────────────
            VStack(spacing: 0) {
                Color.clear.frame(height: 10)   // peek behind Dynamic Island

                VStack(spacing: 18) {
                    MarqueeRow(logos: marqueeRow1, speed: 38, reversed: false)
                    MarqueeRow(logos: marqueeRow2, speed: 29, reversed: true)
                    MarqueeRow(logos: marqueeRow3, speed: 47, reversed: false)
                }
                .rotation3DEffect(
                    Angle(degrees: -9),
                    axis: (x: 1.0, y: 0.0, z: 0.0),
                    perspective: 0.45
                )

                Spacer()
            }
            .opacity(marqueeFade)

            // ── Gradient fade: logos bleed into content area ──────────
            LinearGradient(
                stops: [
                    .init(color: .clear,                  location: 0.00),
                    .init(color: .clear,                  location: 0.25),
                    .init(color: Color.appBackground.opacity(0.6), location: 0.45),
                    .init(color: Color.appBackground,     location: 0.62),
                    .init(color: Color.appBackground,     location: 1.00),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // ── Hero content ──────────────────────────────────────────
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
            // Deep dark base
            LinearGradient(
                colors: [Color(hex: "#05051A"), Color.appBackground],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.68)
            )
            .ignoresSafeArea()

            // Brand purple — top center
            RadialGradient(
                colors: [Color.brand.opacity(0.32), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 280
            )
            .frame(width: 560, height: 560)
            .offset(y: -230)

            // Indigo — upper right
            RadialGradient(
                colors: [Color(hex: "#818CF8").opacity(0.15), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
            .frame(width: 400, height: 400)
            .offset(x: 150, y: -110)

            // Teal — upper left
            RadialGradient(
                colors: [Color(hex: "#22D3EE").opacity(0.08), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 180
            )
            .frame(width: 360, height: 360)
            .offset(x: -155, y: -55)
        }
    }

    // MARK: - Hero content

    private var heroContent: some View {
        VStack(spacing: 0) {
            Spacer()

            // App badge with pulsing glow
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.brand, Color.brandDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: Color.brand.opacity(glowPulsing ? 0.72 : 0.22),
                        radius: glowPulsing ? 32 : 10,
                        x: 0, y: 10
                    )
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: glowPulsing
                    )

                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 34, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
            .scaleEffect(badgeVisible ? 1.0 : 0.4)
            .opacity(badgeVisible ? 1.0 : 0.0)
            .padding(.bottom, AppSpacing.xl)

            // Headline + subtitle
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
        withAnimation(.easeOut(duration: 0.9).delay(0.05)) {
            marqueeFade = 1.0
        }
        withAnimation(.spring(response: 0.65, dampingFraction: 0.7, blendDuration: 0).delay(0.55)) {
            badgeVisible = true
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8, blendDuration: 0).delay(0.75)) {
            heroVisible = true
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8, blendDuration: 0).delay(0.95)) {
            buttonsVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            glowPulsing = true
        }
    }
}
