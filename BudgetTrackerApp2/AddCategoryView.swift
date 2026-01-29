import SwiftUI

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var type: CategoryType = .expense
    @State private var selectedColor: Color = .gray
    @State private var iconName: String = ""

    var onSave: () -> Void

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
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveCategory() {
        // Convert SwiftUI Color -> UIColor -> hex
        let uiColor = UIColor(selectedColor)
        let hex = uiColor.toHex()

        let newCategory = Category(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            type: type,
            colorHex: hex,
            iconName: iconName.isEmpty ? nil : iconName,
            isActive: true
        )

        Database.shared.insertCategory(newCategory)
        onSave()
        dismiss()
    }
}
