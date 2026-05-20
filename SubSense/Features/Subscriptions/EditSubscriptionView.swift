import SwiftUI

struct EditSubscriptionView: View {
    let subscription: Subscription

    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionRepository.self) private var repository
    @State private var draft: SubscriptionFormDraft
    @State private var showCurrencyPicker = false
    @State private var isSaving = false
    @State private var saveSuccessTrigger = false
    @State private var errorMessage: String?

    init(subscription: Subscription) {
        self.subscription = subscription
        var d = SubscriptionFormDraft()
        d.name            = subscription.name
        d.category        = subscription.category
        d.brandColor      = subscription.brandColor ?? ""
        d.price           = NSDecimalNumber(decimal: subscription.price).doubleValue
        d.currency        = subscription.currency
        d.cycle           = subscription.cycle
        d.nextDate        = subscription.nextDate
        d.reminderEnabled = subscription.reminderEnabled
        d.notes           = subscription.notes ?? ""
        _draft = State(initialValue: d)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        formFields
                        if let err = errorMessage {
                            Text(err)
                                .font(.appFootnote)
                                .foregroundStyle(Color.appDanger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity)
                        }
                        Spacer().frame(height: AppSpacing.xl3)
                    }
                    .padding(.horizontal, AppSpacing.base)
                    .padding(.top, AppSpacing.md)
                }
            }
            .navigationTitle(String(localized: "subscription.edit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView().tint(Color.brand)
                    } else {
                        Button(String(localized: "general.save")) {
                            Task { await save() }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brand)
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
            .sensoryFeedback(.success, trigger: saveSuccessTrigger)
        }
    }

    // MARK: - Form
    private var formFields: some View {
        VStack(spacing: AppSpacing.xl) {

            // Name
            fieldSection(label: String(localized: "subscription.name.label")) {
                TextField(String(localized: "subscription.namePlaceholder"), text: $draft.name)
                    .textInputAutocapitalization(.words)
                    .font(.appBody)
                    .padding(AppSpacing.base)
                    .background(fieldBG)
            }

            // Category
            fieldSection(label: String(localized: "subscription.category")) {
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
                            .foregroundStyle(Color.appTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextMuted)
                    }
                    .padding(AppSpacing.base)
                    .background(fieldBG)
                }
            }

            // Price + Currency
            fieldSection(label: String(localized: "subscription.price")) {
                HStack(spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(Currencies.symbol(for: draft.currency))
                            .font(.appCallout)
                            .foregroundStyle(Color.appTextMuted)
                        TextField("0.00", value: $draft.price, format: .number)
                            .keyboardType(.decimalPad)
                            .font(.appBody)
                    }
                    .padding(AppSpacing.base)
                    .background(fieldBG)

                    Button {
                        showCurrencyPicker = true
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Text(Currencies.flag(for: draft.currency))
                            Text(draft.currency)
                                .font(.appCallout.weight(.semibold))
                                .foregroundStyle(Color.appTextPrimary)
                            Image(systemName: "chevron.down")
                                .font(.appCaption)
                                .foregroundStyle(Color.appTextMuted)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.base)
                        .background(fieldBG)
                    }
                    .frame(width: 110)
                }
            }

            // Billing Cycle
            fieldSection(label: String(localized: "subscription.billingCycle")) {
                Picker("", selection: $draft.cycle) {
                    Text(String(localized: "subscription.cycle.monthly")).tag(Subscription.Cycle.monthly)
                    Text(String(localized: "subscription.cycle.yearly")).tag(Subscription.Cycle.yearly)
                }
                .pickerStyle(.segmented)
            }

            // Next Billing Date
            fieldSection(label: String(localized: "subscription.nextBillingDate")) {
                DatePicker(
                    "",
                    selection: $draft.nextDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .labelsHidden()
                .padding(AppSpacing.base)
                .background(fieldBG)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Reminder
            fieldSection(label: String(localized: "subscription.remindMe")) {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(String(localized: "subscription.reminder.label"))
                            .font(.appBody)
                            .foregroundStyle(Color.appTextPrimary)
                        Text(String(localized: "subscription.reminder.subtitle"))
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextMuted)
                    }
                    Spacer()
                    Toggle("", isOn: $draft.reminderEnabled)
                        .tint(Color.brand)
                        .labelsHidden()
                }
                .padding(AppSpacing.base)
                .background(fieldBG)
            }

            // Notes
            fieldSection(label: "\(String(localized: "subscription.notes")) (\(String(localized: "general.optional")))") {
                ZStack(alignment: .topLeading) {
                    if draft.notes.isEmpty {
                        Text(String(localized: "subscription.notes.placeholder"))
                            .font(.appBody)
                            .foregroundStyle(Color.appTextMuted)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                    }
                    TextEditor(text: $draft.notes)
                        .font(.appBody)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                }
                .padding(AppSpacing.sm)
                .background(fieldBG)
            }
        }
    }

    @ViewBuilder
    private func fieldSection(
        label: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label.uppercased())
                .font(.appCaption)
                .foregroundStyle(Color.appTextMuted)
                .tracking(0.5)
            content()
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
        }
    }

    private var fieldBG: some View {
        RoundedRectangle(cornerRadius: AppRadius.button)
            .fill(Color.appSurface)
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.button)
                    .strokeBorder(Color.appBorder, lineWidth: 1)
            }
    }

    // MARK: - Save
    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            var updated = subscription
            updated.name            = draft.name.trimmingCharacters(in: .whitespaces)
            updated.category        = draft.category
            updated.brandColor      = draft.brandColor.isEmpty ? nil : draft.brandColor
            updated.price           = Decimal(draft.price)
            updated.currency        = draft.currency
            updated.cycle           = draft.cycle
            updated.nextDate        = draft.nextDate
            updated.reminderEnabled = draft.reminderEnabled
            updated.notes           = draft.notes.isEmpty ? nil : draft.notes
            updated.updatedAt       = Date()
            try await repository.update(updated)
            RenewalScheduler.shared.schedule(updated)
            saveSuccessTrigger.toggle()
            dismiss()
        } catch {
            withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    EditSubscriptionView(subscription: .mock)
        .environment(SubscriptionRepository())
}
