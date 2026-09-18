import Foundation
import UserNotifications

actor LocalReminderSchedulingService: ReminderSchedulingService {
    private let center = UNUserNotificationCenter.current()

    func permissionStatus() async -> UNAuthorizationStatus { await center.notificationSettings().authorizationStatus }

    func requestPermission() async throws -> Bool {
        switch await permissionStatus() {
        case .notDetermined: return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    func synchronize(reminders: [CareReminder], preferences: ReminderPreferences, petName: String, now: Date = .now) async throws {
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
            content.body = notificationBody(for: reminder, petName: petName, advanceDays: preferences.advanceTime.rawValue)
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

    private func notificationBody(for reminder: CareReminder, petName: String, advanceDays: Int) -> String {
        let name = petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? String(localized: "tu mascota") : petName
        let prefix = reminder.sourceKey ?? ""
        if prefix.hasPrefix("visit.") {
            return advanceDays == 1
                ? String(localized: "Mañana \(name) tiene cita veterinaria.")
                : String(localized: "Próxima cita veterinaria de \(name).")
        }
        if prefix.hasPrefix("vaccine.") {
            if advanceDays == 7 { return String(localized: "La vacuna de \(name) vence la semana que viene.") }
            if advanceDays == 1 { return String(localized: "La vacuna de \(name) vence mañana.") }
            return String(localized: "Revisa la próxima vacuna de \(name).")
        }
        if prefix.hasPrefix("medication.") {
            return String(localized: "Toca administrar la medicación de \(name).")
        }
        if prefix.hasPrefix("deworming.") {
            return String(localized: "Se acerca la desparasitación de \(name).")
        }
        return reminder.notes.isEmpty ? String(localized: "Tienes un cuidado pendiente para \(name) en PetPlanify.") : reminder.notes
    }
}

extension Notification.Name {
    static let petPlanifyOpenReminder = Notification.Name("PetPlanifyOpenReminder")
}

@MainActor
final class PetPlanifyNotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PetPlanifyNotificationRouter()

    func activate() {
        UNUserNotificationCenter.current().delegate = self
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let feature = userInfo["feature"] as? String
        let reminderID = userInfo["reminderID"] as? String
        completionHandler()
        Task { @MainActor in
            var routedInfo: [AnyHashable: Any] = [:]
            routedInfo["feature"] = feature
            routedInfo["reminderID"] = reminderID
            NotificationCenter.default.post(name: .petPlanifyOpenReminder, object: nil, userInfo: routedInfo)
        }
    }
}

/// Compatibility alias while call sites migrate to the service protocol.
typealias LocalNotificationService = LocalReminderSchedulingService
