import Foundation

enum ReportTab: CaseIterable {
    case summary
    case categories
    case trends

    var title: String {
        switch self {
        case .summary: return "Summary"
        case .categories: return "Categories"
        case .trends: return "Trends"
        }
    }
}
