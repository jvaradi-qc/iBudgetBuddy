//
//  EditCategoryView.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/21/26.
//


import SwiftUI

struct EditCategoryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var type: CategoryType
    @State private var selectedColor: Color
    @State private var iconName: String
    @State private var isActive: Bool

    let category: Category
    var onSave: () -> Void

    init(category: Category, onSave: @escaping () -> Void) {
        self.category = category
        self.onSave = onSave

        _name = State(initialValue: category.name)
        _type = State(initialValue: category.type)
        _selectedColor = State(initialValue: category.color)
        _iconName = State(initialValue: category.iconName ?? "")
        _isActive = State(initialValue: category.isActive)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Category Name", text: $name)

                    Picker("Type", selection: $type) {
                        ForEach(CategoryType.allCases, id: \.self) { t in
                            Text(t.rawValue.capitalized)
                                .tag(t)
                        }
                    }
                }

                Section("Appearance") {
                    ColorPicker("Color", selection: $selectedColor)

                    TextField("Icon Name (optional)", text: $iconName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section("Status") {
                    if isActive {
                        Button(role: .destructive) {
                            deactivate()
                        } label: {
                            Text("Deactivate Category")
                        }
                    } else {
                        Button {
                            reactivate()
                        } label: {
                            Text("Reactivate Category")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Edit Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        let uiColor = UIColor(selectedColor)
        let hex = uiColor.toHex()

        let updated = Category(
            id: category.id,
            name: name.trimmingCharacters(in: .whitespaces),
            type: type,
            colorHex: hex,
            iconName: iconName.isEmpty ? nil : iconName,
            isActive: isActive
        )

        Database.shared.updateCategory(updated)
        onSave()
        dismiss()
    }

    private func deactivate() {
        Database.shared.deactivateCategory(id: category.id)
        isActive = false
        onSave()
        dismiss()
    }

    private func reactivate() {
        Database.shared.reactivateCategory(id: category.id)
        isActive = true
        onSave()
        dismiss()
    }
}
