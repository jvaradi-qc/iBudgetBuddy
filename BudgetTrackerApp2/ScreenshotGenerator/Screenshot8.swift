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

struct Screenshot8: View {
    var body: some View {
        ScreenshotTemplate(caption: "Stay on top of recurring bills") {
            AddRecurringView(budgetId: UUID()) { _ in }
        }
    }
}

#Preview {
    Screenshot8()
        .previewDevice("iPad Pro 13-inch (M5) (16GB)")
        .environment(\.horizontalSizeClass, .compact)
}
