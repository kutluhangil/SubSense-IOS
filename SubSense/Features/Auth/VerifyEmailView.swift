import SwiftUI

struct VerifyEmailView: View {
    let email: String

    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss

    @State private var isRefreshing = false
    @State private var isResending = false
    @State private var resendCooldown = 0
    @State private var resendTimer: Timer?
    @State private var showError = false
    @State private var errorMessage = ""

    // Entrance animations
    @State private var envelopeScale: CGFloat = 0.5
    @State private var envelopeOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0

    // Repeating pulse
    @State private var pulseScale: CGFloat = 1.0

    // Success haptic
    @State private var successTrigger = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // Ambient glow behind icon
            Circle()
                .fill(.brand.opacity(0.07))
                .frame(width: 280, height: 280)
                .offset(y: -120)
                .blur(radius: 60)

            VStack(spacing: AppSpacing.xl3) {
                Spacer()

                // MARK: Animated Envelope
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .fill(.brand.opacity(0.09))
                        .frame(width: 148, height: 148)
                        .scaleEffect(pulseScale)

                    // Glass card
                    RoundedRectangle(cornerRadius: AppRadius.card * 2)
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.card * 2)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.brand.opacity(0.25), .brand.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .frame(width: 104, height: 104)
                        .shadow(color: .brand.opacity(0.22), radius: 24, x: 0, y: 10)

                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 46, weight: .thin))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.brand)
                }
                .scaleEffect(envelopeScale)
                .opacity(envelopeOpacity)

                // MARK: Text Content
                VStack(spacing: AppSpacing.md) {
                    Text(String(localized: "auth.verifyEmail.title"))
                        .font(.appTitle)
                        .foregroundStyle(.appTextPrimary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: AppSpacing.sm) {
                        Text(String(localized: "auth.verifyEmail.body"))
                            .font(.appBody)
                            .foregroundStyle(.appTextMuted)
                            .multilineTextAlignment(.center)

                        Text(email)
                            .font(.appBody.weight(.semibold))
                            .foregroundStyle(.brand)
                    }

                    Text(String(localized: "auth.verifyEmail.instruction"))
                        .font(.appFootnote)
                        .foregroundStyle(.appTextMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.base)
                }
                .opacity(contentOpacity)
                .padding(.horizontal, AppSpacing.xl)

                // MARK: Error Banner
                if showError {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.appDanger)
                        Text(errorMessage)
                            .font(.appFootnote)
                            .foregroundStyle(.appDanger)
                        Spacer()
                    }
                    .padding(AppSpacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.icon)
                            .fill(Color.appDanger.opacity(0.08))
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.icon)
                                    .strokeBorder(Color.appDanger.opacity(0.18), lineWidth: 1)
                            }
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // MARK: Action Buttons
                VStack(spacing: AppSpacing.md) {
                    PrimaryButton(
                        title: String(localized: "auth.verifyEmail.refresh"),
                        isLoading: isRefreshing
                    ) {
                        Task { await refreshSession() }
                    }
                    .sensoryFeedback(.success, trigger: successTrigger)

                    SecondaryButton(
                        title: resendCooldown > 0
                            ? String(format: String(localized: "auth.resendIn"), resendCooldown)
                            : String(localized: "auth.resendEmail"),
                        isLoading: isResending
                    ) {
                        guard resendCooldown == 0 else { return }
                        Task { await resendEmail() }
                    }

                    Button {
                        Task {
                            try? await authStore.signOut()
                            dismiss()
                        }
                    } label: {
                        Text(String(localized: "auth.useDifferentAccount"))
                            .font(.appFootnote)
                            .foregroundStyle(.appTextMuted)
                            .padding(.vertical, AppSpacing.sm)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .opacity(buttonsOpacity)

                Spacer()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showError)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: resendCooldown)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.1)) {
                envelopeScale = 1
                envelopeOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.38)) {
                contentOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.52)) {
                buttonsOpacity = 1
            }
            // Start pulse loop after entrance settles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                withAnimation(Animation.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                    pulseScale = 1.16
                }
            }
        }
        .onDisappear {
            resendTimer?.invalidate()
        }
    }

    // MARK: - Actions

    private func refreshSession() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            try await AuthService().refreshSession()
            // AuthStore observes auth state changes; if verified, it will flip isAuthenticated
            successTrigger.toggle()
        } catch {
            // Silently ignore — user may not have verified yet
        }
    }

    private func resendEmail() async {
        isResending = true
        defer { isResending = false }
        do {
            try await AuthService().resendVerificationEmail(email: email)
            startResendCooldown()
        } catch {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func startResendCooldown() {
        resendCooldown = 60
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                timer.invalidate()
                resendTimer = nil
            }
        }
    }
}
