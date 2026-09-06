import Foundation

struct HealthData: Codable, Equatable, Sendable {
    var weights: [WeightRecord] = []
    var vaccines: [VaccinationRecord] = []
    var dewormings: [DewormingRecord] = []
    var medications: [MedicationRecord] = []
    var visits: [VeterinaryVisit] = []
    var documents: [DocumentAttachment] = []
    var observations: [PetObservation] = []
}

struct WeightRecord: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var date: Date = .now
    /// Canonical storage is kilograms, independent of the display unit.
    var weight: Double
    var note: String? = nil
}

enum HealthRecordStatus: Sendable {
    case completed, upcoming, overdue, active, finished

    var title: String {
        switch self {
        case .completed: String(localized: "Registrada")
        case .upcoming: String(localized: "Próxima")
        case .overdue: String(localized: "Fecha pasada")
        case .active: String(localized: "Activa")
        case .finished: String(localized: "Finalizada")
        }
    }

    static func dueDate(_ date: Date?, relativeTo now: Date) -> Self {
        guard let date else { return .completed }
        return date < Calendar.current.startOfDay(for: now) ? .overdue : .upcoming
    }
}

struct VaccinationRecord: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var name: String
    var dateAdministered: Date = .now
    var nextDueDate: Date? = nil
    var clinic: String? = nil
    var notes: String? = nil

    func status(relativeTo now: Date = .now) -> HealthRecordStatus {
        .dueDate(nextDueDate, relativeTo: now)
    }
}

enum DewormingKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case internalDeworming
    case externalDeworming

    var id: Self { self }
    var title: String {
        switch self {
        case .internalDeworming: String(localized: "Desparasitación interna")
        case .externalDeworming: String(localized: "Desparasitación externa")
        }
    }
    var shortTitle: String {
        switch self {
        case .internalDeworming: String(localized: "Interna")
        case .externalDeworming: String(localized: "Externa")
        }
    }
    var symbol: String {
        switch self {
        case .internalDeworming: "pills"
        case .externalDeworming: "drop"
        }
    }
}

struct DewormingRecord: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var kind: DewormingKind
    var productName: String? = nil
    var applicationDate: Date = .now
    var nextDueDate: Date? = nil
    var notes: String? = nil

    func status(relativeTo now: Date = .now) -> HealthRecordStatus {
        .dueDate(nextDueDate, relativeTo: now)
    }
}

struct MedicationRecord: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var name: String
    var startDate: Date = .now
    var endDate: Date? = nil
    var notes: String = ""
    var relatedVisitID: UUID? = nil

    func isActive(relativeTo now: Date = .now) -> Bool {
        startDate <= now && (endDate == nil || endDate! > now)
    }

    func status(relativeTo now: Date = .now) -> HealthRecordStatus {
        if startDate > now { return .upcoming }
        return isActive(relativeTo: now) ? .active : .finished
    }
}

struct VeterinaryVisit: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var date: Date = .now
    var reason: String
    var clinic: String = ""
    var notes: String = ""
    var assessment: String? = nil
    var treatmentNotes: String? = nil
    var followUpDate: Date? = nil
    var documentIDs: [UUID] = []
    var createdAt: Date = .now
    var updatedAt: Date = .now

    func status(relativeTo now: Date = .now) -> HealthRecordStatus {
        date > now ? .upcoming : .completed
    }
}

extension Array where Element: Identifiable {
    mutating func upsert(_ value: Element) {
        if let index = firstIndex(where: { $0.id == value.id }) {
            self[index] = value
        } else {
            append(value)
        }
    }
}

extension String {
    var healthTrimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var healthOptional: String? { healthTrimmed.isEmpty ? nil : healthTrimmed }
}
