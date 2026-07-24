import Foundation

enum HealthRecordStatus: Hashable, Sendable {
    case completed
    case upcoming
    case resolved
    case active
    case finished

    var title: String {
        switch self {
        case .completed: String(localized: "Completada")
        case .upcoming: String(localized: "Próxima")
        case .resolved: String(localized: "Resuelto")
        case .active: String(localized: "Activo")
        case .finished: String(localized: "Finalizado")
        }
    }

    var isUpcoming: Bool { self == .upcoming }
}

enum SymptomSeverity: Hashable, Sendable {
    case mild

    var title: String {
        switch self {
        case .mild: String(localized: "Leve")
        }
    }
}

struct VaccinationRecord: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let title: String
    let details: String
    let status: HealthRecordStatus
}

struct MedicationRecord: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let startDate: Date
    let endDate: Date
    let status: HealthRecordStatus
}

struct SymptomRecord: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let name: String
    let notes: String
    let severity: SymptomSeverity
    let status: HealthRecordStatus
}

struct VeterinaryVisit: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let reason: String
    let clinic: String
    let status: HealthRecordStatus
}

struct HealthDocument: Identifiable, Hashable, Sendable {
    let id: Int
    let filename: String
    let fileType: String
    let fileSize: String
    let updatedDate: Date
}

struct HealthOverview: Hashable, Sendable {
    let vaccinations: [VaccinationRecord]
    let medicationHistory: [MedicationRecord]
    let symptoms: [SymptomRecord]
    let visits: [VeterinaryVisit]
    let documents: [HealthDocument]

    var upcomingVaccination: VaccinationRecord? {
        vaccinations.first(where: { $0.status == .upcoming })
    }

    var upcomingVisit: VeterinaryVisit? {
        visits.first(where: { $0.status == .upcoming })
    }

}

enum HealthDetail: Identifiable, Hashable, Sendable {
    case addRecord
    case vaccination(VaccinationRecord)
    case medicationHistory
    case symptom(SymptomRecord)
    case visit(VeterinaryVisit)
    case document(HealthDocument)

    var id: String {
        switch self {
        case .addRecord: "add-record"
        case let .vaccination(record): "vaccination-\(record.id)"
        case .medicationHistory: "medication-history"
        case let .symptom(record): "symptom-\(record.id)"
        case let .visit(record): "visit-\(record.id)"
        case let .document(record): "document-\(record.id)"
        }
    }
}

enum HealthFormatting {
    static let spanishLocale = Locale(identifier: "es_ES")

    static func date(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle()
                .day()
                .month(.wide)
                .year()
                .locale(spanishLocale)
        )
    }

    static func shortDate(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle()
                .day()
                .month(.abbreviated)
                .year()
                .locale(spanishLocale)
        )
    }
}
