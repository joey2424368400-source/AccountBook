import Foundation
import SwiftData

enum RecurringCycle: String, Codable, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .weekly: return "每周"
        case .monthly: return "每月"
        case .yearly: return "每年"
        }
    }
}

enum RecurringType: String, Codable, CaseIterable {
    case creditCard = "creditCard"
    case loan = "loan"
    case subscription = "subscription"
    case other = "other"

    var displayName: String {
        switch self {
        case .creditCard: return "信用卡"
        case .loan: return "贷款"
        case .subscription: return "订阅会员"
        case .other: return "其他"
        }
    }

    var icon: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .loan: return "house.fill"
        case .subscription: return "repeat.circle.fill"
        case .other: return "arrow.triangle.2.circlepath"
        }
    }
}

@Model
final class RecurringTransaction {
    var id: UUID
    var name: String
    var amount: Double
    var typeRaw: String
    var cycleRaw: String
    var nextDueDate: Date
    var isEnabled: Bool
    var note: String
    var createdAt: Date
    var category: Category?
    var account: Account?
    @Relationship(deleteRule: .cascade, inverse: \Transaction.recurringTransaction) var generatedTransactions: [Transaction]?

    var type: RecurringType {
        get { RecurringType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var cycle: RecurringCycle {
        get { RecurringCycle(rawValue: cycleRaw) ?? .monthly }
        set { cycleRaw = newValue.rawValue }
    }

    init(
        name: String,
        amount: Double,
        type: RecurringType = .subscription,
        cycle: RecurringCycle = .monthly,
        nextDueDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
        isEnabled: Bool = true,
        note: String = "",
        category: Category? = nil,
        account: Account? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.typeRaw = type.rawValue
        self.cycleRaw = cycle.rawValue
        self.nextDueDate = nextDueDate
        self.isEnabled = isEnabled
        self.note = note
        self.createdAt = Date()
        self.category = category
        self.account = account
        self.generatedTransactions = []
    }
}
