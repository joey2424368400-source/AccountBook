import Foundation
import SwiftData

// MARK: - 备份/恢复 DTO

struct BackupPayload: Encodable {
    let categories: [CategoryDTO]
    let accounts: [AccountDTO]
    let transactions: [TransactionDTO]
    let budgets: [BudgetDTO]
    let autoDebits: [AutoDebitDTO]
}

struct RestorePayload: Decodable {
    let categories: [CategoryDTO]
    let accounts: [AccountDTO]
    let transactions: [TransactionDTO]
    let budgets: [BudgetDTO]
    let autoDebits: [AutoDebitDTO]
}

struct CategoryDTO: Codable {
    let uuid: String
    let name: String
    let type: String
    let icon: String
    let color: String
}

struct AccountDTO: Codable {
    let uuid: String
    let name: String
    let type: String
    let balance: Double
    let color: String
}

struct TransactionDTO: Codable {
    let uuid: String
    let type: String
    let amount: Double
    let note: String?
    let date: String
    let categoryUuid: String?
    let accountUuid: String?
}

struct BudgetDTO: Codable {
    let uuid: String
    let amount: Double
    let month: String
    let categoryUuid: String?
}

struct AutoDebitDTO: Codable {
    let uuid: String
    let name: String
    let type: String
    let amount: Double
    let frequency: String
    let startDate: String
    let nextDate: String
    let endDate: String?
    let creditLimit: Double?
    let billDay: Int?
    let repayDay: Int?
    let principal: Double?
    let interestRate: Double?
    let loanTerm: Int?
    let interestType: String?
    let categoryUuid: String?
    let accountUuid: String?
}

struct SyncResponse: Decodable {
    let success: Bool
    let syncedAt: String?
}

// MARK: - 同步服务

final class SyncService {
    static let shared = SyncService()

    private let apiService = APIService.shared
    private let dateFormatter: ISO8601DateFormatter

    private init() {
        dateFormatter = ISO8601DateFormatter()
    }

    var lastSyncedAt: String? {
        get { UserDefaults.standard.string(forKey: "last_synced_at") }
        set { UserDefaults.standard.set(newValue, forKey: "last_synced_at") }
    }

    // MARK: - 备份（上传到服务器）

