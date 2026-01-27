//
//  TrendDataPoint.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/26/26.
//


import Foundation

struct TrendDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let net: Double
}
