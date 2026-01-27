import SwiftUI

struct TransactionEditWrapperView: View {
    let transaction: Transaction
    let onSave: (Transaction) -> Void
    let onCancel: () -> Void

    @State private var date: Date
    @State private var description: String
    @State private var amountString: String
    @State private var isIncome: Bool
    @State private var selectedCategoryId: UUID?

    @State private var categories: [Category] = []

    init(
        transaction: Transaction,
        onSave: @escaping (Transaction) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.transaction = transaction
        self.onSave = onSave
        self.onCancel = onCancel

        _date = State(initialValue: transaction.date)
        _description = State(initialValue: transaction.description)

        // Proper currency formatting for prefill
        let formattedAmount = TransactionEditWrapperView.currencyString(transaction.amount)
        _amountString = State(initialValue: formattedAmount)

        _isIncome = State(initialValue: transaction.isIncome)
        _selectedCategoryId = State(initialValue: transaction.categoryId)
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Edit Fields
                Section("Edit Transaction") {
                    TextField("Description", text: $description)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    TextField("Amount", text: $amountString)
                        .keyboardType(.decimalPad)

                    Toggle("Income", isOn: $isIncome)
                        .onChange(of: isIncome) { newValue in
                            reloadCategories()
                            selectedCategoryId = nil

                            // MARK: - Normalize amount sign when toggling income/expense
                            let cleaned = amountString
                                .replacingOccurrences(of: "$", with: "")
                                .replacingOccurrences(of: ",", with: "")

                            if var amount = Double(cleaned) {
                                if newValue {
                                    // Income → ensure positive
                                    if amount < 0 { amount = -amount }
                                } else {
                                    // Expense → ensure negative
                                    if amount > 0 { amount = -amount }
                                }

                                // Reformat back into currency string
                                amountString = TransactionEditWrapperView.currencyString(amount)
                            }
                        }
                }

                // MARK: - Category
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
            .navigationTitle("Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Strip currency formatting before converting
                        let cleaned = amountString
                            .replacingOccurrences(of: "$", with: "")
                            .replacingOccurrences(of: ",", with: "")

                        guard let amount = Double(cleaned) else { return }

                        let updated = Transaction(
                            id: UUID(),
                            budgetId: transaction.budgetId,
                            date: date,
                            description: description,
                            amount: amount,
                            isIncome: isIncome,
                            categoryId: transaction.categoryId,
                            isRecurringInstance: false,   // NEW
                            recurringRuleId: nil          // NEW
                        )

                        onSave(updated)
                    }
                    .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty ||
                              Double(amountString.replacingOccurrences(of: "$", with: "")
                                    .replacingOccurrences(of: ",", with: "")) == nil)
                }
            }
            .onAppear {
                reloadCategories()
            }
        }
    }

    // MARK: - Filtered categories by type
    private var filteredCategories: [Category] {
        categories.filter { $0.type == (isIncome ? .income : .expense) }
    }

    // MARK: - Helpers
    private func reloadCategories() {
        categories = Database.shared.fetchActiveCategories()
    }

    private func categoryName(for id: UUID?) -> String {
        guard let id else { return "None" }
        return categories.first(where: { $0.id == id })?.name ?? "None"
    }

    // MARK: - Currency Formatter
    static func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

