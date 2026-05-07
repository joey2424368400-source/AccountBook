import Foundation
import SwiftUI
import SwiftData

@Observable
final class HomeViewModel {
    var transactions: [Transaction] = []
    var accounts: [Account] = []
    var budgets: [Budget] = []
    var recurringTransactions: [RecurringTransaction] = []
    var currentMonthIncome: Double = 0
    var currentMonthExpense: Double = 0
    var currentMonthBalance: Double { currentMonthIncome - currentMonthExpense }
    var totalBalance: Double { accounts.reduce(0) { $0 + $1.balance } }

    func fetchData(modelContext: ModelContext) {
        let now = Date()
        let monthStart = now.startOfMonth
        let monthEnd = now.endOfMonth

        // 本月交易
        let transactionDescriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.date >= monthStart && $0.date <= monthEnd },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        transactions = (try? modelContext.fetch(transactionDescriptor)) ?? []

        // 计算收支
        currentMonthIncome = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        currentMonthExpense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

        // 账户
        let accountDescriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)])
        accounts = (try? modelContext.fetch(accountDescriptor)) ?? []

        // 预算
        let budgetDescriptor = FetchDescriptor<Budget>()
        budgets = (try? modelContext.fetch(budgetDescriptor)) ?? []

        // 近期待扣费
        let sevenDaysLater = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        let recurringDescriptor = FetchDescriptor<RecurringTransaction>(
            predicate: #Predicate { $0.isEnabled == true && $0.nextDueDate <= sevenDaysLater },
            sortBy: [SortDescriptor(\.nextDueDate)]
        )
        recurringTransactions = (try? modelContext.fetch(recurringDescriptor)) ?? []
    }

    func recentTransactions(_ limit: Int = 10) -> [Transaction] {
        Array(transactions.prefix(limit))
    }
}
