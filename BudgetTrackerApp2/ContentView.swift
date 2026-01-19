import SwiftUI

struct ContentView: View {
    @StateObject private var vm = BudgetViewModel()

    @State private var showAddTransaction = false
    @State private var showAddRecurring = false
    @State private var showAddBudget = false
    @State private var showSettings = false

    @Environment(\.uiTestMode) private var uiTestMode

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    budgetPickerSection
                    summarySection
                    Divider()

                    if vm.transactions.isEmpty && vm.recurring.isEmpty {
                        emptyState
                    } else {
                        transactionAndRecurringList
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showSettings = true
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if vm.selectedBudgetId != nil {
                            Button {
                                showAddTransaction = true
                            } label: {
                                Label("Add Transaction", systemImage: "plus.circle")
                            }
                            .accessibilityIdentifier("addTransactionMenuItem")

                            Button {
                                showAddRecurring = true
                            } label: {
                                Label("Add Recurring", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .accessibilityIdentifier("addRecurringMenuItem")
                        }

                        Button {
                            showAddBudget = true
                        } label: {
                            Label("Add Budget", systemImage: "folder.badge.plus")
                        }
                        .accessibilityIdentifier("addBudgetMenuItem")

                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                            .accessibilityIdentifier("addMenuButton")
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView { date, desc, amount, isIncome in
                    vm.addTransaction(date: date,
                                      description: desc,
                                      amount: amount,
                                      isIncome: isIncome)
                }
            }
            .sheet(isPresented: $showAddRecurring) {
                AddRecurringView(budgetId: vm.selectedBudgetId ?? UUID()) { recurring in
                    vm.addRecurring(recurring)
                }
            }
            .sheet(isPresented: $showAddBudget) {
                AddBudgetView { budget in
                    vm.addBudget(budget)
                    vm.selectBudget(budget.id)
                }
            }
            .sheet(isPresented: $vm.isPresentingEditTransaction) {
                if let tx = vm.editingTransaction {
                    TransactionEditWrapperView(
                        transaction: tx,
                        onSave: { updated in
                            vm.finishEditing(updatedTransaction: updated)
                        },
                        onCancel: {
                            vm.isPresentingEditTransaction = false
                        }
                    )
                }
            }
            .sheet(isPresented: $vm.isPresentingEditRecurring) {
                if let item = vm.editingRecurring {
                    RecurringEditWrapperView(
                        recurring: item,
                        onSave: { updated in
                            vm.finishEditingRecurring(updated)
                        },
                        onCancel: {
                            vm.isPresentingEditRecurring = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Delete Budget?",
                   isPresented: $vm.showDeleteBudgetAlert) {
                Button("Delete", role: .destructive) {
                    vm.confirmDeleteBudget()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete the budget and all associated transactions and recurring items.")
            }
            .onAppear {
                seedUITestBudgetIfNeeded()
            }
        }
    }

    // MARK: - UI Test Seeding

    private func seedUITestBudgetIfNeeded() {
        guard uiTestMode else { return }
        guard vm.budgets.isEmpty else { return }

        let seeded = Budget(
            id: UUID(),
            name: "UI Test Budget"
        )

        vm.addBudget(seeded)
        vm.selectBudget(seeded.id)

    }

    // MARK: - Sections

    private var budgetPickerSection: some View {
        HStack {
            Text("Budget:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            budgetPicker
        }
        .padding([.top, .horizontal])
    }

    @ViewBuilder
    private var budgetPicker: some View {
        if uiTestMode {
            Picker("Budget", selection: $vm.selectedBudgetId) {
                ForEach(vm.budgets) { budget in
                    Text(budget.name)
                        .tag(Optional(budget.id))
                        .accessibilityIdentifier("budgetPickerOption_\(budget.name)")
                }
            }
            .pickerStyle(.inline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("budgetPicker")
            .onChange(of: vm.selectedBudgetId) { newValue in
                if let id = newValue {
                    vm.selectBudget(id)
                }
            }
        } else {
            Picker("Budget", selection: $vm.selectedBudgetId) {
                ForEach(vm.budgets) { budget in
                    Text(budget.name)
                        .tag(Optional(budget.id))
                        .accessibilityIdentifier("budgetPickerOption_\(budget.name)")
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("budgetPicker")
            .onChange(of: vm.selectedBudgetId) { newValue in
                if let id = newValue {
                    vm.selectBudget(id)
                }
            }
        }
    }

    private var summarySection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Income")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currency(vm.totalIncome))
                        .font(.headline)
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Expenses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currency(vm.totalExpense))
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }

            Divider()

            HStack {
                Text(vm.net >= 0 ? "Surplus" : "Deficit")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(currency(abs(vm.net)))
                    .font(.title2.bold())
                    .foregroundColor(vm.net >= 0 ? .green : .red)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var transactionAndRecurringList: some View {
        List {
            Section(header: Text("Budgets")) {
                ForEach(vm.budgets) { budget in
                    HStack {
                        Text(budget.name)
                        Spacer()
                        if vm.selectedBudgetId == budget.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("budgetRow_\(budget.name)")
                    .onTapGesture {
                        vm.selectBudget(budget.id)
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        let budget = vm.budgets[index]
                        vm.requestDeleteBudget(budget)
                    }
                }
            }

            if !vm.transactions.isEmpty {
                Section(header: Text("Transactions")) {
                    ForEach(vm.transactions) { t in
                        Button {
                            vm.startEditing(t)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(t.description)
                                        .font(.body)
                                    Text(dateString(t.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text(amountString(t.amount))
                                    .font(.body.bold())
                                    .foregroundColor(t.amount > 0 ? .green : .red)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("transactionRow_\(t.description)")
                    }
                    .onDelete(perform: vm.deleteTransactions)
                }
            }

            if !vm.recurring.isEmpty {
                Section(header: Text("Recurring Transactions")) {
                    ForEach(vm.recurring) { r in
                        Button {
                            vm.startEditingRecurring(r)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(r.description)
                                        .font(.body)
                                    Text("Next: \(dateString(r.nextRunDate))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text(amountString(r.isIncome ? r.amount : -r.amount))
                                    .font(.body.bold())
                                    .foregroundColor(r.isIncome ? .green : .red)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("recurringRow_\(r.description)")
                    }
                    .onDelete { offsets in
                        offsets.map { vm.recurring[$0] }.forEach(vm.deleteRecurring)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No transactions yet")
                .font(.headline)
            Text("Use the + menu to add income, expenses, or recurring items for this budget.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Helpers

    private func currency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        return f.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func amountString(_ amount: Double) -> String {
        let sign = amount >= 0 ? "+" : "-"
        let absVal = abs(amount)
        let formatted = currency(absVal)
        let clean = formatted.replacingOccurrences(of: "-", with: "")
        return "\(sign)\(clean)"
    }
}
