//
//  Screenshot1.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/18/26.
//


//
//  Screenshot1.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/16/26.
//


import SwiftUI

struct Screenshot9: View {
    var body: some View {
        ScreenshotTemplate(caption: "Create budgets in seconds") {
            AddBudgetView { _ in }
        }
    }
}

#Preview {
    Screenshot9()
        .previewDevice("iPad Pro 13-inch (M5) (16GB)")
        .environment(\.horizontalSizeClass, .compact)
}
