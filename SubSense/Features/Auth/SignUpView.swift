import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    var switchToSignIn: (() -> Void)? = nil

    @Environment(AuthStore.self) private var authStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showVerifyEmail = false
    @State private var successTrigger = false

    // Focus management
    @FocusState private var focusedField: Field?
    private enum Field { case name, email, password }

    // Per-field focus highlight
    @State private var nameFocused = false
    @State private var emailFocused = false
    @State private var passwordFocused = false

    // Entrance animation
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 32

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                // Ambient orbs
                Circle()
                    .fill(.accent.opacity(0.07))
                    .frame(width: 300, height: 300)
                    .offset(x: -110, y: -220)
                    .blur(radius: 70)

                Circle()
                    .fill(.brand.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .offset(x: 130, y: 320)
                    .blur(radius: 50)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.xl2) {

                        // MARK: Header
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppRadius.icon)
                                    .fill(
                                        LinearGradient(
                                            colors: [.brand, .brandDeep],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .brand.opacity(0.35), radius: 10, x: 0, y: 4)

                                Image(systemName: "creditcard.and.123")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            .padding(.bottom, AppSpacing.sm)

                            Text(String(localized: "auth.signUp.title"))
                                .font(.display)
                                .foregroundStyle(.appTextPrimary)

                            Text(String(localized: "auth.signUp.subtitle"))
                                .font(.appBody)
                                .foregroundStyle(.appTextMuted)
                        }
                        .padding(.top, AppSpacing.xl3)

                        // MARK: Form Fields
                        VStack(spacing: AppSpacing.md) {

                            // Display Name
                            formFieldWrapper(
                                label: String(localized: "auth.displayName"),
                                isFocused: nameFocused
                            ) {
                                TextField(String(localized: "auth.displayNamePlaceholder"), text: $displayName)
                                    .textContentType(.name)
                                    .font(.appBody)
                                    .foregroundStyle(.appTextPrimary)
                                    .focused($focusedField, equals: .name)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .email }
                                    .onChange(of: focusedField) { _, new in
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            nameFocused = new == .name
                                        }
                                    }
                            }

                            // Email
                            formFieldWrapper(
                                label: String(localized: "auth.email"),
                                isFocused: emailFocused
                            ) {
                                TextField(String(localized: "auth.emailPlaceholder"), text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.appBody)
                                    .foregroundStyle(.appTextPrimary)
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .password }
                                    .onChange(of: focusedField) { _, new in
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            emailFocused = new == .email
                                        }
                                    }
                            }

                            // Password + strength meter
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(String(localized: "auth.password"))
                                    .font(.appCaption)
                                    .foregroundStyle(.appTextMuted)
                                    .tracking(0.6)
                                    .textCase(.uppercase)

                                HStack(spacing: AppSpacing.sm) {
                                    Group {
                                        if showPassword {
                                            TextField(String(localized: "auth.passwordNewPlaceholder"), text: $password)
                                        } else {
                                            SecureField(String(localized: "auth.passwordNewPlaceholder"), text: $password)
                                        }
                                    }
                                    .textContentType(.newPassword)
                                    .font(.appBody)
                                    .foregroundStyle(.appTextPrimary)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        guard isFormValid else { return }
                                        focusedField = nil
                                        Task { await signUp() }
                                    }
                                    .onChange(of: focusedField) { _, new in
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            passwordFocused = new == .password
                                        }
                                    }

                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            showPassword.toggle()
                                        }
                                    } label: {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .font(.system(size: 16, weight: .light))
                                            .foregroundStyle(.appTextMuted)
                                            .frame(width: 24, height: 24)
                                            .contentTransition(.symbolEffect(.replace))
                                    }
                                }
                                .padding(AppSpacing.base)
                                .background {
                                    RoundedRectangle(cornerRadius: AppRadius.button)
                                        .fill(Color.appSurface)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: AppRadius.button)
                                                .strokeBorder(
                                                    passwordFocused ? Color.brand.opacity(0.6) : Color.appBorder,
                                                    lineWidth: passwordFocused ? 1.5 : 1
                                                )
                                        }
                                        .shadow(
                                            color: passwordFocused ? Color.brand.opacity(0.12) : .clear,
                                            radius: 8, x: 0, y: 2
                                        )
                                }

                                if !password.isEmpty {
                                    passwordStrengthView
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                        }

                        // MARK: Error Banner
                        if let error = errorMessage {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.appDanger)
                                    .font(.system(size: 15))
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
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // MARK: Primary Action
                        PrimaryButton(
                            title: String(localized: "auth.signUpButton"),
                            isLoading: isLoading,
                            isDisabled: !isFormValid
                        ) {
                            focusedField = nil
                            Task { await signUp() }
                        }
                        .sensoryFeedback(.success, trigger: successTrigger)

                        // MARK: Divider
                        dividerRow

                        // MARK: Apple Sign Up
                        SignInWithAppleButton(.signUp) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            Task { await handleAppleSignUp(result) }
                        }
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))

                        // MARK: Switch to Sign In
                        if let switchToSignIn {
                            HStack(spacing: AppSpacing.xs) {
                                Text(String(localized: "auth.hasAccount"))
                                    .font(.appCallout)
                                    .foregroundStyle(.appTextMuted)
                                Button(String(localized: "auth.switchToSignIn")) {
                                    switchToSignIn()
                                }
                                .font(.appCallout.weight(.semibold))
                                .foregroundStyle(.brand)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }

                        // MARK: Legal
                        Text(String(localized: "auth.termsAgreement"))
                            .font(.appCaption)
                            .foregroundStyle(.appTextMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xl3)
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
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: errorMessage)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: password)
            .fullScreenCover(isPresented: $showVerifyEmail) {
                VerifyEmailView(email: email)
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Computed

    private var isFormValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.isEmpty &&
        password.count >= 8
    }

    // MARK: - Subviews

    @ViewBuilder
    private func formFieldWrapper<Content: View>(
        label: String,
        isFocused: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(.appCaption)
                .foregroundStyle(.appTextMuted)
                .tracking(0.6)
                .textCase(.uppercase)

            content()
                .padding(AppSpacing.base)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.button)
                        .fill(Color.appSurface)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.button)
                                .strokeBorder(
                                    isFocused ? Color.brand.opacity(0.6) : Color.appBorder,
                                    lineWidth: isFocused ? 1.5 : 1
                                )
                        }
                        .shadow(
                            color: isFocused ? Color.brand.opacity(0.12) : .clear,
                            radius: 8, x: 0, y: 2
                        )
                }
        }
    }

    private var dividerRow: some View {
        HStack(spacing: AppSpacing.md) {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.appBorder)
            Text(String(localized: "general.or"))
                .font(.appFootnote)
                .foregroundStyle(.appTextMuted)
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.appBorder)
        }
    }

    private var passwordStrengthView: some View {
        let strength = passwordStrength(password)
        return HStack(spacing: AppSpacing.xs) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < strength.bars ? strength.color : Color.appSurfaceAlt)
                    .frame(height: 3)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: strength.bars)
            }
            Text(strength.label)
                .font(.appCaption)
                .foregroundStyle(strength.color)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: strength.label)
        }
    }

    // MARK: - Password Strength

    private struct PasswordStrength {
        let bars: Int
        let color: Color
        let label: String
    }

    private func passwordStrength(_ pwd: String) -> PasswordStrength {
        var score = 0
        if pwd.count >= 8  { score += 1 }
        if pwd.count >= 12 { score += 1 }
        if pwd.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if pwd.range(of: "[0-9!@#$%^&*]", options: .regularExpression) != nil { score += 1 }
        switch score {
        case 0...1: return PasswordStrength(bars: 1, color: .appDanger,  label: String(localized: "auth.passwordStrength.weak"))
        case 2:     return PasswordStrength(bars: 2, color: .appWarning, label: String(localized: "auth.passwordStrength.fair"))
        case 3:     return PasswordStrength(bars: 3, color: .appInfo,    label: String(localized: "auth.passwordStrength.good"))
        default:    return PasswordStrength(bars: 4, color: .appSuccess, label: String(localized: "auth.passwordStrength.strong"))
        }
    }

    // MARK: - Actions

    private func signUp() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authStore.signUp(
                email: email,
                password: password,
                displayName: displayName.trimmingCharacters(in: .whitespaces)
            )
            successTrigger.toggle()
            showVerifyEmail = true
        } catch {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    private func handleAppleSignUp(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let token = String(data: tokenData, encoding: .utf8)
            else { return }

            isLoading = true
            errorMessage = nil
            do {
                try await authStore.signInWithApple(idToken: token, nonce: "")
                successTrigger.toggle()
            } catch {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    errorMessage = error.localizedDescription
                }
            }
            isLoading = false

        case .failure(let error):
            let asError = error as? ASAuthorizationError
            guard asError?.code != .canceled else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                errorMessage = error.localizedDescription
            }
        }
    }
}
