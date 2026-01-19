import SwiftUI

struct TransactionEditWrapperView: View {
    let transaction: Transaction
    let onSave: (Transaction) -> Void
    let onCancel: () -> Void

    @State private var date: Date
    @State private var description: String
    @State private var amountString: String
    @State private var isIncome: Bool

    init(transaction: Transaction,
         onSave: @escaping (Transaction) -> Void,
         onCancel: @escaping () -> Void) {
        self.transaction = transaction
        self.onSave = onSave
        self.onCancel = onCancel

        _date = State(initialValue: transaction.date)
        _description = State(initialValue: transaction.description)
        _amountString = State(initialValue: String(transaction.amount))
        _isIncome = State(initialValue: transaction.isIncome)
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
                }
            }
            .navigationTitle("Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount = Double(amountString) else { return }
                        let updated = Transaction(
                            id: transaction.id,
                            budgetId: transaction.budgetId,
                            date: date,
                            description: description,
                            amount: amount,
                            isIncome: isIncome
                        )
                        onSave(updated)
                    }
                    .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty || Double(amountString) == nil)
                }
            }
        }
    }
}
//
//  TransactionEditWrapperView.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/6/26.
//

