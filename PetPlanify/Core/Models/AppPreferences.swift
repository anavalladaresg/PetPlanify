import Foundation

enum WeightUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case kilograms, pounds
    var id: Self { self }
    var title: String { self == .kilograms ? String(localized: "Kilogramos") : String(localized: "Libras") }
    var symbol: String { self == .kilograms ? "kg" : "lb" }
    func fromKilograms(_ value: Double) -> Double { self == .kilograms ? value : value * 2.2046226218487757 }
    func kilograms(from value: Double) -> Double { self == .kilograms ? value : value / 2.2046226218487757 }
}

enum DistanceUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case kilometers, miles
    var id: Self { self }
    var title: String { self == .kilometers ? String(localized: "Kilómetros") : String(localized: "Millas") }
}

enum AppAppearance: String, Codable, CaseIterable, Identifiable, Sendable {
    case system, light, dark
    var id: Self { self }
    var title: String {
        switch self {
        case .system: String(localized: "Sistema")
        case .light: String(localized: "Claro")
        case .dark: String(localized: "Oscuro")
        }
    }
}

enum ReminderAdvanceTime: Int, Codable, CaseIterable, Identifiable, Sendable {
    case sameDay = 0, oneDay = 1, threeDays = 3, oneWeek = 7
    var id: Self { self }
    var title: String {
        switch self {
        case .sameDay: String(localized: "El mismo día")
        case .oneDay: String(localized: "1 día antes")
        case .threeDays: String(localized: "3 días antes")
        case .oneWeek: String(localized: "1 semana antes")
        }
    }
}

struct ReminderPreferences: Codable, Sendable, Equatable {
    var notificationsEnabled = false
    var healthEnabled = true
    var nutritionEnabled = true
    var trainingEnabled = true
    var advanceTime: ReminderAdvanceTime = .sameDay
}

struct AppPreferences: Codable, Sendable, Equatable {
    var weightUnit: WeightUnit = .kilograms
    var distanceUnit: DistanceUnit = .kilometers
    var appearance: AppAppearance = .system
    var reminders = ReminderPreferences()
    var iCloudEnabled = false
}

struct OnboardingState: Codable, Sendable, Equatable {
    var isComplete = false
    var dismissedSetupTasks: Set<String> = []
}
