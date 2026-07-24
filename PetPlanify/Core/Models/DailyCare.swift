import Foundation

enum ObservationContext: String, CaseIterable, Identifiable, Hashable, Sendable {
    case general
    case nutrition
    case health
    case training

    var id: Self { self }

    var title: String {
        switch self {
        case .general: "General"
        case .nutrition: "Alimentación"
        case .health: "Salud"
        case .training: "Entrenamiento"
        }
    }
}

struct PetObservation: Identifiable, Hashable, Sendable {
    let id: Int
    let context: ObservationContext
    let title: String
    let body: String
    let date: Date
}

struct CareReminder: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let date: Date
    let section: AppSection
    let notes: String
    var isCompleted: Bool

    var isOverdue: Bool {
        !isCompleted && date < PreviewData.referenceDate
    }
}
