import Foundation

enum ObservationContext: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case general, nutrition, health, training
    var id: Self { self }
    var title: String {
        switch self {
        case .general: String(localized: "General")
        case .nutrition: String(localized: "Alimentación")
        case .health: String(localized: "Salud")
        case .training: String(localized: "Entrenamiento")
        }
    }
}

struct PetObservation: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var context: ObservationContext = .general
    var title = ""
    var body = ""
    var date = Date.now
}

struct CareReminder: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var title = ""
    var date = Date.now
    var relatedFeature: ObservationContext = .general
    var relatedRecordID: UUID?
    var sourceKey: String?
    var notes = ""
    var isCompleted = false
    var completedAt: Date?
    var notificationEnabled = true
    var notificationIdentifier: String { "petplanify.reminder.\(id.uuidString)" }
    func isOverdue(at now: Date = .now) -> Bool { !isCompleted && date < now }
}

struct DocumentAttachment: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var displayName: String
    var type: String
    var relativeStoragePath: String
    var createdAt = Date.now
    var linkedVisitID: UUID?
}
