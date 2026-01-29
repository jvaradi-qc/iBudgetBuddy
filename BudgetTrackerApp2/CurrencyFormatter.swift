//
//  CurrencyFormatter.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/24/26.
//


import Foundation

enum CurrencyFormatter {
    
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()
    
    /// Formats a Double using standard currency rules.
    /// Income stays positive, expenses stay negative.
    static func string(from value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
