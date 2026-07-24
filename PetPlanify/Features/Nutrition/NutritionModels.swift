import Foundation

enum FoodType: Sendable {
    case dryFood

    var localizedName: String {
        switch self {
        case .dryFood:
            String(localized: "Alimento seco")
        }
    }
}
struct FoodProduct: Sendable {
    let name: String
    let brand: String
    let type: FoodType
}

enum MealKind: Sendable {
    case breakfast
    case dinner

    var localizedName: String {
        switch self {
        case .breakfast:
            String(localized: "Desayuno")
        case .dinner:
            String(localized: "Cena")
        }
    }
}

struct ScheduledMeal: Identifiable, Sendable {
    let id: Int
    let kind: MealKind
    let time: String
    let amountGrams: Int
}

struct FoodTransition: Sendable {
    let previousFood: FoodProduct
    let currentFood: FoodProduct
    let progress: Double
    let completionDate: Date
}

struct FoodHistoryEntry: Identifiable, Sendable {
    let id: Int
    let food: FoodProduct
    let startDate: Date
    let endDate: Date?
}

struct FoodPlan: Sendable {
    let currentFood: FoodProduct
    let startDate: Date
    let dailyAmountGrams: Int
    let mealsPerDay: Int
    let meals: [ScheduledMeal]
    let transition: FoodTransition
    let foodHistory: [FoodHistoryEntry]
}

enum NutritionFormatting {
    static let spanishLocale = Locale(identifier: "es_ES")

    static func grams(_ value: Int) -> String {
        "\(value.formatted(.number.locale(spanishLocale))) g"
    }

    static func weight(_ value: Double) -> String {
        "\(decimal(value)) kg"
    }

    static func weightRange(_ range: ClosedRange<Double>) -> String {
        "\(decimal(range.lowerBound))–\(decimal(range.upperBound)) kg"
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

    static func shortDate(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle()
                .day()
                .month(.abbreviated)
                .year()
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
