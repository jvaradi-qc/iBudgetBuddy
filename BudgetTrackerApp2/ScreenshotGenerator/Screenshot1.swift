//
//  Screenshot1.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/16/26.
//


import SwiftUI

struct Screenshot1: View {
    var body: some View {
        ScreenshotTemplate(caption: "See your budget at a glance") {
            ContentView()
        }
    }
}

#Preview {
    Screenshot1()
        .previewDevice("iPhone 15 Pro Max")
}
