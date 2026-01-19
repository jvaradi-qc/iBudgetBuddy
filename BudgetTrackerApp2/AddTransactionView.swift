import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var description = ""
    @State private var amountText = ""
    @State private var isIncome = true

    var onSave: (Date, String, Double, Bool) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Description", text: $description)
                        .accessibilityIdentifier("transactionDescriptionField")

                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("transactionAmountField")

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("transactionDatePicker")
                }

                Section("Type") {
                    Picker("Type", selection: $isIncome) {
                        Text("Income").tag(true)
                        Text("Expense").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("transactionTypePicker")
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .accessibilityIdentifier("saveTransactionButton")
                }
            }
        }
    }

    private var canSave: Bool {
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let value = Double(amountText), value > 0 else { return false }
        return true
    }

    private func save() {
        guard let value = Double(amountText), value > 0 else { return }
        onSave(date, description.trimmingCharacters(in: .whitespaces), value, isIncome)
        dismiss()
    }
}
