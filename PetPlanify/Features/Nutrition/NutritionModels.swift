import Foundation

enum FoodType: String, Codable, Sendable, CaseIterable, Identifiable {
    case dryFood, wetFood, mixed, other
    var id: Self { self }
    var title: String {
        switch self {
        case .dryFood: String(localized: "Alimento seco")
        case .wetFood: String(localized: "Alimento húmedo")
        case .mixed: String(localized: "Mixto")
        case .other: String(localized: "Otro")
        }
    }
}
struct FoodProduct: Codable, Sendable, Equatable {
    var name = ""
    var brand = ""
    var type: FoodType = .dryFood
}
struct MealScheduleEntry: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var hour = 9
    var minute = 0
    var amountGrams: Double = 0
    var time: Date {
        get { Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now }
        set {
            hour = Calendar.current.component(.hour, from: newValue)
            minute = Calendar.current.component(.minute, from: newValue)
        }
    }
}
struct FoodPlan: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var product = FoodProduct()
    var dailyAmountGrams: Double = 0
    var meals: [MealScheduleEntry] = []
    var startDate = Date.now
    var notes = ""
    var validationError: String? {
        if product.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return String(localized: "Indica el alimento.") }
        if !dailyAmountGrams.isFinite || !(0.1...100_000).contains(dailyAmountGrams) { return String(localized: "Indica una cantidad diaria positiva.") }
        if !(1...8).contains(meals.count) { return String(localized: "Elige entre una y ocho comidas.") }
        if meals.contains(where: { !$0.amountGrams.isFinite || $0.amountGrams <= 0 || !(0...23).contains($0.hour) || !(0...59).contains($0.minute) }) { return String(localized: "Revisa las cantidades y los horarios de las comidas.") }
        if abs(meals.reduce(0) { $0 + $1.amountGrams } - dailyAmountGrams) > 0.5 { return String(localized: "Las cantidades de las comidas deben sumar la cantidad diaria.") }
        return nil
    }
}
struct FoodTransition: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var previousFood = ""
    var newFood = ""
    var startDate = Date.now
    var endDate = Date.now.addingTimeInterval(7 * 86_400)
    var progress: Double = 0
    var isComplete: Bool { progress >= 1 }
}
struct FoodHistoryEntry: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var plan: FoodPlan
    var endDate: Date
}
typealias NutritionObservation = PetObservation
struct NutritionData: Codable, Sendable, Equatable {
    var plan: FoodPlan?
    var transitions: [FoodTransition] = []
    var observations: [NutritionObservation] = []
    var history: [FoodHistoryEntry] = []
}
