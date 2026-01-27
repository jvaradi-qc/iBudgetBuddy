import SwiftUI

struct RecurringRow: View {
    let recurring: RecurringTransaction

    private var category: Category? {
        Database.shared.fetchCategory(id: recurring.categoryId)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recurring.description)
                    .font(.body)

                if let category {
                    CategoryBadge(category: category)
                }

                Text(recurring.frequency.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(CurrencyFormatter.string(from: recurring.amount))
                .foregroundColor(recurring.amount >= 0 ? .green : .red)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Currency Formatter
    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

