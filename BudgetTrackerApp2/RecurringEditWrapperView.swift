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

    init(recurring: RecurringTransaction,
         onSave: @escaping (RecurringTransaction) -> Void,
         onCancel: @escaping () -> Void) {

        self.recurring = recurring
        self.onSave = onSave
        self.onCancel = onCancel

        _description = State(initialValue: recurring.description)
        _amountString = State(initialValue: String(recurring.amount))
        _isIncome = State(initialValue: recurring.isIncome)
        _frequency = State(initialValue: recurring.frequency)
        _nextRunDate = State(initialValue: recurring.nextRunDate)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Edit Recurring Transaction") {
                    TextField("Description", text: $description)
                    TextField("Amount", text: $amountString)
                        .keyboardType(.decimalPad)
                    Toggle("Income", isOn: $isIncome)

                    Picker("Frequency", selection: $frequency) {
                        Text("Daily").tag(Frequency.daily)
                        Text("Weekly").tag(Frequency.weekly)
                        Text("Monthly").tag(Frequency.monthly)
                        Text("Yearly").tag(Frequency.yearly)
                    }

                    DatePicker("Next Run Date", selection: $nextRunDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Recurring")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount = Double(amountString) else { return }

                        let updated = RecurringTransaction(
                            id: recurring.id,
                            budgetId: recurring.budgetId,
                            description: description,
                            amount: amount,
                            isIncome: isIncome,
                            frequency: frequency,
                            nextRunDate: nextRunDate
                        )

                        onSave(updated)
                    }
                    .disabled(description.isEmpty || Double(amountString) == nil)
                }
            }
        }
    }
}
