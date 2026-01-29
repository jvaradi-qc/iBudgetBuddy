//
//  CategorySelectionView.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/21/26.
//

import SwiftUI

struct CategorySelectionView: View {
    let categories: [Category]          // already active-only
    let isIncome: Bool
    @Binding var selectedCategoryId: UUID?

    var body: some View {
        List(viewModel.filteredCategories) { category in
            HStack(spacing: 12) {

                // Category color circle
                Circle()
                    .fill(category.color)
                    .frame(width: 14, height: 14)

                Text(category.name)

                Spacer()

                // Checkmark for selected category
                if selectedCategoryId == category.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedCategoryId = category.id
            }
        }
        .navigationTitle("Select Category")
    }

    // Filter by income/expense type
    private var viewModel: CategorySelectionViewModel {
        CategorySelectionViewModel(categories: categories, isIncome: isIncome)
    }

}

