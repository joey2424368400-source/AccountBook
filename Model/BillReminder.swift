import Foundation
import SwiftData

enum RepeatCycle: String, Codable, CaseIterable {
    case none = "none"
    case monthly = "monthly"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .none: return "不重复"
        case .monthly: return "每月"
        case .yearly: return "每年"
        }
    }
}

@Model
final class BillReminder {
    var id: UUID
    var name: String
    var amount: Double
    var dueDate: Date
    var repeatCycleRaw: String
    var isEnabled: Bool
    var note: String
    var notificationID: String?

    var repeatCycle: RepeatCycle {
        get { RepeatCycle(rawValue: repeatCycleRaw) ?? .none }
        set { repeatCycleRaw = newValue.rawValue }
    }

    init(name: String, amount: Double, dueDate: Date, repeatCycle: RepeatCycle = .none, isEnabled: Bool = true, note: String = "") {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
        self.repeatCycleRaw = repeatCycle.rawValue
        self.isEnabled = isEnabled
        self.note = note
    }
}
