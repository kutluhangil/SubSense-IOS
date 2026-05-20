import SwiftUI

struct SettingsView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var profileRepo = ProfileRepository()
    @AppStorage("appColorScheme") private var colorSchemePreference = "system"
    @State private var showSignOutConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var signOutTrigger = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                List {
                    // Account
                    Section {
                        accountRow
                    }

                    // Preferences
                    Section(String(localized: "settings.preferences")) {
                        // Currency
                        HStack {
                            Label(String(localized: "settings.currency"), systemImage: "dollarsign.circle")
                                .foregroundStyle(.appTextPrimary)
                            Spacer()
                            Text(profileRepo.profile?.baseCurrency ?? "USD")
                                .foregroundStyle(.appTextMuted)
                        }

                        // Appearance
                        HStack {
                            Label(String(localized: "settings.appearance"), systemImage: "paintbrush")
                                .foregroundStyle(.appTextPrimary)
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
                        HStack {
                            Label(
                                profileRepo.isPro ? "SubSense Pro" : "Free Plan",
                                systemImage: profileRepo.isPro ? "crown.fill" : "person.fill"
                            )
                            .foregroundStyle(profileRepo.isPro ? .accent : .appTextPrimary)
                            Spacer()
                            if !profileRepo.isPro {
                                Text(String(localized: "settings.upgrade"))
                                    .font(.appCaption.weight(.semibold))
                                    .foregroundStyle(.brand)
                            }
                        }
                        Button(String(localized: "settings.restorePurchases")) {}
                            .foregroundStyle(.brand)
                    }

                    // Support
                    Section(String(localized: "settings.support")) {
                        Link(String(localized: "settings.helpCenter"), destination: URL(string: "https://subsense.app/help")!)
                        Button(String(localized: "settings.rateApp")) {}
                            .foregroundStyle(.brand)
                    }

                    // Legal
                    Section(String(localized: "settings.legal")) {
                        Link(String(localized: "settings.privacyPolicy"), destination: URL(string: "https://subsense.app/privacy")!)
                        Link(String(localized: "settings.termsOfService"), destination: URL(string: "https://subsense.app/terms")!)
                    }

                    // Account actions
                    Section {
                        Button(role: .destructive) {
                            showSignOutConfirm = true
                        } label: {
                            Label(String(localized: "settings.signOut"), systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        Button(role: .destructive) {
                            showDeleteAccountConfirm = true
                        } label: {
                            Label(String(localized: "settings.deleteAccount"), systemImage: "trash")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authStore.signOut()
                        signOutTrigger.toggle()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Delete account?", isPresented: $showDeleteAccountConfirm) {
                Button("Delete Account", role: .destructive) {
                    Task { try? await authStore.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes all your data and cannot be undone.")
            }
            .sensoryFeedback(.impact(.medium), trigger: signOutTrigger)
            .task {
                if let uid = authStore.userID {
                    try? await profileRepo.fetch(userId: uid)
                }
            }
        }
    }

    private var accountRow: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.12))
                    .frame(width: 48, height: 48)
                Text(profileRepo.profile?.initials ?? "U")
                    .font(.appTitle2)
                    .foregroundStyle(.brand)
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(profileRepo.profile?.displayName ?? "Account")
                    .font(.appCallout)
                    .foregroundStyle(.appTextPrimary)
                if let email = authStore.userEmail {
                    Text(email)
                        .font(.appCaption)
                        .foregroundStyle(.appTextMuted)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AuthStore())
}
