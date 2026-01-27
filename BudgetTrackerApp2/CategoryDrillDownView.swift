import SwiftUI

struct CategoryDrillDownView: View {
    let category: Category
    @ObservedObject var viewModel: ReportsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            HStack(spacing: 12) {
                CategoryBadge(category: category)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading) {
                    Text(category.name)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Transactions for \(monthName(viewModel.month)) \(viewModel.year)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            // Transactions List
            List {
                ForEach(viewModel.transactionsForCategory(category.id)) { tx in
                    NavigationLink {
                        TransactionEditWrapperView(
                            transaction: tx,
                            onSave: { updated in
                                Database.shared.updateTransaction(updated)
                                viewModel.reload()
                            },
                            onCancel: {}
                        )
                    } label: {
                        TransactionRow(transaction: tx)
                    }
                }
                .onDelete { offsets in
                    let filteredTxs = viewModel.transactionsForCategory(category.id)

                    for index in offsets {
                        let tx = filteredTxs[index]
                        Database.shared.deleteTransaction(id: tx.id)
                    }

                    viewModel.reload()
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func monthName(_ month: Int) -> String {
        Calendar.current.monthSymbols[month - 1]
    }
}

