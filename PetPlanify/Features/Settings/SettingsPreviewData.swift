import Foundation

enum SettingsPreviewData {
    private static let calendar = Calendar(identifier: .gregorian)
    private static let bundle = Bundle.main

    static let neoProfile = PetProfileSettings(
        name: "Neo",
        species: "Perro",
        breed: "Teckel",
        birthDate: calendar.date(from: DateComponents(year: 2023, month: 8, day: 15))!,
        sex: "Macho",
        currentWeightKilograms: 6.8,
        healthyWeightRangeKilograms: 6.5 ... 7.5,
        microchipStatus: "No registrado",
        veterinaryClinic: "Clínica VetSalud",
        referenceDate: calendar.date(from: DateComponents(year: 2026, month: 6, day: 12))!
    )

    static let preferences = AppPreferences(
        language: .spanish,
        dateFormat: "Día / mes / año",
        timeFormat: .twentyFourHours,
        weekStartDay: .monday,
        appearance: "Clara"
    )

    static let reminderPreferences = ReminderPreferences(
        healthEnabled: true,
        nutritionEnabled: true,
        trainingEnabled: false,
        advanceTime: .oneDay
    )

    static let dataSummaries = [
        DataCategorySummary(id: "health", title: "Salud", count: 14, symbol: "heart"),
        DataCategorySummary(id: "nutrition", title: "Alimentación", count: 18, symbol: "fork.knife"),
        DataCategorySummary(id: "training", title: "Entrenamiento", count: 12, symbol: "figure.walk"),
        DataCategorySummary(id: "evolution", title: "Evolución", count: 24, symbol: "chart.line.uptrend.xyaxis"),
        DataCategorySummary(id: "reminders", title: "Recordatorios", count: 8, symbol: "calendar.badge.clock"),
        DataCategorySummary(id: "notes", title: "Notas", count: 8, symbol: "note.text")
    ]

    static let appInformation = AppInformation(
        name: "PetPlanify",
        tagline: "El diario personal de Neo",
        version: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0",
        build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1",
        platforms: "iPhone y Mac",
        interfaceLanguage: "Español",
        technology: "SwiftUI",
        description: "PetPlanify reúne la alimentación, salud, entrenamiento, evolución, recordatorios y notas de Neo en un único espacio.",
        credit: "Diseñado y desarrollado por Ana Valladares."
    )

    static let overview = SettingsOverview(
        profile: neoProfile,
        preferences: preferences,
        dataSummaries: dataSummaries,
        appInformation: appInformation
    )
}
