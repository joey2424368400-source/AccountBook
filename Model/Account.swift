import Foundation
import SwiftData

enum AccountType: String, Codable, CaseIterable {
    case cash = "cash"
    case bank = "bank"
    case credit = "credit"
    case alipay = "alipay"
    case wechat = "wechat"

    var displayName: String {
        switch self {
        case .cash: return "现金"
        case .bank: return "银行卡"
        case .credit: return "信用卡"
        case .alipay: return "支付宝"
        case .wechat: return "微信"
        }
    }

    var icon: String {
        switch self {
        case .cash: return "yensign.circle.fill"
        case .bank: return "building.columns.fill"
        case .credit: return "creditcard.fill"
        case .alipay: return "a.circle.fill"
        case .wechat: return "message.fill"
        }
    }
}

@Model
final class Account {
    var id: UUID
    var name: String
    var typeRaw: String
    var initialBalance: Double
    var currency: String
    var sortOrder: Int
    @Relationship(deleteRule: .nullify, inverse: \Transaction.account) var transactions: [Transaction]?

    var type: AccountType {
        get { AccountType(rawValue: typeRaw) ?? .cash }
        set { typeRaw = newValue.rawValue }
    }

    var balance: Double {
        guard let transactions = transactions else { return initialBalance }
        let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return initialBalance + income - expense
    }

    init(name: String, type: AccountType, initialBalance: Double = 0, currency: String = "CNY", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.typeRaw = type.rawValue
        self.initialBalance = initialBalance
        self.currency = currency
        self.sortOrder = sortOrder
        self.transactions = []
    }
}
