import Foundation
import SwiftUI
import SwiftData

enum StatisticsRange: String, CaseIterable {
    case currentMonth = "本月"
    case last3Months = "近3月"
    case lastYear = "近1年"
}

struct CategoryStat: Identifiable {
    let id: UUID
    let category: Category
    let amount: Double
    let percentage: Double
}

struct MonthlyStat: Identifiable {
    let id: String
    let month: String
    let income: Double
    let expense: Double
}

@Observable
final class StatisticsViewModel {
    var selectedRange: StatisticsRange = .currentMonth
    var categoryStats: [CategoryStat] = []
    var monthlyStats: [MonthlyStat] = []
    var totalExpense: Double = 0
    var totalIncome: Double = 0
    var transactions: [Transaction] = []

    func fetchData(modelContext: ModelContext) {
        let now = Date()
        let startDate: Date
        switch selectedRange {
        case .currentMonth:
            startDate = now.startOfMonth
        case .last3Months:
            startDate = Calendar.current.date(byAdding: .month, value: -3, to: now.startOfMonth) ?? now
        case .lastYear:
            startDate = Calendar.current.date(byAdding: .year, value: -1, to: now.startOfMonth) ?? now
        }

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.date >= startDate },
            sortBy: [SortDescriptor(\.date)]
        )
        transactions = (try? modelContext.fetch(descriptor)) ?? []

        totalIncome = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        totalExpense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

        buildCategoryStats()
        buildMonthlyStats()
    }

    private func buildCategoryStats() {
        let expenses = transactions.filter { $0.type == .expense }
        var dict: [UUID: (category: Category, amount: Double)] = [:]
        for t in expenses {
            guard let cat = t.category else { continue }
            if let existing = dict[cat.id] {
                dict[cat.id] = (cat, existing.amount + t.amount)
            } else {
                dict[cat.id] = (cat, t.amount)
            }
        }
        let total = totalExpense
        categoryStats = dict.values
            .map { CategoryStat(
                id: $0.category.id,
                category: $0.category,
                amount: $0.amount,
                percentage: total > 0 ? $0.amount / total : 0
            )}
            .sorted { $0.amount > $1.amount }
    }

    private func buildMonthlyStats() {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction -> String in
            let components = calendar.dateComponents([.year, .month], from: transaction.date)
            return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
        }
        monthlyStats = grouped.map { (key, items) in
            MonthlyStat(
                id: key,
                month: key,
                income: items.filter { $0.type == .income }.reduce(0) { $0 + $1.amount },
                expense: items.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            )
        }.sorted { $0.id < $1.id }
    }
}
