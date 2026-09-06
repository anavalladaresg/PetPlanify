import Foundation

enum TrickStatus: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
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

enum TrickDifficulty: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
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

enum TrickCategory: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
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
    var objective: String
    var requiredMaterials: String
    var steps: [String]
    var commonMistakes: [String]
    var recommendedAttemptDuration: String
    var rewardGuidance: String
    var progressionCriteria: String
    var precautions: String
}

/// Built-in artwork can later replace a symbol without changing persisted records.
struct TrickDefinition: Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var iconIdentifier: String
    var illustrationAssetName: String? = nil
    var difficulty: TrickDifficulty
    var category: TrickCategory
    var prerequisites: [String]
    var guide: TrickGuide
}

struct SelectedTrick: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var trickID: String
    var status: TrickStatus = .notStarted
    var progress: Int = 0
    var addedAt: Date = Date()
    var customNotes: String = ""
}

struct CustomTrick: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String = ""
    var category: TrickCategory = .fun
    var difficulty: TrickDifficulty = .easy
    var objective: String = ""
    var steps: [String] = []
    var notes: String = ""

    var trickID: String { "custom-\(id.uuidString)" }

    var definition: TrickDefinition {
        TrickDefinition(
            id: trickID,
            name: name,
            iconIdentifier: "pawprint",
            difficulty: difficulty,
            category: category,
            prerequisites: [],
            guide: TrickGuide(
                objective: objective, requiredMaterials: "", steps: steps,
                commonMistakes: [], recommendedAttemptDuration: "",
                rewardGuidance: "", progressionCriteria: "", precautions: ""
            )
        )
    }
}

struct BehaviorObservation: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var date: Date = Date()
    var title: String = ""
    var observation: String = ""
    var context: String = ""
    var status: String = ""
}

struct TrainingData: Codable, Equatable, Sendable {
    var selectedTricks: [SelectedTrick] = []
    var customTricks: [CustomTrick] = []
    var observations: [BehaviorObservation] = []

    var library: [TrickDefinition] {
        BuiltInTrickLibrary.tricks + customTricks.map(\.definition)
    }

    func definition(for trickID: String) -> TrickDefinition? {
        library.first { $0.id == trickID }
    }

    mutating func addTrick(_ trickID: String) {
        guard definition(for: trickID) != nil,
              !selectedTricks.contains(where: { $0.trickID == trickID }) else { return }
        selectedTricks.append(SelectedTrick(trickID: trickID))
    }

    mutating func removeCustomTrick(_ id: UUID) {
        guard let trick = customTricks.first(where: { $0.id == id }) else { return }
        selectedTricks.removeAll { $0.trickID == trick.trickID }
        customTricks.removeAll { $0.id == id }
    }

    var validationError: String? {
        guard Set(selectedTricks.map(\.id)).count == selectedTricks.count,
              Set(selectedTricks.map(\.trickID)).count == selectedTricks.count,
              Set(customTricks.map(\.id)).count == customTricks.count,
              Set(observations.map(\.id)).count == observations.count else {
            return String(localized: "Hay registros de entrenamiento duplicados.")
        }
        guard selectedTricks.allSatisfy({ (0...100).contains($0.progress) && definition(for: $0.trickID) != nil }) else {
            return String(localized: "Hay un truco o un progreso de entrenamiento no válido.")
        }
        guard customTricks.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return String(localized: "Los trucos personalizados necesitan un nombre.")
        }
        guard observations.allSatisfy({
            !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !$0.observation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else {
            return String(localized: "Las observaciones de comportamiento necesitan título y contenido.")
        }
        return nil
    }
}

enum TrainingFormatting {
    static let spanishLocale = Locale(identifier: "es_ES")

    static func date(_ value: Date) -> String {
        value.formatted(Date.FormatStyle().day().month(.wide).year().locale(spanishLocale))
    }
}
