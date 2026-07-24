import Foundation

enum ObservationContext: String, CaseIterable, Identifiable, Hashable, Sendable {
    case general
    case nutrition

    var id: Self { self }

    var title: String {
        switch self {
        case .general: String(localized: "General")
        case .nutrition: String(localized: "Alimentación")
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
        !isCompleted && date < Date.now
    }
}
