import Foundation

// MARK: - Budget

struct Budget: Identifiable, Equatable {
    let id: UUID
    let name: String
}

// MARK: - Category

struct Category: Identifiable, Equatable {
    let id: UUID
    var name: String
    var type: CategoryType
    var colorHex: String?
    var iconName: String?
    var isActive: Bool = true
}



enum CategoryType: String, Codable, CaseIterable {
    case income
    case expense
}

// MARK: - Core models

struct Transaction: Identifiable {
    let id: UUID
    let budgetId: UUID

    // Editable fields
    var date: Date
    var description: String
    var amount: Double
    var isIncome: Bool
    var categoryId: UUID?

    // Recurring linkage (runtime only)
    var isRecurringInstance: Bool
    var recurringRuleId: UUID?
}



struct RecurringTransaction: Identifiable {
    let id: UUID
    let budgetId: UUID

    // Editable fields
    var description: String
    var amount: Double
    var isIncome: Bool
    var frequency: Frequency
    var nextRunDate: Date
    var categoryId: UUID?
    var isActive: Bool
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

