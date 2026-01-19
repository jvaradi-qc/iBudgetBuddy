//
//  Screenshot4.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/16/26.
//


import SwiftUI

struct Screenshot4: View {
    var body: some View {
        ScreenshotTemplate(caption: "Create budgets in seconds") {
            AddBudgetView { _ in }
        }
    }
}

#Preview {
    Screenshot4()
        .previewDevice("iPhone 15 Pro Max")
}
