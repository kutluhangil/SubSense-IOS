import Foundation

enum L10n {
    // MARK: - Auth
    enum Auth {
        static let signInTitle = String(localized: "auth.signIn.title")
        static let signUpTitle = String(localized: "auth.signUp.title")
        static let email = String(localized: "auth.email")
        static let password = String(localized: "auth.password")
        static let forgotPassword = String(localized: "auth.forgotPassword")
        static let signInButton = String(localized: "auth.signInButton")
        static let signUpButton = String(localized: "auth.signUpButton")
        static let continueWithApple = String(localized: "auth.continueWithApple")
        static let verifyEmailTitle = String(localized: "auth.verifyEmail.title")
        static let verifyEmailSubtitle = String(localized: "auth.verifyEmail.subtitle")
        static let verifyEmailRefresh = String(localized: "auth.verifyEmail.refresh")
        static let resendEmail = String(localized: "auth.resendEmail")
        static let switchToSignUp = String(localized: "auth.switchToSignUp")
        static let switchToSignIn = String(localized: "auth.switchToSignIn")
    }

    // MARK: - Onboarding
    enum Onboarding {
        static let screen1Title = String(localized: "onboarding.screen1.title")
        static let screen1Subtitle = String(localized: "onboarding.screen1.subtitle")
        static let screen2Title = String(localized: "onboarding.screen2.title")
        static let screen2Subtitle = String(localized: "onboarding.screen2.subtitle")
        static let screen3Title = String(localized: "onboarding.screen3.title")
        static let screen3Subtitle = String(localized: "onboarding.screen3.subtitle")
        static let continueButton = String(localized: "onboarding.continueButton")
        static let getStarted = String(localized: "onboarding.getStarted")
    }

    // MARK: - Dashboard
    enum Dashboard {
        static let title = String(localized: "dashboard.title")
        static let thisMonth = String(localized: "dashboard.thisMonth")
        static let upNext = String(localized: "dashboard.upNext")
        static let seeAll = String(localized: "dashboard.seeAll")
        static let activeCount = String(localized: "dashboard.activeCount")
        static let yearlyTotal = String(localized: "dashboard.yearlyTotal")
        static let aiInsight = String(localized: "dashboard.aiInsight")
        static let vsLastMonth = String(localized: "dashboard.vsLastMonth")
    }

    // MARK: - Subscription
    enum Subscription {
        static let title = String(localized: "subscription.title")
        static let addTitle = String(localized: "subscription.add.title")
        static let editTitle = String(localized: "subscription.edit.title")
        static let name = String(localized: "subscription.name")
        static let category = String(localized: "subscription.category")
        static let price = String(localized: "subscription.price")
        static let currency = String(localized: "subscription.currency")
        static let cycleMonthly = String(localized: "subscription.cycle.monthly")
        static let cycleYearly = String(localized: "subscription.cycle.yearly")
        static let nextBillingDate = String(localized: "subscription.nextBillingDate")
        static let remindMe = String(localized: "subscription.remindMe")
        static let notes = String(localized: "subscription.notes")
        static let save = String(localized: "subscription.save")
        static let cancel = String(localized: "subscription.cancel")
        static let delete = String(localized: "subscription.delete")
        static let markInactive = String(localized: "subscription.markInactive")
        static let statusActive = String(localized: "subscription.status.active")
        static let statusTrial = String(localized: "subscription.status.trial")
        static let statusExpiring = String(localized: "subscription.status.expiring")
        static let statusInactive = String(localized: "subscription.status.inactive")
        static let discoverTitle = String(localized: "subscription.discover.title")
        static let pickPopular = String(localized: "subscription.pickPopular")
        static let perMonth = String(localized: "subscription.perMonth")
        static let perYear = String(localized: "subscription.perYear")
        static let nextCharge = String(localized: "subscription.nextCharge")
        static let lifetime = String(localized: "subscription.lifetime")
        static let renewalHistory = String(localized: "subscription.renewalHistory")
    }

    // MARK: - Analytics
    enum Analytics {
        static let title = String(localized: "analytics.title")
        static let spendingTrend = String(localized: "analytics.spending.trend")
        static let byCategory = String(localized: "analytics.byCategory")
        static let topServices = String(localized: "analytics.topServices")
        static let budgets = String(localized: "analytics.budgets")
        static let range30d = String(localized: "analytics.range.30d")
        static let range3m = String(localized: "analytics.range.3m")
        static let range6m = String(localized: "analytics.range.6m")
        static let range12m = String(localized: "analytics.range.12m")
    }

    // MARK: - AI
    enum AI {
        static let insightsTitle = String(localized: "ai.insights.title")
        static let assistantPlaceholder = String(localized: "ai.assistant.placeholder")
        static let poweredBy = String(localized: "ai.poweredBy")
        static let askAssistant = String(localized: "ai.askAssistant")
        static let proOnly = String(localized: "ai.proOnly")
    }

    // MARK: - Settings
    enum Settings {
        static let title = String(localized: "settings.title")
        static let preferences = String(localized: "settings.preferences")
        static let currency = String(localized: "settings.currency")
        static let language = String(localized: "settings.language")
        static let appearance = String(localized: "settings.appearance")
        static let notifications = String(localized: "settings.notifications")
        static let plan = String(localized: "settings.plan")
        static let upgrade = String(localized: "settings.upgrade")
        static let restorePurchases = String(localized: "settings.restorePurchases")
        static let data = String(localized: "settings.data")
        static let exportCSV = String(localized: "settings.exportCSV")
        static let importCSV = String(localized: "settings.importCSV")
        static let support = String(localized: "settings.support")
        static let helpCenter = String(localized: "settings.helpCenter")
        static let contactSupport = String(localized: "settings.contactSupport")
        static let rateApp = String(localized: "settings.rateApp")
        static let signOut = String(localized: "settings.signOut")
        static let deleteAccount = String(localized: "settings.deleteAccount")
        static let legal = String(localized: "settings.legal")
        static let privacyPolicy = String(localized: "settings.privacyPolicy")
        static let termsOfService = String(localized: "settings.termsOfService")
    }

    // MARK: - Notifications
    enum Notifications {
        static func renewal(service: String, days: Int) -> String {
            String(localized: "notifications.renewal \(service) \(days)")
        }
    }

    // MARK: - Paywall
    enum Paywall {
        static let title = String(localized: "paywall.title")
        static let subtitle = String(localized: "paywall.subtitle")
        static let featureAI = String(localized: "paywall.feature.aiInsights")
        static let featureChat = String(localized: "paywall.feature.chat")
        static let featureComparison = String(localized: "paywall.feature.comparison")
        static let featureSupport = String(localized: "paywall.feature.support")
        static let yearlyPlan = String(localized: "paywall.plan.yearly")
        static let monthlyPlan = String(localized: "paywall.plan.monthly")
        static let startTrial = String(localized: "paywall.startTrial")
        static let restore = String(localized: "paywall.restore")
    }

    // MARK: - General
    enum General {
        static let loading = String(localized: "general.loading")
        static let error = String(localized: "general.error")
        static let retry = String(localized: "general.retry")
        static let done = String(localized: "general.done")
        static let edit = String(localized: "general.edit")
        static let delete = String(localized: "general.delete")
        static let cancel = String(localized: "general.cancel")
        static let save = String(localized: "general.save")
        static let pro = String(localized: "general.pro")
    }
}
