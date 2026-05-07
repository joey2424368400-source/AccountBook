import Foundation
import SwiftData

enum SeedData {
    static func seed(modelContext: ModelContext) {
        // 默认支出分类
        let expenseCategories: [(name: String, icon: String, color: String)] = [
            ("餐饮", "fork.knife", "#FF6B6B"),
            ("交通", "car.fill", "#4ECDC4"),
            ("购物", "bag.fill", "#FFD93D"),
            ("娱乐", "gamecontroller.fill", "#6C5CE7"),
            ("居住", "house.fill", "#A8E6CF"),
            ("通讯", "phone.fill", "#74B9FF"),
            ("医疗", "cross.case.fill", "#FF8A5C"),
            ("教育", "book.fill", "#B794F4"),
            ("人情", "heart.fill", "#FD79A8"),
            ("日用", "basket.fill", "#FDCB6E"),
            ("服饰", "tshirt.fill", "#E17055"),
            ("其他", "ellipsis.circle.fill", "#B2BEC3"),
        ]

        // 默认收入分类
        let incomeCategories: [(name: String, icon: String, color: String)] = [
            ("工资", "banknote.fill", "#00B894"),
            ("奖金", "gift.fill", "#FDCB6E"),
            ("投资", "chart.line.uptrend.xyaxis", "#0984E3"),
            ("兼职", "briefcase.fill", "#6C5CE7"),
            ("退款", "arrow.uturn.backward.circle.fill", "#74B9FF"),
            ("其他收入", "plus.circle.fill", "#B2BEC3"),
        ]

        var sortOrder = 0
        for cat in expenseCategories {
            modelContext.insert(Category(name: cat.name, icon: cat.icon, colorHex: cat.color, type: .expense, sortOrder: sortOrder))
            sortOrder += 1
        }
        sortOrder = 0
        for cat in incomeCategories {
            modelContext.insert(Category(name: cat.name, icon: cat.icon, colorHex: cat.color, type: .income, sortOrder: sortOrder))
            sortOrder += 1
        }

        // 默认账户
        let defaultAccounts: [(name: String, type: AccountType, balance: Double)] = [
            ("现金钱包", .cash, 1000),
            ("工商银行", .bank, 50000),
            ("微信钱包", .wechat, 2000),
            ("支付宝", .alipay, 3000),
        ]
        sortOrder = 0
        for acc in defaultAccounts {
            modelContext.insert(Account(name: acc.name, type: acc.type, initialBalance: acc.balance, sortOrder: sortOrder))
            sortOrder += 1
        }

        try? modelContext.save()
    }
}
