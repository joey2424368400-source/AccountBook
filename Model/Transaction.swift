import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"

    var displayName: String {
        switch self {
        case .income: return "收入"
        case .expense: return "支出"
        }
    }
}

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var note: String
    var date: Date
    var typeRaw: String
    var createdAt: Date
    var category: Category?
    var account: Account?
    var recurringTransaction: RecurringTransaction?

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    init(
        amount: Double,
        note: String = "",
        date: Date = Date(),
        type: TransactionType = .expense,
        category: Category? = nil,
        account: Account? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.note = note
        self.date = date
        self.typeRaw = type.rawValue
        self.createdAt = Date()
        self.category = category
        self.account = account
    }
}
