import SwiftUI

struct RecurringEditWrapperView: View {
    let recurring: RecurringTransaction
    let onSave: (RecurringTransaction) -> Void
    let onCancel: () -> Void

    @State private var description: String
    @State private var amountString: String
    @State private var isIncome: Bool
    @State private var frequency: Frequency
    @State private var nextRunDate: Date
    @State private var selectedCategoryId: UUID?

    @State private var isActive: Bool
    @State private var categories: [Category] = []

    init(
        recurring: RecurringTransaction,
        onSave: @escaping (RecurringTransaction) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.recurring = recurring
        self.onSave = onSave
        self.onCancel = onCancel

        _description = State(initialValue: recurring.description)

        let formattedAmount = RecurringEditWrapperView.currencyString(recurring.amount)
        _amountString = State(initialValue: formattedAmount)

        _isIncome = State(initialValue: recurring.isIncome)
        _frequency = State(initialValue: recurring.frequency)
        _nextRunDate = State(initialValue: recurring.nextRunDate)
        _selectedCategoryId = State(initialValue: recurring.categoryId)

        _isActive = State(initialValue: recurring.isActive)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Edit Recurring Transaction") {
                    TextField("Description", text: $description)

                    TextField("Amount", text: $amountString)
                        .keyboardType(.decimalPad)

                    Toggle("Income", isOn: $isIncome)
                        .onChange(of: isIncome) { newValue in
                            reloadCategories()
                            selectedCategoryId = nil

                            let cleaned = amountString
                                .replacingOccurrences(of: "$", with: "")
                                .replacingOccurrences(of: ",", with: "")

                            if var amount = Double(cleaned) {
                                if newValue {
                                    if amount < 0 { amount = -amount }
                                } else {
                                    if amount > 0 { amount = -amount }
                                }

                                amountString = RecurringEditWrapperView.currencyString(amount)
                            }
                        }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(Frequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    DatePicker("Next Run Date", selection: $nextRunDate, displayedComponents: .date)

                    Toggle("Active", isOn: $isActive)
                }

                Section("Category") {
                    NavigationLink {
                        CategorySelectionView(
                            categories: filteredCategories,
                            isIncome: isIncome,
                            selectedCategoryId: $selectedCategoryId
                        )
                    } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(categoryName(for: selectedCategoryId))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Recurring")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleaned = amountString
                            .replacingOccurrences(of: "$", with: "")
                            .replacingOccurrences(of: ",", with: "")

                        guard let rawAmount = Double(cleaned) else { return }

                        let normalizedAmount = isIncome ? abs(rawAmount) : -abs(rawAmount)

                        let updated = RecurringTransaction(
                            id: recurring.id,
                            budgetId: recurring.budgetId,
                            description: description,
                            amount: normalizedAmount,
                            isIncome: isIncome,
                            frequency: frequency,
                            nextRunDate: nextRunDate,
                            categoryId: selectedCategoryId,
                            isActive: isActive
                        )

                        onSave(updated)
                    }
                    .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty ||
                              Double(amountString
                                .replacingOccurrences(of: "$", with: "")
                                .replacingOccurrences(of: ",", with: "")) == nil)
                }
            }
            .onAppear {
                reloadCategories()
            }
        }
    }

    private var filteredCategories: [Category] {
        categories.filter { $0.type == (isIncome ? .income : .expense) }
    }

    private func reloadCategories() {
        categories = Database.shared.fetchActiveCategories()
    }

    private func categoryName(for id: UUID?) -> String {
        guard let id else { return "None" }
        return categories.first(where: { $0.id == id })?.name ?? "None"
    }

    static func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

