//
//  CategoryTotal.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/26/26.
//


import Foundation

struct CategoryTotal: Identifiable {
    let id = UUID()
    let categoryId: UUID
    let total: Double
}
