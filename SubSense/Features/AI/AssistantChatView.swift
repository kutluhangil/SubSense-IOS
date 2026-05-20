import SwiftUI

struct AssistantChatView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(SubscriptionRepository.self) private var repository
    @State private var profileRepo = ProfileRepository()
    @State private var messages: [AssistantService.ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var streamingContent = ""
    @FocusState private var inputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private let service = AssistantService()

    private var baseCurrency: String { profileRepo.profile?.baseCurrency ?? "USD" }
    private var language: String { profileRepo.profile?.preferredLanguage.rawValue ?? "en" }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: AppSpacing.md) {
                                welcomeHeader

                                ForEach(messages) { msg in
                                    MessageBubble(message: msg)
                                        .id(msg.id)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.9, anchor: msg.role == .user ? .bottomTrailing : .bottomLeading).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }

                                if isLoading && !streamingContent.isEmpty {
                                    StreamingBubble(content: streamingContent)
                                        .id("streaming")
                                }

                                if isLoading && streamingContent.isEmpty {
                                    TypingIndicator()
                                        .id("typing")
                                }

                                Spacer().frame(height: AppSpacing.xl4)
                            }
                            .padding(.horizontal, AppSpacing.base)
                            .padding(.top, AppSpacing.md)
                        }
                        .onChange(of: messages.count) {
                            withAnimation {
                                proxy.scrollTo(messages.last?.id ?? "typing", anchor: .bottom)
                            }
                        }
                        .onChange(of: streamingContent) {
                            withAnimation {
                                proxy.scrollTo("streaming", anchor: .bottom)
                            }
                        }
                    }

                    // Suggestion chips
                    if messages.isEmpty {
                        suggestionChips
                    }

                    // Input bar
                    inputBar
                }
            }
            .navigationTitle(String(localized: "ai.assistant.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.close")) { dismiss() }
                        .foregroundStyle(.brand)
                }
            }
            .task {
                if let uid = authStore.userID {
                    try? await profileRepo.fetch(userId: uid)
                }
            }
        }
    }

    // MARK: - Welcome

    private var welcomeHeader: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.brand.opacity(0.15), .accent.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 72, height: 72)
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.accent)
                    .symbolEffect(.pulse, options: .repeating.speed(0.4))
            }
            Text(String(localized: "ai.assistant.welcome"))
                .font(.appTitle2)
                .foregroundStyle(.appTextPrimary)
            Text(String(localized: "ai.assistant.welcomeSubtitle"))
                .font(.appFootnote)
                .foregroundStyle(.appTextMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppSpacing.xl)
    }

    // MARK: - Suggestion chips

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        inputText = suggestion
                        sendMessage()
                    } label: {
                        Text(suggestion)
                            .font(.appFootnote.weight(.medium))
                            .foregroundStyle(.brand)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background {
                                Capsule()
                                    .fill(Color.brand.opacity(0.08))
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(Color.brand.opacity(0.15), lineWidth: 1)
                                    }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.base)
        }
        .padding(.bottom, AppSpacing.sm)
    }

    private var suggestions: [String] {
        language == "tr" ? [
            "Hangi aboneliklerim benzer?",
            "Bu ay ne kadar harcıyorum?",
            "Tasarruf önerilerin neler?",
        ] : [
            "Which subscriptions overlap?",
            "How much am I spending this month?",
            "What can I cancel to save money?",
        ]
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: AppSpacing.sm) {
            TextField(
                String(localized: "ai.assistant.inputPlaceholder"),
                text: $inputText,
                axis: .vertical
            )
            .lineLimit(1...4)
            .font(.appBody)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.button)
                    .fill(Color.appSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .strokeBorder(Color.appBorder, lineWidth: 1)
                    }
            }
            .focused($inputFocused)
            .onSubmit { sendMessage() }
            .disabled(isLoading)

            Button {
                sendMessage()
            } label: {
                ZStack {
                    Circle()
                        .fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
                            ? Color.appSurfaceAlt
                            : LinearGradient(colors: [.brand, .brandDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: isLoading ? "ellipsis" : "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
                                ? Color.appTextMuted
                                : .white
                        )
                        .symbolEffect(.bounce, options: .nonRepeating, value: isLoading)
                }
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: inputText.isEmpty)
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, AppSpacing.sm)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    // MARK: - Send

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let userMsg = AssistantService.ChatMessage(role: .user, content: text)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            messages.append(userMsg)
        }
        inputText = ""
        isLoading = true
        streamingContent = ""

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        Task {
            do {
                let stream = try await service.sendMessage(
                    text,
                    subscriptions: repository.subscriptions,
                    baseCurrency: baseCurrency,
                    language: language
                )
                for try await chunk in stream {
                    await MainActor.run {
                        streamingContent += chunk
                    }
                }
                let assistantMsg = AssistantService.ChatMessage(role: .assistant, content: streamingContent)
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        messages.append(assistantMsg)
                        streamingContent = ""
                        isLoading = false
                    }
                }
            } catch {
                let errorMsg = AssistantService.ChatMessage(role: .assistant, content: "Sorry, something went wrong. Please try again.")
                await MainActor.run {
                    withAnimation {
                        messages.append(errorMsg)
                        streamingContent = ""
                        isLoading = false
                    }
                }
            }
        }
    }
}

// MARK: - MessageBubble

private struct MessageBubble: View {
    let message: AssistantService.ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.brand, .brandDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            Text(message.content)
                .font(.appBody)
                .foregroundStyle(isUser ? .white : .appTextPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isUser
                            ? LinearGradient(colors: [.brand, .brandDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : Color.appSurface
                        )
                }
                .shadow(color: isUser ? Color.brand.opacity(0.25) : Color.black.opacity(0.05), radius: 6, x: 0, y: 2)

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - StreamingBubble

private struct StreamingBubble: View {
    let content: String

    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.brand, .brandDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(content + "▌")
                .font(.appBody)
                .foregroundStyle(.appTextPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.appSurface)
                }

            Spacer(minLength: 60)
        }
    }
}

// MARK: - TypingIndicator

private struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.brand, .brandDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.appTextMuted)
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.3 : 0.9)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.6)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + 2)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.appSurface)
            }

            Spacer(minLength: 60)
        }
        .onAppear { phase = 2 }
    }
}
