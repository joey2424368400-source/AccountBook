import Foundation
import SwiftData

enum BudgetPeriod: String, Codable, CaseIterable {
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

@Model
final class Budget {
    var id: UUID
    var amount: Double
    var periodRaw: String
    var startDate: Date
    var category: Category?
    var cycleStartDay: Int = 1

    var period: BudgetPeriod {
        get { BudgetPeriod(rawValue: periodRaw) ?? .monthly }
        set { periodRaw = newValue.rawValue }
    }

    var currentCycleRange: Range<Date> {
        let calendar = Calendar.current
        let now = Date()
        switch period {
        case .weekly:
            let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return start..<now
        case .monthly:
            let components = calendar.dateComponents([.year, .month, .day], from: now)
            let today = components.day ?? 1
            let day = min(max(cycleStartDay, 1), 28)
            let thisMonthAnchor = calendar.date(from: DateComponents(year: components.year, month: components.month, day: day)) ?? now
            if today >= day {
                let nextAnchor = calendar.date(byAdding: .month, value: 1, to: thisMonthAnchor) ?? now
                return thisMonthAnchor..<nextAnchor
            } else {
                let prevAnchor = calendar.date(byAdding: .month, value: -1, to: thisMonthAnchor) ?? now
                return prevAnchor..<thisMonthAnchor
            }
        case .yearly:
            let start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return start..<now
        }
    }

    var spentAmount: Double {
        guard let category = category else { return 0 }
        let range = currentCycleRange
        return category.transactions?
            .filter { $0.type == .expense && range.contains($0.date) }
            .reduce(0) { $0 + $1.amount } ?? 0
    }

    var remainingAmount: Double { amount - spentAmount }

    var progress: Double {
        guard amount > 0 else { return 0 }
        return min(spentAmount / amount, 1.0)
    }

    init(amount: Double, period: BudgetPeriod = .monthly, startDate: Date = Date(), category: Category? = nil, cycleStartDay: Int = 1) {
        self.id = UUID()
        self.amount = amount
        self.periodRaw = period.rawValue
        self.startDate = startDate
        self.category = category
        self.cycleStartDay = cycleStartDay
    }
}
