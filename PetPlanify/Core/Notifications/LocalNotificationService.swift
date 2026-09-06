import Foundation
import UserNotifications

actor LocalNotificationService {
    private let center = UNUserNotificationCenter.current()

    func permissionStatus() async -> UNAuthorizationStatus { await center.notificationSettings().authorizationStatus }

    func requestPermission() async throws -> Bool {
        switch await permissionStatus() {
        case .notDetermined: return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    func synchronize(reminders: [CareReminder], preferences: ReminderPreferences, now: Date = .now) async throws {
        let pending = await center.pendingNotificationRequests()
        let owned = pending.filter { $0.identifier.hasPrefix("petplanify.reminder.") }.map(\.identifier)
        // This app owns only this prefix, so unrelated requests are never removed.
        center.removePendingNotificationRequests(withIdentifiers: owned)
        let status = await permissionStatus()
        guard status == .authorized || status == .provisional, preferences.notificationsEnabled else { return }
        let eligible = reminders.compactMap { reminder -> (CareReminder, Date)? in
            guard let date = ReminderEngine.notificationDate(for: reminder, preferences: preferences), date > now else { return nil }
            return (reminder, date)
        }.sorted { $0.1 < $1.1 }.prefix(60)
        for (reminder, date) in eligible {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.notes.isEmpty ? String(localized: "Tienes un cuidado pendiente en PetPlanify.") : reminder.notes
            content.sound = .default
            content.userInfo = ["feature": reminder.relatedFeature.rawValue, "reminderID": reminder.id.uuidString]
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try await center.add(UNNotificationRequest(identifier: reminder.notificationIdentifier, content: content, trigger: trigger))
        }
        let delivered = await center.deliveredNotifications()
        let activeIDs = Set(reminders.filter { !$0.isCompleted }.map(\.notificationIdentifier))
        center.removeDeliveredNotifications(withIdentifiers: delivered.map(\.request.identifier).filter { $0.hasPrefix("petplanify.reminder.") && !activeIDs.contains($0) })
    }
}
