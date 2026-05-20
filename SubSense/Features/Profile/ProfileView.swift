import SwiftUI

struct ProfileView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var profileRepo = ProfileRepository()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Avatar
                        VStack(spacing: AppSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.brand.opacity(0.12))
                                    .frame(width: 80, height: 80)
                                Text(profileRepo.profile?.initials ?? "U")
                                    .font(.display)
                                    .foregroundStyle(Color.brand)
                            }
                            VStack(spacing: AppSpacing.xs) {
                                Text(profileRepo.profile?.displayName ?? authStore.userEmail ?? "")
                                    .font(.appTitle2)
                                    .foregroundStyle(Color.appTextPrimary)
                                if let email = authStore.userEmail {
                                    Text(email)
                                        .font(.appFootnote)
                                        .foregroundStyle(Color.appTextMuted)
                                }
                            }
                        }
                        .padding(.top, AppSpacing.xl)

                        // Plan badge
                        if profileRepo.isPro {
                            Label("SubSense Pro", systemImage: "crown.fill")
                                .font(.appCallout.weight(.semibold))
                                .foregroundStyle(Color.accent)
                                .padding(.horizontal, AppSpacing.base)
                                .padding(.vertical, AppSpacing.sm)
                                .background(Capsule().fill(Color.accent.opacity(0.12)))
                        }

                        Spacer().frame(height: AppSpacing.xl4)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if let uid = authStore.userID {
                    try? await profileRepo.fetch(userId: uid)
                }
            }
        }
    }
}
