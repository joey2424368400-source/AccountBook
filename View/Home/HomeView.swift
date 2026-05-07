import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var showAddSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 本月收支概览
                monthSummarySection

                // 账户总余额
                balanceSection

                // 预算进度
                budgetSection

                // 近期待扣费
                if !viewModel.recurringTransactions.isEmpty {
                    upcomingRecurringSection
                }

                // 最近交易
                recentTransactionsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("首页")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            TransactionEditView()
        }
        .onAppear { viewModel.fetchData(modelContext: modelContext) }
        .onChange(of: showAddSheet) { _, newValue in
            if !newValue { viewModel.fetchData(modelContext: modelContext) }
        }
        .refreshable { viewModel.fetchData(modelContext: modelContext) }
    }

    // MARK: - 本月收支概览

    private var monthSummarySection: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "本月收入",
                amount: viewModel.currentMonthIncome,
                color: .green,
                icon: "arrow.down.circle.fill"
            )
            SummaryCard(
                title: "本月支出",
                amount: viewModel.currentMonthExpense,
                color: .red,
                icon: "arrow.up.circle.fill"
            )
            SummaryCard(
                title: "本月结余",
                amount: viewModel.currentMonthBalance,
                color: viewModel.currentMonthBalance >= 0 ? .blue : .red,
                icon: "equal.circle.fill"
            )
        }
    }

    // MARK: - 账户总余额

    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("账户总余额")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text(viewModel.totalBalance.currencyFormatted)
                .font(.system(size: 30, weight: .bold, design: .rounded))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.accounts) { account in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: account.type.icon)
                                    .font(.system(size: 12))
                                Text(account.name)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.secondary)
                            Text((viewModel.accountBalances[account.persistentModelID] ?? 0).currencyFormatted)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - 预算进度

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("预算")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            if viewModel.budgets.isEmpty {
                NavigationLink(destination: BudgetManageView()) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("设置预算")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                }
            } else {
                ForEach(viewModel.budgets) { budget in
                    BudgetProgressRow(budget: budget)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - 近期待扣费

    private var upcomingRecurringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("近期待扣费")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            ForEach(viewModel.recurringTransactions) { item in
                HStack {
                    Image(systemName: item.type.icon)
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.system(size: 14, weight: .medium))
                        Text("\(item.nextDueDate.monthAndYear) 自动扣费")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(item.amount.currencyFormatted)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - 最近交易

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近交易")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                NavigationLink(destination: TransactionListView()) {
                    Text("查看全部")
                        .font(.system(size: 13))
                }
            }

            if viewModel.transactions.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("还没有交易记录")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTransactions()) { transaction in
                        NavigationLink(destination: TransactionEditView(transaction: transaction)) {
                            TransactionRow(transaction: transaction)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if transaction.id != viewModel.recentTransactions().last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - 预算进度行

struct BudgetProgressRow: View {
    let budget: Budget

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    if let category = budget.category {
                        CategoryIcon(icon: category.icon, colorHex: category.colorHex, size: 24)
                        Text(category.name)
                    } else {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                        Text("总预算")
                    }
                }
                .font(.system(size: 13))

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(budget.spentAmount.shortFormatted) / \(budget.amount.currencyFormatted)")
                        .font(.system(size: 13, design: .rounded))
                    Text("剩余 \(budget.remainingAmount.currencyFormatted)")
                        .font(.system(size: 11))
                        .foregroundColor(budget.remainingAmount < 0 ? .red : .secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    Capsule()
                        .fill(budget.remainingAmount < 0 ? Color.red : Color.blue)
                        .frame(width: geo.size.width * budget.progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
