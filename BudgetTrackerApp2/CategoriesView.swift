//
//  CategoriesView.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/21/26.
//

import SwiftUI

struct CategoriesView: View {
    @State private var categories: [Category] = []
    @State private var showAdd = false
    @State private var editingCategory: Category?

    var body: some View {
        List {

            // MARK: - Active Categories
            let active = categories.filter { $0.isActive }
            if !active.isEmpty {
                Section("Active Categories") {
                    ForEach(active) { cat in
                        HStack {
                            Text(cat.name)
                            Spacer()
                            Circle()
                                .fill(cat.color)
                                .frame(width: 12, height: 12)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = cat
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { i in
                            let cat = active[i]
                            Database.shared.deactivateCategory(id: cat.id)
                        }
                        load()
                    }
                }
            }

            // MARK: - Inactive Categories
            let inactive = categories.filter { !$0.isActive }
            if !inactive.isEmpty {
                Section("Inactive Categories") {
                    ForEach(inactive) { cat in
                        HStack {
                            Text(cat.name)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Reactivate") {
                                Database.shared.reactivateCategory(id: cat.id)
                                load()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = cat
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear { load() }
        .sheet(isPresented: $showAdd) {
            AddCategoryView {
                load()
            }
        }
        .sheet(item: $editingCategory) { cat in
            EditCategoryView(category: cat) {
                load()
            }
        }
    }

    private func load() {
        categories = Database.shared.fetchCategories()
    }
}

