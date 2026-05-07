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
        let transaction = Transaction(
            amount: recurring.amount,
            note: "自动扣费: \(recurring.name)",
            date: recurring.nextDueDate,
            type: .expense,
            category: recurring.category,
            account: recurring.account
        )
        transaction.recurringTransaction = recurring
        modelContext.insert(transaction)
        recurring.generatedTransactions?.append(transaction)
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
    }
}
