//
//  CategorySelectionViewModel.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/22/26.
//


import Foundation

struct CategorySelectionViewModel {

    let categories: [Category]
    let isIncome: Bool

    var filteredCategories: [Category] {
        categories.filter { $0.type == (isIncome ? .income : .expense) }
    }
}
