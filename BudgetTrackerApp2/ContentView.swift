import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    @State private var showingAddTransaction = false
    @State private var showingAddRecurring = false
    @State private var showingAddBudget = false
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

                            // MARK: - Transactions
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

                // MARK: - Floating Gear Button
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

                // MARK: - Calendar Picker
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Month") {
                            ForEach(1...12, id: \.self) { m in
                                Button(monthName(m)) {
                                    viewModel.selectedMonth = m
                                    if let id = viewModel.selectedBudget?.id {
                                        viewModel.loadData(for: id)
                                    }
                                }
                            }
                        }

                        Section("Year") {
                            ForEach(2024...2030, id: \.self) { y in
                                Button("\(y)") {
                                    viewModel.selectedYear = y
                                    if let id = viewModel.selectedBudget?.id {
                                        viewModel.loadData(for: id)
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "calendar")
                    }
                }

                // MARK: - Reports Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let budget = viewModel.selectedBudget {
                        NavigationLink(destination: ReportsView(budgetId: budget.id)) {
                            Image(systemName: "chart.pie.fill")
                        }
                    }
                }

                // MARK: - Add Menu
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Transaction") {
                            showingAddTransaction = true
                        }

                        Button("Add Recurring") {
                            showingAddRecurring = true
                        }

                        Button("Add Budget") {
                            showingAddBudget = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            // MARK: - Sheets
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
                        isRecurringInstance: false,
                        recurringRuleId: nil
                    )

                    viewModel.addTransaction(transaction)
                }
            }

            .sheet(isPresented: $showingAddRecurring) {
                if let budgetId = viewModel.selectedBudget?.id {
                    AddRecurringView(budgetId: budgetId) { recurring in
                        viewModel.addRecurring(recurring)
                    }
                } else {
                    Text("Please select a budget first.")
                }
            }

            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView { newBudget in
                    // Persist to database
                    Database.shared.insertBudget(newBudget)

                    // Update view model
                    viewModel.budgets.append(newBudget)
                    viewModel.selectBudget(newBudget)
                    viewModel.loadData(for: newBudget.id)
                }
            }


            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Currency Formatter
    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    // MARK: - Month Name Helper
    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        return formatter.monthSymbols[month - 1]
    }
}
