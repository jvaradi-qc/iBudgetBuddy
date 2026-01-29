import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    private var category: Category? {
        Database.shared.fetchCategory(id: transaction.categoryId)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.body)

                if let category {
                    CategoryBadge(category: category)
                        .id(category.id)   // ✅ force refresh when category changes
                }
            }

            Spacer()

            Text(CurrencyFormatter.string(from: transaction.amount))
                .foregroundColor(transaction.amount >= 0 ? .green : .red)
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

