import SwiftUI

struct AddBudgetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""

    var onSave: (Budget) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Budget") {
                    TextField("Budget name", text: $name)
                        .accessibilityIdentifier("budgetNameField")
                }
            }
            .navigationTitle("New Budget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("saveBudgetButton")
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let budget = Budget(id: UUID(), name: trimmed)
        onSave(budget)
        dismiss()
    }
}

