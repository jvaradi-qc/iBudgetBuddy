import SwiftUI

struct AddRecurringView: View {
    @Environment(\.dismiss) private var dismiss

    let budgetId: UUID

    @State private var description = ""
    @State private var amountText = ""
    @State private var isIncome = true
    @State private var frequency: Frequency = .monthly
    @State private var firstRunDate = Date()

    var onSave: (RecurringTransaction) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Description", text: $description)
                        .accessibilityIdentifier("recurringDescriptionField")

                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("recurringAmountField")
                }

                Section("Type") {
                    Picker("Type", selection: $isIncome) {
                        Text("Income").tag(true)
                        Text("Expense").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("recurringTypePicker")
                }

                Section("Frequency") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Frequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    .accessibilityIdentifier("recurringFrequencyPicker")
                }

                Section("First occurrence") {
                    DatePicker("Start date", selection: $firstRunDate, displayedComponents: .date)
                        .accessibilityIdentifier("recurringStartDatePicker")
                }
            }
            .navigationTitle("Add Recurring")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .accessibilityIdentifier("saveRecurringButton")
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
        let recurring = RecurringTransaction(
            id: UUID(),
            budgetId: budgetId,
            description: description.trimmingCharacters(in: .whitespaces),
            amount: value,
            isIncome: isIncome,
            frequency: frequency,
            nextRunDate: firstRunDate
        )
        onSave(recurring)
        dismiss()
    }
}

