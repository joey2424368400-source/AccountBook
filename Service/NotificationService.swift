import Foundation
import UserNotifications

final class NotificationService: ObservableObject {
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("Notification permission granted")
            }
        }
    }

    func scheduleReminder(_ reminder: BillReminder) {
        guard reminder.isEnabled else {
            cancelReminder(reminder)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "账单提醒"
        content.body = "\(reminder.name) 即将到期，金额: \(reminder.amount.currencyFormatted)"
        content.sound = .default

        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: reminder.dueDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger: UNCalendarNotificationTrigger
        switch reminder.repeatCycle {
        case .monthly:
            var monthly = DateComponents()
            monthly.day = calendar.component(.day, from: reminder.dueDate)
            monthly.hour = 9
            monthly.minute = 0
            trigger = UNCalendarNotificationTrigger(dateMatching: monthly, repeats: true)
        case .yearly:
            var yearly = DateComponents()
            yearly.month = calendar.component(.month, from: reminder.dueDate)
            yearly.day = calendar.component(.day, from: reminder.dueDate)
            yearly.hour = 9
            yearly.minute = 0
            trigger = UNCalendarNotificationTrigger(dateMatching: yearly, repeats: true)
        case .none:
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        }

        let request = UNNotificationRequest(identifier: "reminder-\(reminder.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelReminder(_ reminder: BillReminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["reminder-\(reminder.id.uuidString)"])
    }

    func scheduleRecurringNotification(for recurring: RecurringTransaction) {
        guard recurring.isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "自动扣费"
        content.body = "\(recurring.name) 已扣费 \(recurring.amount.currencyFormatted)"
        content.sound = .default

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: recurring.nextDueDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "recurring-\(recurring.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
