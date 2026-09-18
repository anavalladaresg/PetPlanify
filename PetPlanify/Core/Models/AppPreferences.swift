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

enum AppleCalendarAlertAdvance: Int, Codable, CaseIterable, Identifiable, Sendable {
    case none = 0, fiveMinutes = 5, tenMinutes = 10, fifteenMinutes = 15, thirtyMinutes = 30
    case oneHour = 60, twoHours = 120, oneDay = 1440, twoDays = 2880, oneWeek = 10080
    var id: Self { self }
    var title: String {
        switch self {
        case .none: String(localized: "Sin aviso")
        case .fiveMinutes: String(localized: "5 minutos antes")
        case .tenMinutes: String(localized: "10 minutos antes")
        case .fifteenMinutes: String(localized: "15 minutos antes")
        case .thirtyMinutes: String(localized: "30 minutos antes")
        case .oneHour: String(localized: "1 hora antes")
        case .twoHours: String(localized: "2 horas antes")
        case .oneDay: String(localized: "1 día antes")
        case .twoDays: String(localized: "2 días antes")
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
    var appleCalendarLinked = false
    var appleCalendarAlertAdvance: AppleCalendarAlertAdvance = .none
}

struct OnboardingState: Codable, Sendable, Equatable {
    var isComplete = false
    var dismissedSetupTasks: Set<String> = []
}
