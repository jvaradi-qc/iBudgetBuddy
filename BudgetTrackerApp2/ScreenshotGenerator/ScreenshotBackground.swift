//
//  ScreenshotBackground.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/16/26.
//


import SwiftUI

struct ScreenshotBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "#6A5AF9"),
                Color(hex: "#A18CFF")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
