import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    @State private var showingAddTransaction = false
    @State private var showingAddRecurring = false
    @State private var showingSettings = false

    @State private var editingTransaction: Transaction? = nil
    @State private var editingRecurring: RecurringTransaction? = nil

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if let _ = viewModel.selectedBudget {
                        List {
                            // MARK: - Summary
                            Section("Summary") {
                                HStack {
                                    Text("Income")
                                    Spacer()
                                    Text(currency(viewModel.totalIncome))
                                        .foregroundColor(.green)
                                }

                                HStack {
                                    Text("Expenses")
                                    Spacer()
                                    Text(currency(viewModel.totalExpenses))
                                        .foregroundColor(.red)
                                }

                                HStack {
                                    Text("Net")
                                    Spacer()
                                    Text(currency(viewModel.netAmount))
                                        .foregroundColor(viewModel.netAmount >= 0 ? .green : .red)
                                }
                            }

                            // MARK: - Transactions (merged)
                            Section("Transactions") {
                                ForEach(viewModel.transactions) { tx in
                                    TransactionRow(transaction: tx)
                                        .onTapGesture {
                                            if tx.isRecurringInstance,
                                               let ruleId = tx.recurringRuleId,
                                               let rule = viewModel.recurring.first(where: { $0.id == ruleId }) {
                                                editingRecurring = rule
                                            } else {
                                                editingTransaction = tx
                                            }
                                        }

                                }
                                .onDelete(perform: viewModel.deleteTransaction)
                            }
                        }
                    } else {
                        Text("Please create or select a budget.")
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - Floating Bottom-Right Gear Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                        .accessibilityIdentifier("settingsButton")
                    }
                }
            }
            .navigationTitle("iBudgetBuddy")
            .toolbar {

                // MARK: - Budget Switcher
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(viewModel.budgets) { budget in
                            Button(budget.name) {
                                viewModel.selectBudget(budget)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                            Text(viewModel.selectedBudget?.name ?? "Select Budget")
                        }
                    }
                }

                // MARK: - Add Buttons + Reports Button
                ToolbarItemGroup(placement: .navigationBarTrailing) {

                    // Reports Button
                    if let budget = viewModel.selectedBudget {
                        NavigationLink(destination: ReportsView(budgetId: budget.id)) {
                            Image(systemName: "chart.pie.fill")
                        }
                    }

                    // Add Transaction
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }

                    // Add Recurring
                    Button {
                        showingAddRecurring = true
                    } label: {
                        Image(systemName: "repeat.circle")
                    }
                }
            }

            // MARK: - Edit Transaction Sheet
            .sheet(item: $editingTransaction) { tx in
                TransactionEditWrapperView(
                    transaction: tx,
                    onSave: { updated in
                        viewModel.updateTransaction(updated)
                        editingTransaction = nil
                    },
                    onCancel: {
                        editingTransaction = nil
                    }
                )
            }

            // MARK: - Edit Recurring Sheet
            .sheet(item: $editingRecurring) { item in
                RecurringEditWrapperView(
                    recurring: item,
                    onSave: { updated in
                        viewModel.updateRecurring(updated)
                        editingRecurring = nil
                    },
                    onCancel: {
                        editingRecurring = nil
                    }
                )
            }

            // MARK: - Add Transaction Sheet
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView { date, description, amount, isIncome, categoryId in
                    guard let budgetId = viewModel.selectedBudget?.id else { return }

                    let transaction = Transaction(
                        id: UUID(),
                        budgetId: budgetId,
                        date: date,
                        description: description,
                        amount: amount,
                        isIncome: isIncome,
                        categoryId: categoryId,
                        isRecurringInstance: false,   // NEW
                        recurringRuleId: nil          // NEW
                    )

                    viewModel.addTransaction(transaction)
                }
            }


            // MARK: - Add Recurring Sheet
            .sheet(isPresented: $showingAddRecurring) {
                if let budgetId = viewModel.selectedBudget?.id {
                    AddRecurringView(budgetId: budgetId) { recurring in
                        viewModel.addRecurring(recurring)
                    }
                } else {
                    Text("Please select a budget first.")
                }
            }

            // MARK: - Settings Sheet
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Currency Helper
    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
