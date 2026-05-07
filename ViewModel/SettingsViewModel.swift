import Foundation
import SwiftUI
import SwiftData

@Observable
final class SettingsViewModel {
    var categories: [Category] = []
    var accounts: [Account] = []
    var budgets: [Budget] = []
    var reminders: [BillReminder] = []
    var recurringTransactions: [RecurringTransaction] = []

    func fetchAll(modelContext: ModelContext) {
        fetchCategories(modelContext: modelContext)
        fetchAccounts(modelContext: modelContext)
        fetchBudgets(modelContext: modelContext)
        fetchReminders(modelContext: modelContext)
        fetchRecurring(modelContext: modelContext)
    }

    func fetchCategories(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        categories = (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchAccounts(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)])
        accounts = (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchBudgets(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Budget>()
        budgets = (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchReminders(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<BillReminder>(sortBy: [SortDescriptor(\.dueDate)])
        reminders = (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchRecurring(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<RecurringTransaction>(sortBy: [SortDescriptor(\.nextDueDate)])
        recurringTransactions = (try? modelContext.fetch(descriptor)) ?? []
    }

    // CRUD helpers
    func saveCategory(_ category: Category, modelContext: ModelContext) {
        if !categories.contains(where: { $0.id == category.id }) {
            modelContext.insert(category)
        }
        try? modelContext.save()
        fetchCategories(modelContext: modelContext)
    }

    func deleteCategory(_ category: Category, modelContext: ModelContext) {
        modelContext.delete(category)
        try? modelContext.save()
        fetchCategories(modelContext: modelContext)
    }

    func saveAccount(_ account: Account, modelContext: ModelContext) {
        if !accounts.contains(where: { $0.id == account.id }) {
            modelContext.insert(account)
        }
        try? modelContext.save()
        fetchAccounts(modelContext: modelContext)
    }

    func deleteAccount(_ account: Account, modelContext: ModelContext) {
        modelContext.delete(account)
        try? modelContext.save()
        fetchAccounts(modelContext: modelContext)
    }

    func saveBudget(_ budget: Budget, modelContext: ModelContext) {
        if !budgets.contains(where: { $0.id == budget.id }) {
            modelContext.insert(budget)
        }
        try? modelContext.save()
        fetchBudgets(modelContext: modelContext)
    }

    func deleteBudget(_ budget: Budget, modelContext: ModelContext) {
        modelContext.delete(budget)
        try? modelContext.save()
        fetchBudgets(modelContext: modelContext)
    }

    func saveReminder(_ reminder: BillReminder, modelContext: ModelContext, notificationService: NotificationService) {
        if !reminders.contains(where: { $0.id == reminder.id }) {
            modelContext.insert(reminder)
        }
        try? modelContext.save()
        notificationService.scheduleReminder(reminder)
        fetchReminders(modelContext: modelContext)
    }

    func deleteReminder(_ reminder: BillReminder, modelContext: ModelContext, notificationService: NotificationService) {
        notificationService.cancelReminder(reminder)
        modelContext.delete(reminder)
        try? modelContext.save()
        fetchReminders(modelContext: modelContext)
    }

    func saveRecurring(_ recurring: RecurringTransaction, modelContext: ModelContext) {
        if !recurringTransactions.contains(where: { $0.id == recurring.id }) {
            modelContext.insert(recurring)
        }
        try? modelContext.save()
        fetchRecurring(modelContext: modelContext)
    }

    func deleteRecurring(_ recurring: RecurringTransaction, modelContext: ModelContext) {
        modelContext.delete(recurring)
        try? modelContext.save()
        fetchRecurring(modelContext: modelContext)
    }
}
