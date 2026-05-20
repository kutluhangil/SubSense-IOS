import SwiftUI
import Observation

@Observable
final class OnboardingViewModel {
    var currentPage = 0
    var showAuth = false
    var authMode: AuthMode = .signUp

    enum AuthMode { case signIn, signUp }

    let pages = OnboardingPage.all
    var isLastPage: Bool { currentPage == pages.count - 1 }

    func nextPage() {
        guard !isLastPage else { return }
        withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
            currentPage += 1
        }
    }
}

struct OnboardingPage {
    let symbol: String
    let accentColor: String // hex
    let titleKey: String
    let subtitleKey: String

    var title: String { String(localized: String.LocalizationValue(titleKey)) }
    var subtitle: String { String(localized: String.LocalizationValue(subtitleKey)) }

    static let all: [OnboardingPage] = [
        OnboardingPage(
            symbol: "creditcard.and.123",
            accentColor: "#6366F1",
            titleKey: "onboarding.screen1.title",
            subtitleKey: "onboarding.screen1.subtitle"
        ),
        OnboardingPage(
            symbol: "sparkles",
            accentColor: "#F59E0B",
            titleKey: "onboarding.screen2.title",
            subtitleKey: "onboarding.screen2.subtitle"
        ),
        OnboardingPage(
            symbol: "globe.europe.africa.fill",
            accentColor: "#10B981",
            titleKey: "onboarding.screen3.title",
            subtitleKey: "onboarding.screen3.subtitle"
        ),
    ]
}
