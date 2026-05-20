import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storeKit = StoreKitService()
    @State private var selectedPlan: String = ProductID.proYearly
    @State private var isPurchasing = false
    @State private var successTrigger = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Entrance animations
    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = 30
    @State private var featuresOpacity: Double = 0
    @State private var plansOpacity: Double = 0

    private let features: [(icon: String, color: Color, text: String)] = [
        ("cpu.fill",               .brand,      "ai.insights.feature"),
        ("message.fill",           .accent,     "ai.chat.feature"),
        ("globe",                  .appInfo,    "price.comparison.feature"),
        ("arrow.down.doc.fill",    .appSuccess, "csv.import.feature"),
        ("headphones",             .appWarning, "priority.support.feature"),
    ]

    var body: some View {
        ZStack {
            // Premium dark gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#09090B"),
                    Color.brand.opacity(0.15),
                    Color(hex: "#09090B"),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Grain / star overlay
            Canvas { ctx, size in
                for _ in 0..<60 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let r = CGFloat.random(in: 0.5...1.5)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                        with: .color(.white.opacity(CGFloat.random(in: 0.05...0.2)))
                    )
                }
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Close button
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.appCallout)
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(.white.opacity(0.08)))
                        }
                    }
                    .padding(.horizontal, AppSpacing.base)

                    // Hero
                    VStack(spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(RadialGradient(
                                    colors: [.accent.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                ))
                                .frame(width: 100, height: 100)
                            Image(systemName: "sparkles")
                                .font(.system(size: 44, weight: .thin))
                                .foregroundStyle(.accent)
                                .symbolEffect(.pulse, options: .repeating.speed(0.4))
                        }
                        Text(String(localized: "paywall.title"))
                            .font(.display)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        Text(String(localized: "paywall.subtitle"))
                            .font(.appBody)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(headerOpacity)
                    .offset(y: headerOffset)

                    // Feature list
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(features, id: \.text) { feature in
                            HStack(spacing: AppSpacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(feature.color.opacity(0.12))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: feature.icon)
                                        .font(.appCaption.weight(.semibold))
                                        .foregroundStyle(feature.color)
                                }
                                Text(String(localized: String.LocalizationValue(feature.text)))
                                    .font(.appCallout)
                                    .foregroundStyle(.white.opacity(0.85))
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.appCaption.weight(.bold))
                                    .foregroundStyle(.appSuccess)
                            }
                        }
                    }
                    .padding(AppSpacing.base)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.card)
                            .fill(.white.opacity(0.04))
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.card)
                                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                            }
                    }
                    .padding(.horizontal, AppSpacing.base)
                    .opacity(featuresOpacity)

                    // Plan selector
                    VStack(spacing: AppSpacing.sm) {
                        if let yearly = storeKit.yearlyProduct {
                            PlanCard(product: yearly, isSelected: selectedPlan == yearly.id, badge: "Save 37%") {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedPlan = yearly.id
                                }
                            }
                        } else {
                            planCardPlaceholder(
                                title: "Yearly",
                                price: "$29.99/yr",
                                subprice: "$2.50/month",
                                badge: "Save 37%",
                                isSelected: selectedPlan == ProductID.proYearly
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedPlan = ProductID.proYearly
                                }
                            }
                        }

                        if let monthly = storeKit.monthlyProduct {
                            PlanCard(product: monthly, isSelected: selectedPlan == monthly.id, badge: nil) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedPlan = monthly.id
                                }
                            }
                        } else {
                            planCardPlaceholder(
                                title: "Monthly",
                                price: "$3.99/mo",
                                subprice: nil,
                                badge: nil,
                                isSelected: selectedPlan == ProductID.proMonthly
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedPlan = ProductID.proMonthly
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.base)
                    .opacity(plansOpacity)

                    // CTA
                    Button {
                        Task { await purchase() }
                    } label: {
                        ZStack {
                            if isPurchasing {
                                ProgressView().progressViewStyle(.circular).tint(.white)
                            } else {
                                Text(String(localized: "paywall.startTrial"))
                                    .font(.appCallout.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background {
                            RoundedRectangle(cornerRadius: AppRadius.button)
                                .fill(LinearGradient(
                                    colors: [.brand, .brandDeep],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .shadow(color: .brand.opacity(0.4), radius: 16, x: 0, y: 6)
                        }
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal, AppSpacing.base)
                    .sensoryFeedback(.success, trigger: successTrigger)
                    .opacity(plansOpacity)

                    // Footer links
                    HStack(spacing: AppSpacing.base) {
                        Button(String(localized: "paywall.restore")) {
                            Task { await storeKit.restorePurchases() }
                        }
                        Text("·").foregroundStyle(.white.opacity(0.3))
                        Link(
                            String(localized: "settings.termsOfService"),
                            destination: URL(string: "https://subsense.app/terms")!
                        )
                        Text("·").foregroundStyle(.white.opacity(0.3))
                        Link(
                            String(localized: "settings.privacyPolicy"),
                            destination: URL(string: "https://subsense.app/privacy")!
                        )
                    }
                    .font(.appCaption)
                    .foregroundStyle(.white.opacity(0.4))

                    Spacer().frame(height: AppSpacing.xl3)
                }
                .padding(.top, AppSpacing.md)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                headerOpacity = 1
                headerOffset = 0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25)) {
                featuresOpacity = 1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) {
                plansOpacity = 1
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task { await storeKit.fetchProducts() }
    }

    // MARK: - Placeholder plan card (before StoreKit loads)
    @ViewBuilder
    private func planCardPlaceholder(
        title: String,
        price: String,
        subprice: String?,
        badge: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.sm) {
                        Text(title)
                            .font(.appCallout.weight(.semibold))
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.appCaption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.accent))
                        }
                    }
                    if let sub = subprice {
                        Text(sub)
                            .font(.appCaption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                Spacer()
                Text(price)
                    .font(.appCallout.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(AppSpacing.base)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .fill(isSelected ? Color.brand.opacity(0.2) : Color.white.opacity(0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.card)
                            .strokeBorder(
                                isSelected ? Color.brand : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }

    // MARK: - Purchase
    private func purchase() async {
        isPurchasing = true
        guard let product = storeKit.products.first(where: { $0.id == selectedPlan }) else {
            isPurchasing = false
            return
        }
        do {
            try await storeKit.purchase(product)
            successTrigger.toggle()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}

// MARK: - PlanCard

struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.sm) {
                        Text(product.displayName)
                            .font(.appCallout.weight(.semibold))
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.appCaption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.accent))
                        }
                    }
                    Text(product.description)
                        .font(.appCaption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.appCallout.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(AppSpacing.base)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .fill(isSelected ? Color.brand.opacity(0.2) : Color.white.opacity(0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.card)
                            .strokeBorder(
                                isSelected ? Color.brand : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}
