import Foundation
import SwiftUI
import SwiftData

@Observable
final class TransactionViewModel {
    var allTransactions: [Transaction] = []
    var filterType: TransactionType?
    var filterCategory: Category?
    var searchText: String = ""
    var groupedTransactions: [(month: String, items: [Transaction])] = []

    var filteredTransactions: [Transaction] {
        var result = allTransactions
        if let type = filterType {
            result = result.filter { $0.type == type }
        }
        if let category = filterCategory {
            result = result.filter { $0.category?.id == category.id }
        }
        if !searchText.isEmpty {
            result = result.filter { transaction in
                transaction.note.localizedCaseInsensitiveContains(searchText) ||
                (transaction.category?.name ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    func fetchTransactions(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        allTransactions = (try? modelContext.fetch(descriptor)) ?? []
        buildGroups()
    }

    func buildGroups() {
        let items = filteredTransactions
        let dict = Dictionary(grouping: items) { $0.date.monthAndYear }
        let sorted = dict.sorted { $0.key > $1.key }
        groupedTransactions = sorted.map { ($0.key, $0.value) }
    }

    func delete(_ transaction: Transaction, modelContext: ModelContext) {
        modelContext.delete(transaction)
        try? modelContext.save()
        allTransactions.removeAll { $0.id == transaction.id }
        buildGroups()
    }

    func save(_ transaction: Transaction, modelContext: ModelContext) {
        if allTransactions.contains(where: { $0.id == transaction.id }) {
            // update existing — SwiftData auto-saves
        } else {
            modelContext.insert(transaction)
        }
        try? modelContext.save()
    }

    func categoriesByType(_ type: TransactionType, modelContext: ModelContext) -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.typeRaw == type.rawValue },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func allAccounts(modelContext: ModelContext) -> [Account] {
        let descriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
