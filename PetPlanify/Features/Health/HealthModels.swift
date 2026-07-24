import Foundation

enum HealthRecordStatus: Hashable, Sendable {
    case completed, upcoming, active, finished

    var title: String {
        switch self {
        case .completed: String(localized: "Completada")
        case .upcoming: String(localized: "Próxima")
        case .active: String(localized: "Activa")
        case .finished: String(localized: "Finalizada")
        }
    }

    var isUpcoming: Bool { self == .upcoming }
}

struct HealthWeightRecord: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let kilograms: Double
}

struct VaccinationRecord: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let title: String
    let details: String
    let clinic: String
    let status: HealthRecordStatus
}

struct MedicationRecord: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let startDate: Date
    let endDate: Date?
    let notes: String
    let status: HealthRecordStatus
}

struct HealthDocument: Identifiable, Hashable, Sendable {
    let id: Int
    let filename: String
    let fileType: String
    let fileSize: String
    let updatedDate: Date
}

struct VeterinaryVisit: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let reason: String
    let clinic: String
    let notes: String
    let medications: [String]
    let followUpDate: Date?
    let documents: [HealthDocument]
    let status: HealthRecordStatus
}

struct HealthOverview: Hashable, Sendable {
    let weightRecords: [HealthWeightRecord]
    let healthyWeightRange: ClosedRange<Double>?
    let vaccinations: [VaccinationRecord]
    let medications: [MedicationRecord]
    let visits: [VeterinaryVisit]

    var currentWeight: Double { weightRecords.last?.kilograms ?? 0 }
    var upcomingVaccination: VaccinationRecord? {
        vaccinations.first { $0.status == .upcoming }
    }
    var upcomingVisit: VeterinaryVisit? {
        visits.first { $0.status == .upcoming }
    }
    var activeMedications: [MedicationRecord] {
        medications.filter { $0.status == .active }
    }
}

enum HealthDetail: Identifiable, Hashable, Sendable {
    case addRecord
    case registerWeight
    case vaccination(VaccinationRecord)
    case medicationHistory
    case visit(VeterinaryVisit)

    var id: String {
        switch self {
        case .addRecord: "add-record"
        case .registerWeight: "register-weight"
        case let .vaccination(record): "vaccination-\(record.id)"
        case .medicationHistory: "medication-history"
        case let .visit(record): "visit-\(record.id)"
        }
    }
}

enum HealthFormatting {
    static let spanishLocale = Locale(identifier: "es_ES")

    static func date(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle().day().month(.wide).year().locale(spanishLocale)
        )
    }

    static func shortDate(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle().day().month(.abbreviated).year().locale(spanishLocale)
        )
    }

    static func weight(_ value: Double) -> String {
        "\(value.formatted(.number.locale(spanishLocale).precision(.fractionLength(1)))) kg"
    }

    static func weightRange(_ range: ClosedRange<Double>) -> String {
        "\(weight(range.lowerBound).replacingOccurrences(of: " kg", with: ""))–\(weight(range.upperBound))"
    }
}
