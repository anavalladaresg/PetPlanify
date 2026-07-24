import Foundation

enum EvolutionMetric: String, CaseIterable, Identifiable, Hashable, Sendable {
    case weight
    case activity
    case training

    var id: Self { self }

    var title: String {
        switch self {
        case .weight: String(localized: "Peso")
        case .activity: String(localized: "Actividad")
        case .training: String(localized: "Entrenamiento")
        }
    }
}

enum EvolutionRange: String, CaseIterable, Identifiable, Hashable, Sendable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1A"

    var id: Self { self }

    var pointCount: Int {
        switch self {
        case .oneMonth: 2
        case .threeMonths: 3
        case .sixMonths: 6
        case .oneYear: 12
        }
    }

    var periodDescription: String {
        switch self {
        case .oneMonth: String(localized: "último mes")
        case .threeMonths: String(localized: "últimos 3 meses")
        case .sixMonths: String(localized: "últimos 6 meses")
        case .oneYear: String(localized: "último año")
        }
    }
}

enum EvolutionMilestoneCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case weight
    case health
    case nutrition
    case training
    case activity

    var id: Self { self }

    var title: String {
        switch self {
        case .weight: String(localized: "Peso")
        case .health: String(localized: "Salud")
        case .nutrition: String(localized: "Alimentación")
        case .training: String(localized: "Entrenamiento")
        case .activity: String(localized: "Actividad")
        }
    }

    var symbol: String {
        switch self {
        case .weight: "scalemass"
        case .health: "cross.case"
        case .nutrition: "fork.knife"
        case .training: "figure.walk"
        case .activity: "pawprint"
        }
    }
}

struct WeightHistoryPoint: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let kilograms: Double
}

struct ActivityHistoryPoint: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let averageMinutesPerDay: Int
}

struct TrainingProgressPoint: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let masteredTricks: Int
}

struct EvolutionMilestone: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let title: String
    let category: EvolutionMilestoneCategory
    let description: String
    let context: String
}

struct EvolutionOverview: Hashable, Sendable {
    let weightHistory: [WeightHistoryPoint]
    let activityHistory: [ActivityHistoryPoint]
    let trainingHistory: [TrainingProgressPoint]
    let milestones: [EvolutionMilestone]
    let healthyWeightRange: ClosedRange<Double>
    var currentWeight: Double {
        weightHistory.last?.kilograms ?? 0
    }

    var sixMonthWeightChange: Double {
        guard let first = weightHistory.first?.kilograms else { return 0 }
        return currentWeight - first
    }

    var currentActivity: Int {
        activityHistory.last?.averageMinutesPerDay ?? 0
    }

    var masteredTricks: Int {
        trainingHistory.last?.masteredTricks ?? 0
    }

    func weights(for range: EvolutionRange) -> [WeightHistoryPoint] {
        Array(weightHistory.suffix(range.pointCount))
    }

    func activities(for range: EvolutionRange) -> [ActivityHistoryPoint] {
        Array(activityHistory.suffix(range.pointCount))
    }

    func training(for range: EvolutionRange) -> [TrainingProgressPoint] {
        Array(trainingHistory.suffix(range.pointCount))
    }

}

enum EvolutionFormatting {
    static let spanishLocale = Locale(identifier: "es_ES")

    static func weight(_ value: Double) -> String {
        "\(decimal(value)) kg"
    }

    static func signedWeight(_ value: Double) -> String {
        let sign = value < 0 ? "−" : value > 0 ? "+" : ""
        return "\(sign)\(decimal(abs(value))) kg"
    }

    static func weightRange(_ value: ClosedRange<Double>) -> String {
        "\(decimal(value.lowerBound))–\(decimal(value.upperBound)) kg"
    }

    static func date(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle()
                .day()
                .month(.wide)
                .year()
                .locale(spanishLocale)
        )
    }

    static func month(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle()
                .month(.wide)
                .year()
                .locale(spanishLocale)
        )
    }

    static func shortMonth(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle()
                .month(.abbreviated)
                .locale(spanishLocale)
        )
    }

    private static func decimal(_ value: Double) -> String {
        value.formatted(
            .number
                .locale(spanishLocale)
                .precision(.fractionLength(1))
        )
    }
}
