import Foundation
import UserNotifications

actor LocalReminderSchedulingService: ReminderSchedulingService {
    private let center = UNUserNotificationCenter.current()
    private let testPrefix = "petplanify.test."

    func scheduleTestNotifications() async throws {
        let status = await permissionStatus()
        guard status == .authorized || status == .provisional else { throw NSError(domain: "PetPlanifyNotifications", code: 1) }
        center.removePendingNotificationRequests(withIdentifiers: (0..<8).map { "\(testPrefix)\($0)" })
        let messages = [
            ("🩺 Próxima visita", "Recuerda la cita veterinaria de tu perro."),
            ("💉 Próxima vacuna", "Se acerca una vacuna importante para tu perro."),
            ("🟠 Desparasitación", "Toca revisar la próxima desparasitación."),
            ("💊 Medicación", "Tu perro tiene una medicación pendiente."),
            ("🐾 PetPlanify", "Cuéntanos cómo sigue tu perro después de su visita."),
            ("📋 Historia de salud", "Puedes actualizar hoy la historia de tu perro."),
            ("🍽️ Alimentación", "Es un buen momento para revisar su plan de alimentación."),
            ("🐶 PetPlanify", "Un pequeño cuidado hoy hace la diferencia.")
        ].shuffled()
        for (index, message) in messages.enumerated() {
            let content = UNMutableNotificationContent(); content.title = message.0; content.body = message.1; content.sound = .default; content.threadIdentifier = "petplanify.test"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(5 + index * 7), repeats: false)
            try await center.add(UNNotificationRequest(identifier: "\(testPrefix)\(index)", content: content, trigger: trigger))
        }
    }

    func cancelTestNotifications() async { center.removePendingNotificationRequests(withIdentifiers: (0..<8).map { "\(testPrefix)\($0)" }) }

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
            content.title = notificationTitle(for: reminder)
            content.body = notificationBody(for: reminder, petName: petName, advanceDays: preferences.advanceTime.rawValue)
            content.sound = .default
            content.threadIdentifier = "petplanify.care"
            content.categoryIdentifier = "PETPLANIFY_CARE"
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

    private func notificationTitle(for reminder: CareReminder) -> String {
        let key = reminder.sourceKey ?? ""
        if key.hasPrefix("visit.") || key.hasPrefix("followup.") { return "🩺 PetPlanify · (reminder.title)" }
        if key.hasPrefix("vaccine.") { return "💉 PetPlanify · (reminder.title)" }
        if key.hasPrefix("deworming.") { return "🟠 PetPlanify · (reminder.title)" }
        if key.hasPrefix("medication.") { return "💊 PetPlanify · (reminder.title)" }
        return "🐾 PetPlanify · (reminder.title)"
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
