import Foundation

// MARK: - Budget

struct Budget: Identifiable, Equatable {
    let id: UUID
    let name: String
}

// MARK: - Core models

struct Transaction: Identifiable {
    let id: UUID
    let budgetId: UUID
    let date: Date
    let description: String
    let amount: Double   // positive = income, negative = expense
    let isIncome: Bool
}

struct RecurringTransaction: Identifiable {
    let id: UUID
    let budgetId: UUID
    let description: String
    let amount: Double   // positive number; sign handled by isIncome
    let isIncome: Bool
    let frequency: Frequency
    var nextRunDate: Date
}

// MARK: - Frequency

enum Frequency: String, CaseIterable {
    case daily
    case weekly
    case biweekly
    case monthly
    case yearly
}

extension Frequency {
    func nextDate(after date: Date) -> Date {
        var components = DateComponents()
        switch self {
        case .daily:
            components.day = 1
        case .weekly:
            components.day = 7
        case .biweekly:
            components.day = 14
        case .monthly:
            components.month = 1
        case .yearly:
            components.year = 1
        }
        return Calendar.current.date(byAdding: components, to: date) ?? date
    }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}
