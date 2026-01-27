//
//  CategoryBadge.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/21/26.
//


import SwiftUI

struct CategoryBadge: View {
    let category: Category

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(category.color)
                .frame(width: 10, height: 10)

            Text(category.name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
