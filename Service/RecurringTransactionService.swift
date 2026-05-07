import Foundation
import SwiftData

enum RecurringTransactionService {
    static func processRecurringTransactions(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<RecurringTransaction>(
            predicate: #Predicate { $0.isEnabled == true }
        )
        guard let recurringItems = try? modelContext.fetch(descriptor) else { return }

        let now = Date()
        for item in recurringItems where item.nextDueDate <= now {
            createTransaction(for: item, modelContext: modelContext)
            advanceNextDueDate(for: item)
        }
        try? modelContext.save()
    }

    private static func createTransaction(for recurring: RecurringTransaction, modelContext: ModelContext) {
        let interest = recurring.currentPeriodInterest
        let totalAmount = recurring.amount + interest

        var note = "自动扣费: \(recurring.name)"
        if interest > 0 {
            note += " (本金: \(recurring.amount.currencyFormatted), 利息: \(interest.currencyFormatted))"
        }

        let transaction = Transaction(
            amount: totalAmount,
            note: note,
            date: recurring.nextDueDate,
            type: .expense,
            category: recurring.category,
            account: recurring.account
        )
        transaction.recurringTransaction = recurring
        modelContext.insert(transaction)
        recurring.generatedTransactions?.append(transaction)

        // 如有利息, 更新剩余本金
        if recurring.hasInterest, let plan = recurring.interestResultForCurrentPeriod {
            recurring.principal = plan.remainingPrincipal
        }
    }

    private static func advanceNextDueDate(for recurring: RecurringTransaction) {
        let calendar = Calendar.current
        switch recurring.cycle {
        case .weekly:
            recurring.nextDueDate = calendar.date(byAdding: .day, value: 7, to: recurring.nextDueDate) ?? recurring.nextDueDate
        case .monthly:
            recurring.nextDueDate = calendar.date(byAdding: .month, value: 1, to: recurring.nextDueDate) ?? recurring.nextDueDate
        case .yearly:
            recurring.nextDueDate = calendar.date(byAdding: .year, value: 1, to: recurring.nextDueDate) ?? recurring.nextDueDate
        }

        // 推进还款期数
        if recurring.hasInterest {
            recurring.currentPeriod += 1
            // 最后一期后自动停止
            if let total = recurring.totalPeriods, recurring.currentPeriod > total {
                recurring.isEnabled = false
            }
        }
    }
}
