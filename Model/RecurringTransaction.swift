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
    // 利息相关
    var interestRate: Double?       // 年利率 (0.18 = 18%), nil = 无利息
    var interestTypeRaw: String?    // InterestType
    var principal: Double?          // 剩余本金
    var totalPeriods: Int?          // 总期数
    var currentPeriod: Int          // 当前期数
    @Relationship(deleteRule: .cascade, inverse: \Transaction.recurringTransaction) var generatedTransactions: [Transaction]?

    var interestType: InterestType {
        get { InterestType(rawValue: interestTypeRaw ?? "") ?? .none }
        set { interestTypeRaw = newValue.rawValue }
    }

    var hasInterest: Bool {
        interestRate != nil && interestRate! > 0 && interestType != .none
    }

    var currentPeriodInterest: Double {
        guard hasInterest, let principal = principal, let rate = interestRate, let total = totalPeriods else { return 0 }
        return InterestCalculator.currentPeriodInterest(
            type: interestType,
            principal: principal,
            annualRate: rate,
            currentPeriod: currentPeriod,
            totalPeriods: total
        )
    }

    var totalPaymentThisPeriod: Double {
        amount + currentPeriodInterest
    }

    /// 还款计划明细 (用于利息计算器视图)
    var amortizationPlan: [InterestResult] {
        guard hasInterest, let principal = principal, let rate = interestRate, let total = totalPeriods else { return [] }
        return InterestCalculator.calculate(type: interestType, principal: principal, annualRate: rate, totalPeriods: total)
    }

    /// 当前期的还款计划行
    var interestResultForCurrentPeriod: InterestResult? {
        let plan = amortizationPlan
        let idx = min(currentPeriod - 1, plan.count - 1)
        return idx >= 0 && idx < plan.count ? plan[idx] : nil
    }

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
        account: Account? = nil,
        interestRate: Double? = nil,
        interestType: InterestType = .none,
        principal: Double? = nil,
        totalPeriods: Int? = nil,
        currentPeriod: Int = 1
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
        self.interestRate = interestRate
        self.interestTypeRaw = interestType.rawValue
        self.principal = principal
        self.totalPeriods = totalPeriods
        self.currentPeriod = currentPeriod
        self.generatedTransactions = []
    }
}
