import SwiftUI

struct ResetPasswordView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isLoading = false
    @State private var sent = false
    @State private var error: String?
    @State private var successTrigger = false

    // Focus state
    @FocusState private var isEmailFocused: Bool
    @State private var emailFocusHighlight = false

    // Entrance animation
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 24

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                // Ambient orb
                Circle()
                    .fill(.brand.opacity(0.07))
                    .frame(width: 280, height: 280)
                    .offset(x: 80, y: -160)
                    .blur(radius: 70)

                VStack(spacing: AppSpacing.xl2) {
                    // MARK: Icon
                    ZStack {
                        Circle()
                            .fill(.brand.opacity(0.08))
                            .frame(width: 104, height: 104)
                            .blur(radius: 16)

                        RoundedRectangle(cornerRadius: AppRadius.card * 1.5)
                            .fill(.regularMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.card * 1.5)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                sent ? Color.appSuccess.opacity(0.3) : Color.brand.opacity(0.25),
                                                sent ? Color.appSuccess.opacity(0.08) : Color.brand.opacity(0.08)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                            .frame(width: 84, height: 84)
                            .shadow(
                                color: sent ? Color.appSuccess.opacity(0.2) : Color.brand.opacity(0.18),
                                radius: 18, x: 0, y: 6
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sent)

                        Image(systemName: sent ? "checkmark.circle.fill" : "lock.rotation")
                            .font(.system(size: 38, weight: .thin))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(sent ? .appSuccess : .brand)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .padding(.top, AppSpacing.xl3)

                    // MARK: Copy
                    VStack(spacing: AppSpacing.md) {
                        Text(sent
                             ? String(localized: "auth.resetSent.title")
                             : String(localized: "auth.resetPassword.title"))
                            .font(.appTitle)
                            .foregroundStyle(.appTextPrimary)
                            .multilineTextAlignment(.center)
                            .contentTransition(.opacity)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sent)

                        Text(sent
                             ? String(localized: "auth.resetSent.body")
                             : String(localized: "auth.resetPassword.body"))
                            .font(.appBody)
                            .foregroundStyle(.appTextMuted)
                            .multilineTextAlignment(.center)
                            .contentTransition(.opacity)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sent)
                    }
                    .padding(.horizontal, AppSpacing.xl)

                    // MARK: Email Input (pre-send only)
                    if !sent {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(String(localized: "auth.email"))
                                .font(.appCaption)
                                .foregroundStyle(.appTextMuted)
                                .tracking(0.6)
                                .textCase(.uppercase)

                            TextField(String(localized: "auth.emailPlaceholder"), text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.appBody)
                                .foregroundStyle(.appTextPrimary)
                                .focused($isEmailFocused)
                                .submitLabel(.send)
                                .onSubmit {
                                    guard !email.isEmpty else { return }
                                    Task { await sendReset() }
                                }
                                .onChange(of: isEmailFocused) { _, focused in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        emailFocusHighlight = focused
                                    }
                                }
                                .padding(AppSpacing.base)
                                .background {
                                    RoundedRectangle(cornerRadius: AppRadius.button)
                                        .fill(Color.appSurface)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: AppRadius.button)
                                                .strokeBorder(
                                                    emailFocusHighlight ? Color.brand.opacity(0.6) : Color.appBorder,
                                                    lineWidth: emailFocusHighlight ? 1.5 : 1
                                                )
                                        }
                                        .shadow(
                                            color: emailFocusHighlight ? Color.brand.opacity(0.12) : .clear,
                                            radius: 8, x: 0, y: 2
                                        )
                                }
                        }
                        .padding(.horizontal, AppSpacing.xl)
                        .transition(.move(edge: .top).combined(with: .opacity))

                        // Inline error
                        if let error {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.appDanger)
                                    .font(.system(size: 14))
                                Text(error)
                                    .font(.appFootnote)
                                    .foregroundStyle(.appDanger)
                                    .fixedSize(horizontal: false, vertical: true)
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
                    }

                    // MARK: Action Button
                    if sent {
                        PrimaryButton(title: String(localized: "general.done")) {
                            dismiss()
                        }
                        .padding(.horizontal, AppSpacing.xl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        PrimaryButton(
                            title: String(localized: "auth.sendResetLink"),
                            isLoading: isLoading,
                            isDisabled: email.isEmpty
                        ) {
                            isEmailFocused = false
                            Task { await sendReset() }
                        }
                        .sensoryFeedback(.success, trigger: successTrigger)
                        .padding(.horizontal, AppSpacing.xl)
                    }

                    Spacer()
                }
            }
            .opacity(contentOpacity)
            .offset(y: contentOffset)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) {
                    contentOpacity = 1
                    contentOffset = 0
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sent)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: error)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.cancel")) { dismiss() }
                        .foregroundStyle(.brand)
                }
            }
        }
    }

    // MARK: - Actions

    private func sendReset() async {
        isLoading = true
        error = nil
        do {
            try await authStore.resetPassword(email: email)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                sent = true
            }
            successTrigger.toggle()
        } catch {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.error = error.localizedDescription
            }
        }
        isLoading = false
    }
}
