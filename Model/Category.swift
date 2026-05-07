import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var typeRaw: String
    var sortOrder: Int
    @Relationship(deleteRule: .cascade, inverse: \Transaction.category) var transactions: [Transaction]?

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    init(name: String, icon: String, colorHex: String, type: TransactionType, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.typeRaw = type.rawValue
        self.sortOrder = sortOrder
        self.transactions = []
    }
}
