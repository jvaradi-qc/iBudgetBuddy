import SwiftUI

struct AddRecurringView: View {
    @Environment(\.dismiss) private var dismiss

    let budgetId: UUID

    @State private var description = ""
    @State private var amountText = ""
    @State private var isIncome = true
    @State private var frequency: Frequency = .monthly
    @State private var firstRunDate = Date()
    @State private var selectedCategoryId: UUID? = nil

    @State private var categories: [Category] = []

    var onSave: (RecurringTransaction) -> Void

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Details
                Section("Details") {
                    TextField("Description", text: $description)
                        .accessibilityIdentifier("recurringDescriptionField")

                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("recurringAmountField")
                }

                // MARK: - Type
                Section("Type") {
                    Picker("Type", selection: $isIncome) {
                        Text("Income").tag(true)
                        Text("Expense").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("recurringTypePicker")
                    .onChange(of: isIncome) { _ in
                        reloadCategories()
                        selectedCategoryId = nil
                    }
                }

                // MARK: - Frequency
                Section("Frequency") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Frequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    .accessibilityIdentifier("recurringFrequencyPicker")
                }

                // MARK: - First Occurrence
                Section("First occurrence") {
                    DatePicker("Start date", selection: $firstRunDate, displayedComponents: .date)
                        .accessibilityIdentifier("recurringStartDatePicker")
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
                    .accessibilityIdentifier("recurringCategoryPicker")
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
            .onAppear {
                reloadCategories()
            }
        }
    }

    // MARK: - Filtered categories by type
    private var filteredCategories: [Category] {
        categories.filter { $0.type == (isIncome ? .income : .expense) }
    }

    // MARK: - Validation
    private var canSave: Bool {
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let value = Double(amountText), value > 0 else { return false }
        return true
    }

    // MARK: - Save
    private func save() {
        guard let value = Double(amountText), value > 0 else { return }

        // MARK: - Normalize sign based on income/expense
        let normalizedAmount = isIncome ? abs(value) : -abs(value)

        let recurring = RecurringTransaction(
            id: UUID(),
            budgetId: budgetId,
            description: description.trimmingCharacters(in: .whitespaces),
            amount: normalizedAmount,
            isIncome: isIncome,
            frequency: frequency,
            nextRunDate: firstRunDate,
            categoryId: selectedCategoryId,
            isActive: true   // NEW
        )

        onSave(recurring)
        dismiss()
    }

    // MARK: - Helpers
    private func reloadCategories() {
        categories = Database.shared.fetchActiveCategories()
    }

    private func categoryName(for id: UUID?) -> String {
        guard let id else { return "None" }
        return categories.first(where: { $0.id == id })?.name ?? "None"
    }
}

