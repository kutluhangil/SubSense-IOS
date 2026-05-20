import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var profileRepo = ProfileRepository()
    @AppStorage("appColorScheme") private var colorSchemePreference = "system"
    @State private var showSignOutConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var showPaywall = false
    @State private var showCurrencyPicker = false
    @State private var signOutTrigger = false
    @State private var isUpdatingProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                List {
                    // Account
                    Section { accountRow }

                    // Preferences
                    Section(String(localized: "settings.preferences")) {
                        // Currency
                        Button {
                            showCurrencyPicker = true
                        } label: {
                            HStack {
                                Label(String(localized: "settings.currency"), systemImage: "dollarsign.circle")
                                    .foregroundStyle(Color.appTextPrimary)
                                Spacer()
                                Text(profileRepo.profile?.baseCurrency ?? "USD")
                                    .foregroundStyle(Color.appTextMuted)
                                Image(systemName: "chevron.right")
                                    .font(.appCaption)
                                    .foregroundStyle(Color.appTextMuted)
                            }
                        }
                        .buttonStyle(.plain)

                        // Language
                        if let profile = profileRepo.profile {
                            HStack {
                                Label(String(localized: "settings.language"), systemImage: "globe")
                                    .foregroundStyle(Color.appTextPrimary)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { profile.preferredLanguage },
                                    set: { newLang in
                                        Task { await updateLanguage(newLang) }
                                    }
                                )) {
                                    ForEach(Profile.Language.allCases, id: \.self) { lang in
                                        Text(lang.displayName).tag(lang)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                        }

                        // Appearance
                        HStack {
                            Label(String(localized: "settings.appearance"), systemImage: "paintbrush")
                                .foregroundStyle(Color.appTextPrimary)
                            Spacer()
                            Picker("", selection: $colorSchemePreference) {
                                Text("System").tag("system")
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                    }

                    // Plan
                    Section(String(localized: "settings.plan")) {
                        Button {
                            if !profileRepo.isPro { showPaywall = true }
                        } label: {
                            HStack {
                                Label(
                                    profileRepo.isPro ? "SubSense Pro" : String(localized: "settings.freePlan"),
                                    systemImage: profileRepo.isPro ? "crown.fill" : "person.fill"
                                )
                                .foregroundStyle(profileRepo.isPro ? Color.accent : Color.appTextPrimary)
                                Spacer()
                                if !profileRepo.isPro {
                                    Text(String(localized: "settings.upgrade"))
                                        .font(.appCaption.weight(.semibold))
                                        .foregroundStyle(Color.brand)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.appSuccess)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        Button(String(localized: "settings.restorePurchases")) {
                            Task { await restorePurchases() }
                        }
                        .foregroundStyle(Color.brand)
                    }

                    // Support
                    Section(String(localized: "settings.support")) {
                        Link(String(localized: "settings.helpCenter"),
                             destination: URL(string: "https://subsense.app/help")!)
                        Button(String(localized: "settings.rateApp")) {
                            requestAppReview()
                        }
                        .foregroundStyle(Color.brand)
                    }

                    // Legal
                    Section(String(localized: "settings.legal")) {
                        Link(String(localized: "settings.privacyPolicy"),
                             destination: URL(string: "https://subsense.app/privacy")!)
                        Link(String(localized: "settings.termsOfService"),
                             destination: URL(string: "https://subsense.app/terms")!)
                    }

                    // Account actions
                    Section {
                        Button(role: .destructive) {
                            showSignOutConfirm = true
                        } label: {
                            Label(String(localized: "settings.signOut"),
                                  systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        Button(role: .destructive) {
                            showDeleteAccountConfirm = true
                        } label: {
                            Label(String(localized: "settings.deleteAccount"),
                                  systemImage: "trash")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCurrencyPicker) {
                CurrencyPickerSheet(
                    selectedCurrency: Binding(
                        get: { profileRepo.profile?.baseCurrency ?? "USD" },
                        set: { newCurrency in Task { await updateCurrency(newCurrency) } }
                    ),
                    isPresented: $showCurrencyPicker
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .confirmationDialog(String(localized: "settings.signOut.confirm"), isPresented: $showSignOutConfirm) {
                Button(String(localized: "settings.signOut"), role: .destructive) {
                    Task {
                        try? await authStore.signOut()
                        signOutTrigger.toggle()
                    }
                }
                Button(String(localized: "general.cancel"), role: .cancel) {}
            }
            .confirmationDialog(String(localized: "settings.deleteAccount.confirm"), isPresented: $showDeleteAccountConfirm) {
                Button(String(localized: "settings.deleteAccount"), role: .destructive) {
                    Task { try? await authStore.deleteAccount() }
                }
                Button(String(localized: "general.cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "settings.deleteAccount.message"))
            }
            .sensoryFeedback(.impact, trigger: signOutTrigger)
            .task {
                if let uid = authStore.userID {
                    try? await profileRepo.fetch(userId: uid)
                }
            }
        }
    }

    // MARK: - Account row

    private var accountRow: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.12))
                    .frame(width: 48, height: 48)
                Text(profileRepo.profile?.initials ?? "U")
                    .font(.appTitle2)
                    .foregroundStyle(Color.brand)
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(profileRepo.profile?.displayName ?? String(localized: "settings.account"))
                    .font(.appCallout)
                    .foregroundStyle(Color.appTextPrimary)
                if let email = authStore.userEmail {
                    Text(email)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextMuted)
                }
            }
        }
    }

    // MARK: - Actions

    private func restorePurchases() async {
        let storeKit = StoreKitService()
        await storeKit.restorePurchases()
        if let uid = authStore.userID {
            try? await profileRepo.fetch(userId: uid)
        }
    }

    private func requestAppReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        AppStore.requestReview(in: scene)
    }

    private func updateCurrency(_ currency: String) async {
        guard var profile = profileRepo.profile else { return }
        profile.baseCurrency = currency
        try? await profileRepo.update(profile)
    }

    private func updateLanguage(_ language: Profile.Language) async {
        guard var profile = profileRepo.profile else { return }
        profile.preferredLanguage = language
        try? await profileRepo.update(profile)
    }
}

#Preview {
    SettingsView()
        .environment(AuthStore())
}
