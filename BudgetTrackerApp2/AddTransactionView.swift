import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var description = ""
    @State private var amountText = ""
    @State private var isIncome = true
    @State private var selectedCategoryId: UUID? = nil

    // Updated to include categoryId
    var onSave: (Date, String, Double, Bool, UUID?) -> Void

    // Load categories once when the view appears
    @State private var categories: [Category] = []

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Details
                Section("Details") {
                    TextField("Description", text: $description)
                        .accessibilityIdentifier("transactionDescriptionField")

                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("transactionAmountField")

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("transactionDatePicker")
                }

                // MARK: - Type
                Section("Type") {
                    Picker("Type", selection: $isIncome) {
                        Text("Income").tag(true)
                        Text("Expense").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("transactionTypePicker")
                    .onChange(of: isIncome) { _ in
                        reloadCategories()
                        selectedCategoryId = nil
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
                    .accessibilityIdentifier("transactionCategoryPicker")
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
            .onAppear {
                reloadCategories()
            }
        }
    }

    // MARK: - Computed filtered list
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

        onSave(
            date,
            description.trimmingCharacters(in: .whitespaces),
            normalizedAmount,
            isIncome,
            selectedCategoryId
        )

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

