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

struct Screenshot10: View {
    var body: some View {
        ScreenshotTemplate(caption: "Your data stays on your device") {
            SettingsView()
        }
    }
}

#Preview {
    Screenshot10()
        .previewDevice("iPad Pro 13-inch (M5) (16GB)")
        .environment(\.horizontalSizeClass, .compact)
}
