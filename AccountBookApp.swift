import SwiftUI
import SwiftData

@main
struct AccountBookApp: App {
    @StateObject private var notificationService = NotificationService()

    var modelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Account.self,
            Budget.self,
            BillReminder.self,
            RecurringTransaction.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    notificationService.requestAuthorization()
                    seedDataIfNeeded()
                    RecurringTransactionService.processRecurringTransactions(modelContext: modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
        .environmentObject(notificationService)
    }

    private func seedDataIfNeeded() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Category>()
        guard let count = try? context.fetchCount(descriptor), count == 0 else { return }
        SeedData.seed(modelContext: context)
    }
}
