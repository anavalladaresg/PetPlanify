import Foundation

enum RemindersPreviewData {
    static let referenceDate = date(2026, 6, 12, 8, 0)

    static let neoReminders: [PetReminder] = [
        PetReminder(
            id: 0,
            title: String(localized: "Revisión veterinaria anual"),
            date: date(2026, 6, 12, 10, 30),
            category: .health,
            priority: .high,
            status: .upcoming,
            notes: String(localized: "Revisión general y vacuna anual"),
            recurrence: .yearly
        ),
        PetReminder(
            id: 1,
            title: String(localized: "Dar antiparasitario interno"),
            date: date(2026, 6, 15, 9, 0),
            category: .medication,
            priority: .medium,
            status: .upcoming,
            notes: String(localized: "Registro personal sin instrucciones de dosis"),
            recurrence: .none
        ),
        PetReminder(
            id: 2,
            title: String(localized: "Comprar comida"),
            date: date(2026, 6, 18, 19, 0),
            category: .nutrition,
            priority: .medium,
            status: .upcoming,
            notes: String(localized: "Queda aproximadamente una semana de alimento"),
            recurrence: .monthly
        ),
        PetReminder(
            id: 3,
            title: String(localized: "Practicar “quieto”"),
            date: date(2026, 6, 20, 18, 0),
            category: .training,
            priority: .low,
            status: .upcoming,
            notes: String(localized: "Sesión breve"),
            recurrence: .none
        ),
        PetReminder(
            id: 4,
            title: String(localized: "Control mensual de peso"),
            date: date(2026, 7, 1, 9, 0),
            category: .weight,
            priority: .low,
            status: .upcoming,
            notes: String(localized: "Registrar el peso manualmente"),
            recurrence: .monthly
        ),
        PetReminder(
            id: 5,
            title: String(localized: "Revisar cartilla veterinaria"),
            date: date(2026, 5, 5, 12, 0),
            category: .health,
            priority: .medium,
            status: .overdue,
            notes: String(localized: "Comprobar que los registros personales estén actualizados"),
            recurrence: .yearly
        ),
        PetReminder(
            id: 6,
            title: String(localized: "Sesión de entrenamiento"),
            date: date(2026, 5, 10, 18, 30),
            category: .training,
            priority: .low,
            status: .completed,
            notes: String(localized: "Sesión breve de práctica"),
            recurrence: .none
        ),
        PetReminder(
            id: 7,
            title: String(localized: "Vacunación anual"),
            date: date(2026, 5, 20, 9, 0),
            category: .health,
            priority: .high,
            status: .completed,
            notes: String(localized: "Registro personal del recordatorio anual"),
            recurrence: .yearly
        )
    ]

    static let neoOverview = ReminderOverview(
        reminders: neoReminders,
        referenceDate: referenceDate
    )

    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int
    ) -> Date {
        ReminderFormatting.spanishCalendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        ) ?? Date(timeIntervalSince1970: 0)
    }
}
