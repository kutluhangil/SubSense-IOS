import SwiftUI
import AuthenticationServices

struct SignInView: View {
    var switchToSignUp: (() -> Void)? = nil

    @Environment(AuthStore.self) private var authStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showForgotPassword = false
    @State private var successTrigger = false

    // Focus management
    @FocusState private var focusedField: Field?
    private enum Field { case email, password }

    // Entrance animation
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 32

    // Per-field focus highlight
    @State private var emailFocused = false
    @State private var passwordFocused = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                // Ambient background orb
                Circle()
                    .fill(.brand.opacity(0.07))
                    .frame(width: 320, height: 320)
                    .offset(x: 110, y: -220)
                    .blur(radius: 70)

                Circle()
                    .fill(.brandDeep.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .offset(x: -120, y: 300)
                    .blur(radius: 50)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.xl2) {

                        // MARK: Header
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            // Logo mark
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

                            Text(String(localized: "auth.signIn.title"))
                                .font(.display)
                                .foregroundStyle(.appTextPrimary)

                            Text(String(localized: "auth.signIn.subtitle"))
                                .font(.appBody)
                                .foregroundStyle(.appTextMuted)
                        }
                        .padding(.top, AppSpacing.xl3)

                        // MARK: Form Fields
                        VStack(spacing: AppSpacing.md) {
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

                            // Password
                            formFieldWrapper(
                                label: String(localized: "auth.password"),
                                isFocused: passwordFocused
                            ) {
                                HStack(spacing: AppSpacing.sm) {
                                    Group {
                                        if showPassword {
                                            TextField(String(localized: "auth.passwordPlaceholder"), text: $password)
                                        } else {
                                            SecureField(String(localized: "auth.passwordPlaceholder"), text: $password)
                                        }
                                    }
                                    .textContentType(.password)
                                    .font(.appBody)
                                    .foregroundStyle(.appTextPrimary)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        guard !email.isEmpty && !password.isEmpty else { return }
                                        Task { await signIn() }
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
                        VStack(spacing: AppSpacing.md) {
                            PrimaryButton(
                                title: String(localized: "auth.signInButton"),
                                isLoading: isLoading,
                                isDisabled: email.isEmpty || password.isEmpty
                            ) {
                                focusedField = nil
                                Task { await signIn() }
                            }
                            .sensoryFeedback(.success, trigger: successTrigger)

                            Button {
                                showForgotPassword = true
                            } label: {
                                Text(String(localized: "auth.forgotPassword"))
                                    .font(.appCallout)
                                    .foregroundStyle(.brand)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }

                        // MARK: Divider
                        dividerRow

                        // MARK: Apple Sign In
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            Task { await handleAppleSignIn(result) }
                        }
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))

                        // MARK: Switch to Sign Up
                        if let switchToSignUp {
                            HStack(spacing: AppSpacing.xs) {
                                Text(String(localized: "auth.noAccount"))
                                    .font(.appCallout)
                                    .foregroundStyle(.appTextMuted)
                                Button(String(localized: "auth.switchToSignUp")) {
                                    switchToSignUp()
                                }
                                .font(.appCallout.weight(.semibold))
                                .foregroundStyle(.brand)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
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
            .sheet(isPresented: $showForgotPassword) {
                ResetPasswordView()
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Subviews

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

    // MARK: - Actions

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authStore.signIn(email: email, password: password)
            successTrigger.toggle()
        } catch {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
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
            // ASAuthorizationError.canceled is not an error worth surfacing
            let asError = error as? ASAuthorizationError
            guard asError?.code != .canceled else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                errorMessage = error.localizedDescription
            }
        }
    }
}
