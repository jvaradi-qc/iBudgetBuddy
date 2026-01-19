//
//  Screenshot5.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/16/26.
//


import SwiftUI

struct Screenshot5: View {
    var body: some View {
        ScreenshotTemplate(caption: "Your data stays on your device") {
            SettingsView()
        }
    }
}

#Preview {
    Screenshot5()
        .previewDevice("iPhone 15 Pro Max")
}