    func uploadBackup(modelContext: ModelContext) async throws {
        // 获取全量数据
        let categories = (try? modelContext.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        let accounts = (try? modelContext.fetch(FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        let transactions = (try? modelContext.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
        let budgets = (try? modelContext.fetch(FetchDescriptor<Budget>())) ?? []
        let autoDebits = (try? modelContext.fetch(FetchDescriptor<RecurringTransaction>())) ?? []

        let payload = BackupPayload(
            categories: categories.map(mapCategory),
            accounts: accounts.map(mapAccount),
            transactions: transactions.map(mapTransaction),
            budgets: budgets.map(mapBudget),
            autoDebits: autoDebits.map(mapAutoDebit)
        )

        let response: SyncResponse = try await apiService.post("/sync/backup", body: payload)
        if response.success {
            lastSyncedAt = response.syncedAt ?? ISO8601DateFormatter().string(from: Date())
        }
    }

    // MARK: - 恢复（从服务器下载）

    func downloadRestore(modelContext: ModelContext) async throws {
        let payload: RestorePayload = try await apiService.get("/sync/restore")

        // 按外键顺序删除：先删子表
        let allTransactions = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
        for t in allTransactions { modelContext.delete(t) }

        let allBudgets = (try? modelContext.fetch(FetchDescriptor<Budget>())) ?? []
        for b in allBudgets { modelContext.delete(b) }

        let allReminders = (try? modelContext.fetch(FetchDescriptor<BillReminder>())) ?? []
        for r in allReminders { modelContext.delete(r) }

        let allRecurring = (try? modelContext.fetch(FetchDescriptor<RecurringTransaction>())) ?? []
        for r in allRecurring { modelContext.delete(r) }

        let allAccounts = (try? modelContext.fetch(FetchDescriptor<Account>())) ?? []
        for a in allAccounts { modelContext.delete(a) }

        let allCategories = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        for c in allCategories { modelContext.delete(c) }

        try? modelContext.save()

        // 重建 UUID → 对象 映射
        var categoryMap: [String: Category] = [:]
        var accountMap: [String: Account] = [:]

        for dto in payload.categories {
            let cat = Category(name: dto.name, icon: dto.icon, colorHex: dto.color, type: dto.type == "income" ? .income : .expense)
            cat.id = UUID(uuidString: dto.uuid) ?? UUID()
            modelContext.insert(cat)
            categoryMap[dto.uuid] = cat
        }

        for dto in payload.accounts {
            let acc = Account(name: dto.name, type: AccountType(rawValue: dto.type) ?? .cash, initialBalance: dto.balance)
            acc.id = UUID(uuidString: dto.uuid) ?? UUID()
            modelContext.insert(acc)
            accountMap[dto.uuid] = acc
        }

        for dto in payload.transactions {
            let tx = Transaction(
                amount: dto.amount,
                note: dto.note ?? "",
                date: ISO8601DateFormatter().date(from: dto.date) ?? Date(),
                type: dto.type == "income" ? .income : .expense,
                category: dto.categoryUuid.flatMap { categoryMap[$0] },
                account: dto.accountUuid.flatMap { accountMap[$0] }
            )
            tx.id = UUID(uuidString: dto.uuid) ?? UUID()
            modelContext.insert(tx)
        }

        for dto in payload.budgets {
            let budget = Budget(amount: dto.amount, period: .monthly, category: dto.categoryUuid.flatMap { categoryMap[$0] })
            budget.id = UUID(uuidString: dto.uuid) ?? UUID()
            modelContext.insert(budget)
        }

        for dto in payload.autoDebits {
            let recurring = RecurringTransaction(
                name: dto.name,
                amount: dto.amount,
                type: RecurringType(rawValue: dto.type) ?? .other,
                cycle: RecurringCycle(rawValue: dto.frequency) ?? .monthly,
                nextDueDate: ISO8601DateFormatter().date(from: dto.nextDate) ?? Date(),
                category: dto.categoryUuid.flatMap { categoryMap[$0] },
                account: dto.accountUuid.flatMap { accountMap[$0] }
            )
            recurring.id = UUID(uuidString: dto.uuid) ?? UUID()
            modelContext.insert(recurring)
        }

        try? modelContext.save()
        lastSyncedAt = ISO8601DateFormatter().string(from: Date())
    }

    // MARK: - 映射函数

    private func mapCategory(_ c: Category) -> CategoryDTO {
        CategoryDTO(uuid: c.id.uuidString, name: c.name, type: c.typeRaw, icon: c.icon, color: c.colorHex)
    }

    private func mapAccount(_ a: Account) -> AccountDTO {
        AccountDTO(uuid: a.id.uuidString, name: a.name, type: a.typeRaw, balance: a.initialBalance, color: "#4CAF50")
    }

    private func mapTransaction(_ t: Transaction) -> TransactionDTO {
        TransactionDTO(
            uuid: t.id.uuidString,
            type: t.typeRaw,
            amount: t.amount,
            note: t.note,
            date: ISO8601DateFormatter().string(from: t.date),
            categoryUuid: t.category?.id.uuidString,
            accountUuid: t.account?.id.uuidString
        )
    }

    private func mapBudget(_ b: Budget) -> BudgetDTO {
        BudgetDTO(
            uuid: b.id.uuidString,
            amount: b.amount,
            month: ISO8601DateFormatter().string(from: b.startDate).prefix(7).description,
            categoryUuid: b.category?.id.uuidString
        )
    }

    private func mapAutoDebit(_ a: RecurringTransaction) -> AutoDebitDTO {
        AutoDebitDTO(
            uuid: a.id.uuidString,
            name: a.name,
            type: a.typeRaw,
            amount: a.amount,
            frequency: a.cycleRaw,
            startDate: ISO8601DateFormatter().string(from: a.createdAt),
            nextDate: ISO8601DateFormatter().string(from: a.nextDueDate),
            endDate: nil,
            creditLimit: 0,
            billDay: 1,
            repayDay: 20,
            principal: a.principal,
            interestRate: a.interestRate,
            loanTerm: a.totalPeriods,
            interestType: a.interestTypeRaw,
            categoryUuid: a.category?.id.uuidString,
            accountUuid: a.account?.id.uuidString
        )
    }
}
