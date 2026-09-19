import EventKit
import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Optional, write-only bridge to Calendar. PetPlanify never reads a person's
/// calendars: its own local health calendar remains the source of truth.
actor AppleCalendarExportService {
    static let shared = AppleCalendarExportService()

    enum ExportError: LocalizedError, Sendable {
        case permissionDenied
        case noWritableCalendar
        case fullAccessRequired

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                String(localized: "No se ha podido añadir al Calendario porque el permiso de escritura no está activo. Puedes activarlo en Ajustes del sistema.")
            case .noWritableCalendar:
                String(localized: "No hay un calendario disponible para añadir este cuidado.")
            case .fullAccessRequired:
                String(localized: "Necesitamos permiso para gestionar los eventos del calendario PetPlanify.")
            }
        }
    }

    private let eventStore = EKEventStore()
    private let calendarTitle = "PetPlanify"

    struct CalendarItem: Sendable {
        let title: String
        let date: Date
        let endDate: Date?
        let notes: String?
    }

    func export(title: String, date: Date, endDate: Date? = nil, notes: String? = nil, alertAdvance: AppleCalendarAlertAdvance = .none) async throws {
        guard try await requestWriteOnlyAccess() else { throw ExportError.permissionDenied }
        let calendar = try petPlanifyCalendar()

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = title
        event.startDate = date
        event.endDate = max(endDate ?? date.addingTimeInterval(30 * 60), date.addingTimeInterval(60))
        event.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        // Los avisos los gestiona PetPlanify para evitar duplicados del Calendario.
        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    /// Creates one dedicated writable calendar the first time it is needed.
    /// The user can freely rename or recolor it in Apple's Calendar app; we
    /// only reuse it and never overwrite its color after creation.
    private func petPlanifyCalendar() throws -> EKCalendar {
        if let existing = eventStore.calendars(for: .event).first(where: { $0.title == calendarTitle && $0.allowsContentModifications }) {
            return existing
        }
        guard let source = eventStore.defaultCalendarForNewEvents?.source
                ?? eventStore.calendars(for: .event).first(where: { $0.allowsContentModifications })?.source else {
            throw ExportError.noWritableCalendar
        }
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = calendarTitle
        calendar.source = source
        #if os(macOS)
        calendar.color = Self.defaultCalendarColor
        #endif
        try eventStore.saveCalendar(calendar, commit: true)
        return calendar
    }

    #if os(macOS)
    private static var defaultCalendarColor: NSColor {
        return NSColor(calibratedRed: 0.38, green: 0.63, blue: 0.53, alpha: 1)
    }
    #endif

    func exportAll(_ items: [CalendarItem], petName: String, alertAdvance: AppleCalendarAlertAdvance = .none) async throws {
        for item in items {
            try await export(
                title: "\(petName) · \(item.title)",
                date: item.date,
                endDate: item.endDate,
                notes: item.notes,
                alertAdvance: alertAdvance
            )
        }
    }

    func deletePetPlanifyEvents() async throws {
        guard try await requestFullAccess() else { throw ExportError.permissionDenied }
        guard let calendar = eventStore.calendars(for: .event).first(where: { $0.title == calendarTitle }) else { return }
        let predicate = eventStore.predicateForEvents(withStart: .distantPast, end: .distantFuture, calendars: [calendar])
        let events = eventStore.events(matching: predicate)
        for event in events { try eventStore.remove(event, span: .thisEvent, commit: false) }
        if !events.isEmpty { try eventStore.commit() }
    }

    private func requestWriteOnlyAccess() async throws -> Bool {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            return try await eventStore.requestWriteOnlyAccessToEvents()
        }
        return false
        #elseif os(macOS)
        if #available(macOS 14.0, *) {
            return try await eventStore.requestWriteOnlyAccessToEvents()
        }
        return false
        #endif
    }

    private func requestFullAccess() async throws -> Bool {
        #if os(iOS)
        if #available(iOS 17.0, *) { return try await eventStore.requestFullAccessToEvents() }
        return false
        #elseif os(macOS)
        if #available(macOS 14.0, *) { return try await eventStore.requestFullAccessToEvents() }
        return false
        #endif
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

@MainActor
func exportCareToAppleCalendarIfNeeded(
    _ isEnabled: Bool,
    petName: String,
    title: String,
    date: Date,
    endDate: Date? = nil,
    notes: String?,
    alertAdvance: AppleCalendarAlertAdvance = .none,
    store: PetPlanifyStore
) async {
    guard isEnabled else { return }
    do {
        let name = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        try await AppleCalendarExportService.shared.export(
            title: "\(name.isEmpty ? String(localized: "Tu mascota") : name) · \(title)",
            date: date,
            endDate: endDate,
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            alertAdvance: alertAdvance
        )
    } catch {
        store.message = error.localizedDescription
    }
}
