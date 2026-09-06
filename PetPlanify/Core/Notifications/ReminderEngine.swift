import Foundation

/// Linked reminders retain their identifiers and completion state until the source date changes.
enum ReminderEngine {
    static func reconcile(_ snapshot: inout PetPlanifySnapshot, now: Date = .now) {
        var sources: [(String, UUID, String, Date, String)] = []
        let vaccines = Dictionary(grouping: snapshot.health.vaccines, by: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        for records in vaccines.values {
            if let value = records.max(by: { $0.dateAdministered < $1.dateAdministered }), let date = value.nextDueDate {
                sources.append(("vaccine.\(value.id)", value.id, value.name, date, value.notes ?? ""))
            }
        }
        for kind in DewormingKind.allCases {
            if let value = snapshot.health.dewormings.filter({ $0.kind == kind }).max(by: { $0.applicationDate < $1.applicationDate }), let date = value.nextDueDate {
                sources.append(("deworming.\(value.id)", value.id, kind.title, date, value.productName ?? ""))
            }
        }
        for visit in snapshot.health.visits {
            let key = "visit.\(visit.id)"
            if visit.date > now || snapshot.reminders.contains(where: { $0.sourceKey == key }) {
                sources.append((key, visit.id, visit.reason, visit.date, visit.clinic))
            }
            if let date = visit.followUpDate {
                sources.append(("followup.\(visit.id)", visit.id, String(localized: "Seguimiento: \(visit.reason)"), date, visit.clinic))
            }
        }
        let validKeys = Set(sources.map(\.0))
        snapshot.reminders.removeAll { $0.sourceKey.map { !validKeys.contains($0) } ?? false }
        for (key, id, title, date, notes) in sources {
            if let index = snapshot.reminders.firstIndex(where: { $0.sourceKey == key }) {
                if snapshot.reminders[index].date != date {
                    snapshot.reminders[index].isCompleted = false
                    snapshot.reminders[index].completedAt = nil
                }
                snapshot.reminders[index].title = title
                snapshot.reminders[index].date = date
                snapshot.reminders[index].notes = notes
            } else {
                snapshot.reminders.append(CareReminder(title: title, date: date, relatedFeature: .health, relatedRecordID: id, sourceKey: key, notes: notes))
            }
        }
        snapshot.reminders.sort { $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date < $1.date }
    }

    static func upcoming(_ reminders: [CareReminder], now: Date = .now) -> [CareReminder] {
        reminders.filter { !$0.isCompleted && $0.date > now }.sorted { $0.date < $1.date }
    }

    static func notificationDate(for reminder: CareReminder, preferences: ReminderPreferences, calendar: Calendar = .current) -> Date? {
        guard preferences.notificationsEnabled, reminder.notificationEnabled, !reminder.isCompleted else { return nil }
        switch reminder.relatedFeature {
        case .health where !preferences.healthEnabled: return nil
        case .nutrition where !preferences.nutritionEnabled: return nil
        case .training where !preferences.trainingEnabled: return nil
        default: break
        }
        return calendar.date(byAdding: .day, value: -preferences.advanceTime.rawValue, to: reminder.date)
    }
}
