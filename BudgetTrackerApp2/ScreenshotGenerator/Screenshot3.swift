//
//  Screenshot3.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/16/26.
//


import SwiftUI

struct Screenshot3: View {
    var body: some View {
        ScreenshotTemplate(caption: "Stay on top of recurring bills") {
            AddRecurringView(budgetId: UUID()) { _ in }
        }
    }
}

#Preview {
    Screenshot3()
        .previewDevice("iPhone 15 Pro Max")
}
