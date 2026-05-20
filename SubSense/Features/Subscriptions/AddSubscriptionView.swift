import SwiftUI

// MARK: - Add Subscription View
struct AddSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthStore.self) private var authStore
    @Environment(SubscriptionRepository.self) private var repository
    @State private var catalogItems: [ServiceCatalogItem] = []
    @State private var draft = SubscriptionFormDraft()
    @State private var showCurrencyPicker = false
    @State private var showCatalog = false
    @State private var showDuplicateAlert = false
    @State private var isSaving = false
    @State private var saveSuccessTrigger = false
    @State private var validationError: String?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        popularServicesSection
                        formFields
                        validationLabel
                        Spacer().frame(height: AppSpacing.xl3)
                    }
                    .padding(.horizontal, AppSpacing.base)
                    .padding(.top, AppSpacing.md)
                }
            }
            .navigationTitle(String(localized: "subscription.add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView().tint(.brand)
                    } else {
                        Button(String(localized: "general.save")) {
                            Task { await save() }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(isFormValid ? .brand : .appTextMuted)
                        .disabled(!isFormValid)
                    }
                }
            }
            .sheet(isPresented: $showCurrencyPicker) {
                CurrencyPickerSheet(
                    selectedCurrency: $draft.currency,
                    isPresented: $showCurrencyPicker
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showCatalog) {
                ServiceCatalogView { item in
                    applyFromCatalog(item)
                }
            }
            .alert(String(localized: "subscription.duplicate.title"), isPresented: $showDuplicateAlert) {
                Button(String(localized: "subscription.duplicate.addAnyway")) { Task { await saveForced() } }
                Button(String(localized: "general.cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "subscription.duplicate.message"))
            }
            .sensoryFeedback(.success, trigger: saveSuccessTrigger)
        }
        .onAppear { loadCatalog() }
    }

    // MARK: - Popular Services Strip
    private var popularServicesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(String(localized: "subscription.pickPopular").uppercased())
                    .font(.appCaption)
                    .foregroundStyle(.appTextMuted)
                    .tracking(0.5)
                Spacer()
                Button {
                    showCatalog = true
                } label: {
                    Text(String(localized: "subscription.seeAll"))
                        .font(.appCaption)
                        .foregroundStyle(.brand)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(catalogItems.prefix(12)) { item in
                        Button {
                            applyFromCatalog(item)
                        } label: {
                            VStack(spacing: AppSpacing.xs) {
                                BrandIcon(
                                    name: item.name,
                                    brandColor: Color(hex: item.brandColor),
                                    size: 52,
                                    radius: AppRadius.icon
                                )
                                Text(item.name)
                                    .font(.appCaption)
                                    .foregroundStyle(.appTextMuted)
                                    .lineLimit(1)
                                    .frame(width: 56)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // "More" bubble
                    Button {
                        showCatalog = true
                    } label: {
                        VStack(spacing: AppSpacing.xs) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppRadius.icon)
                                    .fill(Color.appSurface)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: AppRadius.icon)
                                            .strokeBorder(Color.appBorder, lineWidth: 1)
                                    }
                                    .frame(width: 52, height: 52)
                                Image(systemName: "ellipsis")
                                    .foregroundStyle(.appTextMuted)
                            }
                            Text(String(localized: "subscription.more"))
                                .font(.appCaption)
                                .foregroundStyle(.appTextMuted)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.base)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.card)
                .fill(Color.appSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.card)
                        .strokeBorder(Color.appBorder, lineWidth: 1)
                }
        }
    }

    // MARK: - Form Fields
    private var formFields: some View {
        VStack(spacing: AppSpacing.xl) {
            // Name
            formSection(title: String(localized: "subscription.name")) {
                TextField(String(localized: "subscription.namePlaceholder"), text: $draft.name)
                    .textInputAutocapitalization(.words)
                    .font(.appBody)
                    .padding(AppSpacing.base)
                    .background(fieldBackground)
            }

            // Category
            formSection(title: String(localized: "subscription.category")) {
                Menu {
                    ForEach(Subscription.Category.allCases, id: \.self) { cat in
                        Button {
                            draft.category = cat
                        } label: {
                            Label(cat.displayName, systemImage: cat.symbol)
                        }
                    }
                } label: {
                    HStack {
                        Label(draft.category.displayName, systemImage: draft.category.symbol)
                            .font(.appBody)
                            .foregroundStyle(.appTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.appCaption)
                            .foregroundStyle(.appTextMuted)
                    }
                    .padding(AppSpacing.base)
                    .background(fieldBackground)
                }
            }

            // Price + Currency
            formSection(title: String(localized: "subscription.price")) {
                HStack(spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(Currencies.symbol(for: draft.currency))
                            .font(.appCallout)
                            .foregroundStyle(.appTextMuted)
                        TextField("0.00", value: $draft.price, format: .number)
                            .keyboardType(.decimalPad)
                            .font(.appBody)
                    }
                    .padding(AppSpacing.base)
                    .background(fieldBackground)

                    Button {
                        showCurrencyPicker = true
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Text(Currencies.flag(for: draft.currency))
                            Text(draft.currency)
                                .font(.appCallout.weight(.semibold))
                                .foregroundStyle(.appTextPrimary)
                            Image(systemName: "chevron.down")
                                .font(.appCaption)
                                .foregroundStyle(.appTextMuted)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.base)
                        .background(fieldBackground)
                    }
                    .frame(width: 110)
                }
            }

            // Billing Cycle
            formSection(title: String(localized: "subscription.billingCycle")) {
                Picker("Cycle", selection: $draft.cycle) {
                    Text(String(localized: "subscription.cycle.monthly")).tag(Subscription.Cycle.monthly)
                    Text(String(localized: "subscription.cycle.yearly")).tag(Subscription.Cycle.yearly)
                }
                .pickerStyle(.segmented)
            }

            // Next billing date
            formSection(title: String(localized: "subscription.nextBillingDate")) {
                DatePicker(
                    "",
                    selection: $draft.nextDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .labelsHidden()
                .padding(AppSpacing.base)
                .background(fieldBackground)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Reminder toggle
            formSection(title: String(localized: "subscription.remindMe")) {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(String(localized: "subscription.reminder.label"))
                            .font(.appBody)
                            .foregroundStyle(.appTextPrimary)
                        Text(String(localized: "subscription.reminder.subtitle"))
                            .font(.appCaption)
                            .foregroundStyle(.appTextMuted)
                    }
                    Spacer()
                    Toggle("", isOn: $draft.reminderEnabled)
                        .tint(.brand)
                        .labelsHidden()
                }
                .padding(AppSpacing.base)
                .background(fieldBackground)
            }

            // Notes (optional)
            formSection(title: "\(String(localized: "subscription.notes")) (\(String(localized: "general.optional")))") {
                ZStack(alignment: .topLeading) {
                    if draft.notes.isEmpty {
                        Text(String(localized: "subscription.notes.placeholder"))
                            .font(.appBody)
                            .foregroundStyle(.appTextMuted)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                    }
                    TextEditor(text: $draft.notes)
                        .font(.appBody)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                }
                .padding(AppSpacing.sm)
                .background(fieldBackground)
            }
        }
    }

    @ViewBuilder
    private var validationLabel: some View {
        if let err = validationError {
            Text(err)
                .font(.appFootnote)
                .foregroundStyle(.appDanger)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
        }
    }

    // MARK: - Helpers
    @ViewBuilder
    private func formSection(
        title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title.uppercased())
                .font(.appCaption)
                .foregroundStyle(.appTextMuted)
                .tracking(0.5)
            content()
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.button)
            .fill(Color.appSurface)
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.button)
                    .strokeBorder(Color.appBorder, lineWidth: 1)
            }
    }

    private var isFormValid: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty && draft.price > 0
    }

    private func applyFromCatalog(_ item: ServiceCatalogItem) {
        let template = item.toSubscriptionDraft()
        draft.name      = template.name
        draft.category  = template.category
        draft.brandColor = template.brandColor
        if template.price > 0 {
            draft.price = NSDecimalNumber(decimal: template.price).doubleValue
        }
        draft.currency = template.currency
        draft.cycle    = template.cycle
    }

    private func loadCatalog() {
        guard
            let url  = Bundle.main.url(forResource: "ServiceCatalog", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let items = try? JSONDecoder().decode([ServiceCatalogItem].self, from: data)
        else { return }
        catalogItems = items
    }

    // MARK: - Save
    private func save() async {
        guard isFormValid, let userId = authStore.userID else { return }
        let sub = draft.toSubscription(userId: userId)
        if repository.isDuplicate(sub) {
            showDuplicateAlert = true
            return
        }
        await saveForced()
    }

    private func saveForced() async {
        guard let userId = authStore.userID else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let sub = draft.toSubscription(userId: userId)
            try await repository.forceAdd(sub)
            RenewalScheduler.shared.schedule(sub)
            saveSuccessTrigger.toggle()
            dismiss()
        } catch {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                validationError = error.localizedDescription
            }
        }
    }
}

// MARK: - Form Draft
struct SubscriptionFormDraft {
    var name          = ""
    var category: Subscription.Category = .other
    var brandColor    = ""
    var price: Double = 0
    var currency      = Locale.current.currency?.identifier ?? "USD"
    var cycle: Subscription.Cycle = .monthly
    var nextDate      = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    var reminderEnabled = true
    var notes         = ""

    func toSubscription(userId: UUID) -> Subscription {
        Subscription(
            id: UUID(),
            userId: userId,
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            serviceType: nil,
            logoURL: nil,
            brandColor: brandColor.isEmpty ? nil : brandColor,
            price: Decimal(price),
            currency: currency,
            cycle: cycle,
            startDate: Date(),
            nextDate: nextDate,
            trialEndDate: nil,
            billingDay: Calendar.current.component(.day, from: nextDate),
            status: .active,
            nickname: nil,
            notes: notes.isEmpty ? nil : notes,
            reminderEnabled: reminderEnabled,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

#Preview {
    AddSubscriptionView()
        .environment(AuthStore())
        .environment(SubscriptionRepository())
}
