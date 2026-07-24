import Foundation

enum WeightUnit: String, CaseIterable, Identifiable, Hashable, Sendable {
    case kilograms
    case pounds

    var id: Self { self }

    var title: String {
        switch self {
        case .kilograms: String(localized: "Kilogramos")
        case .pounds: String(localized: "Libras")
        }
    }

    func formattedWeight(kilograms: Double) -> String {
        let value = self == .kilograms ? kilograms : kilograms * 2.204_622_621_8
        let suffix = self == .kilograms ? "kg" : "lb"
        return "\(SettingsFormatting.decimal(value)) \(suffix)"
    }

    func formattedRange(_ range: ClosedRange<Double>) -> String {
        "\(SettingsFormatting.decimal(convert(range.lowerBound)))–\(SettingsFormatting.decimal(convert(range.upperBound))) \(shortTitle)"
    }

    private var shortTitle: String {
        self == .kilograms ? "kg" : "lb"
    }

    private func convert(_ kilograms: Double) -> Double {
        self == .kilograms ? kilograms : kilograms * 2.204_622_621_8
    }
}

enum DistanceUnit: String, CaseIterable, Identifiable, Hashable, Sendable {
    case kilometers
    case miles

    var id: Self { self }

    var title: String {
        switch self {
        case .kilometers: String(localized: "Kilómetros")
        case .miles: String(localized: "Millas")
        }
    }
}

enum TimeFormat: String, Hashable, Sendable {
    case twentyFourHours

    var title: String { String(localized: "24 horas") }
}

enum WeekStartDay: String, Hashable, Sendable {
    case monday

    var title: String { String(localized: "Lunes") }
}

enum AppLanguage: String, Hashable, Sendable {
    case spanish

    var title: String { String(localized: "Español") }
}

enum ReminderAdvanceTime: String, CaseIterable, Identifiable, Hashable, Sendable {
    case sameDay
    case oneDay
    case threeDays
    case oneWeek

    var id: Self { self }

    var title: String {
        switch self {
        case .sameDay: String(localized: "El mismo día")
        case .oneDay: String(localized: "1 día de antelación")
        case .threeDays: String(localized: "3 días de antelación")
        case .oneWeek: String(localized: "1 semana de antelación")
        }
    }
}

struct PetProfileSettings: Hashable, Sendable {
    let name: String
    let species: String
    let breed: String
    let birthDate: Date
    let sex: String
    let currentWeightKilograms: Double
    let healthyWeightRangeKilograms: ClosedRange<Double>?
    let microchipStatus: String
    let veterinaryClinic: String
    let referenceDate: Date

    var age: String {
        let years = Calendar(identifier: .gregorian)
            .dateComponents([.year], from: birthDate, to: referenceDate)
            .year ?? 0
        return years == 1
            ? String(localized: "1 año")
            : String(localized: "\(years) años")
    }
}

struct AppPreferences: Hashable, Sendable {
    let language: AppLanguage
    let dateFormat: String
    let timeFormat: TimeFormat
    let weekStartDay: WeekStartDay
    let appearance: String
}

struct ReminderPreferences: Hashable, Sendable {
    var healthEnabled: Bool
    var nutritionEnabled: Bool
    var trainingEnabled: Bool
    var advanceTime: ReminderAdvanceTime
}

struct AppInformation: Hashable, Sendable {
    let name: String
    let tagline: String
    let version: String
    let build: String
    let platforms: String
    let interfaceLanguage: String
    let technology: String
    let description: String
    let credit: String
}

struct SettingsOverview: Hashable, Sendable {
    let profile: PetProfileSettings
    let preferences: AppPreferences
    let appInformation: AppInformation
}

enum SettingsFutureAction: String, Identifiable, Hashable, Sendable {
    case editProfile
    case foodPlan
    case healthData
    case appearance
    case localStorage
    case iCloud
    case export
    case importData
    case backup
    case reset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .editProfile: String(localized: "Editar perfil")
        case .foodPlan: String(localized: "Editar alimentación")
        case .healthData: String(localized: "Editar datos de salud")
        case .appearance: String(localized: "Apariencia")
        case .localStorage: String(localized: "Almacenamiento local")
        case .iCloud: String(localized: "Sincronización con iCloud")
        case .export: String(localized: "Exportar datos")
        case .importData: String(localized: "Importar datos")
        case .backup: String(localized: "Crear copia de seguridad")
        case .reset: String(localized: "Restablecer datos")
        }
    }

    var symbol: String {
        switch self {
        case .editProfile: "pencil"
        case .foodPlan: "fork.knife"
        case .healthData: "cross.case"
        case .appearance: "sun.max"
        case .localStorage: "internaldrive"
        case .iCloud: "icloud"
        case .export: "square.and.arrow.up"
        case .importData: "square.and.arrow.down"
        case .backup: "externaldrive.badge.timemachine"
        case .reset: "arrow.counterclockwise"
        }
    }

    var explanation: String {
        switch self {
        case .editProfile:
            String(localized: "La edición del perfil estará disponible cuando se añada el almacenamiento de PetPlanify.")
        case .foodPlan:
            String(localized: "Aquí se editarán el alimento, la marca, las cantidades, los horarios y el número de comidas.")
        case .healthData:
            String(localized: "Aquí se editarán la clínica, el microchip y el rango de peso indicado manualmente.")
        case .appearance:
            String(localized: "PetPlanify utiliza actualmente una apariencia clara. Se estudiarán más opciones en una fase posterior.")
        case .localStorage:
            String(localized: "El almacenamiento local se añadirá en una fase posterior. Los datos actuales son de demostración.")
        case .iCloud:
            String(localized: "La sincronización con iCloud no está activa en esta versión.")
        case .export:
            String(localized: "La exportación estará disponible cuando PetPlanify incorpore almacenamiento permanente.")
        case .importData:
            String(localized: "La importación de datos todavía no está disponible.")
        case .backup:
            String(localized: "Las copias de seguridad se habilitarán cuando exista almacenamiento permanente.")
        case .reset:
            String(localized: "No hay datos permanentes que restablecer en esta versión.")
        }
    }
}

enum SettingsFormatting {
    static let spanishLocale = Locale(identifier: "es_ES")

    static func decimal(_ value: Double) -> String {
        value.formatted(
            .number
                .locale(spanishLocale)
                .precision(.fractionLength(1))
        )
    }

    static func date(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle(date: .long, time: .omitted, locale: spanishLocale)
        )
    }
}
