import SwiftUI
import Supabase

@main
struct SubSenseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var authStore = AuthStore()
    @State private var subscriptionRepository = SubscriptionRepository()
    @State private var currencyService = CurrencyService()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("appColorScheme") private var colorSchemePreference = "system"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authStore)
                .environment(subscriptionRepository)
                .environment(currencyService)
                .preferredColorScheme(resolvedColorScheme)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let host = url.host else { return }
        switch host {
        case "verify":
            Task { try? await SupabaseClientManager.shared.auth.session(from: url) }
        case "reset":
            NotificationCenter.default.post(name: .handlePasswordReset, object: url)
        default:
            break
        }
    }
}

struct RootView: View {
    @Environment(AuthStore.self) private var authStore
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if !authStore.isAuthenticated {
                AuthFlowView()
            } else {
                MainTabView()
            }
        }
        .animation(Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: authStore.isAuthenticated)
        .animation(Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: hasSeenOnboarding)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showAddSubscription = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                    .tabItem {
                        Label("dashboard.tab", systemImage: "house.fill")
                    }

                SubscriptionListView()
                    .tag(1)
                    .tabItem {
                        Label("subscriptions.tab", systemImage: "list.bullet")
                    }

                Color.clear
                    .tag(2)
                    .tabItem {
                        Label("add.tab", systemImage: "plus")
                    }

                AnalyticsView()
                    .tag(3)
                    .tabItem {
                        Label("analytics.tab", systemImage: "chart.bar.fill")
                    }

                SettingsView()
                    .tag(4)
                    .tabItem {
                        Label("settings.tab", systemImage: "gearshape.fill")
                    }
            }
            .tint(Color.brand)

            // Floating center + button
            Button {
                showAddSubscription = true
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.brand, .brandDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.brand.opacity(0.4), radius: 12, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -16)
        }
        .sheet(isPresented: $showAddSubscription) {
            AddSubscriptionView()
        }
        .onChange(of: selectedTab) { _, new in
            if new == 2 {
                selectedTab = 0
                showAddSubscription = true
            }
        }
    }
}

extension Notification.Name {
    static let handlePasswordReset = Notification.Name("handlePasswordReset")
}
