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

        let formattedAmount = TransactionEditWrapperView.currencyString(transaction.amount)
        _amountString = State(initialValue: formattedAmount)

        _isIncome = State(initialValue: transaction.isIncome)
        _selectedCategoryId = State(initialValue: transaction.categoryId)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Edit Transaction") {
                    TextField("Description", text: $description)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

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

                                amountString = TransactionEditWrapperView.currencyString(amount)
                            }
                        }
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
            .navigationTitle("Edit Transaction")
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

                        let updated = Transaction(
                            id: transaction.id,
                            budgetId: transaction.budgetId,
                            date: date,
                            description: description,
                            amount: normalizedAmount,
                            isIncome: isIncome,
                            categoryId: selectedCategoryId,
                            isRecurringInstance: transaction.isRecurringInstance,
                            recurringRuleId: transaction.recurringRuleId
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

