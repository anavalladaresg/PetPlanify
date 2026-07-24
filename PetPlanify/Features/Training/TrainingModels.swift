import Foundation

enum TrickStatus: String, CaseIterable, Identifiable, Hashable, Sendable {
    case notStarted, learning, mastered
    var id: Self { self }

    var title: String {
        switch self {
        case .notStarted: String(localized: "Por empezar")
        case .learning: String(localized: "Aprendiendo")
        case .mastered: String(localized: "Dominado")
        }
    }
}

enum TrickDifficulty: String, CaseIterable, Identifiable, Hashable, Sendable {
    case easy, medium, advanced
    var id: Self { self }

    var title: String {
        switch self {
        case .easy: String(localized: "Fácil")
        case .medium: String(localized: "Media")
        case .advanced: String(localized: "Avanzada")
        }
    }
}

enum TrickCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case basic, safety, coexistence, fun
    var id: Self { self }

    var title: String {
        switch self {
        case .basic: String(localized: "Obediencia básica")
        case .safety: String(localized: "Seguridad")
        case .coexistence: String(localized: "Convivencia")
        case .fun: String(localized: "Diversión")
        }
    }
}

struct TrickGuide: Hashable, Sendable {
    let objective: String
    let materials: String
    let steps: [String]
    let commonMistakes: [String]
    let recommendedAttempt: String
    let reward: String
    let advancement: String
    let precautions: String
}

struct TrickDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let symbol: String
    let difficulty: TrickDifficulty
    let category: TrickCategory
    let prerequisites: [String]
    let guide: TrickGuide
}

struct SelectedTrick: Identifiable, Hashable, Sendable {
    let definition: TrickDefinition
    var status: TrickStatus
    var progress: Int
    var id: String { definition.id }
}

struct BehaviorObservation: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let title: String
    let body: String
    let helpfulContext: String
}

struct TrainingOverview: Hashable, Sendable {
    var selectedTricks: [SelectedTrick]
    let library: [TrickDefinition]
    let behaviorObservations: [BehaviorObservation]
}

enum TrainingDetail: Identifiable, Hashable, Sendable {
    case customTrick
    case library
    case trick(TrickDefinition)
    case behavior(BehaviorObservation)

    var id: String {
        switch self {
        case .customTrick: "custom-trick"
        case .library: "library"
        case let .trick(trick): "trick-\(trick.id)"
        case let .behavior(observation): "behavior-\(observation.id)"
        }
    }
}

enum TrainingFormatting {
    static let spanishLocale = Locale(identifier: "es_ES")

    static func date(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle().day().month(.wide).year().locale(spanishLocale)
        )
    }
}
