//
//  Screenshot2.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/16/26.
//


import SwiftUI

struct Screenshot2: View {
    var body: some View {
        ScreenshotTemplate(caption: "Track expenses with ease") {
            AddTransactionView { _,_,_,_ in }
        }
    }
}

#Preview {
    Screenshot2()
        .previewDevice("iPhone 15 Pro Max")
}
