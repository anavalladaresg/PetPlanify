import Foundation

enum DailyCarePreviewData {
    static let observations = [
        PetObservation(
            id: 0,
            context: .nutrition,
            title: "Desayuno tranquilo",
            body: "Neo comió más despacio de lo habitual y terminó toda la ración.",
            date: date(2026, 6, 3, 8, 15)
        )
    ]

    static let reminders = [
        CareReminder(
            id: 0,
            title: "Vacuna anual",
            date: date(2026, 6, 12, 10, 30),
            section: .health,
            notes: "Vacuna anual en Clínica VetSalud.",
            isCompleted: false
        ),
        CareReminder(
            id: 1,
            title: "Próxima cita veterinaria",
            date: date(2026, 6, 25, 17),
            section: .health,
            notes: "Seguimiento general en Clínica VetSalud.",
            isCompleted: false
        ),
        CareReminder(
            id: 2,
            title: "Antiparasitario interno",
            date: date(2026, 7, 1, 9),
            section: .health,
            notes: "Recordatorio personal, sin instrucciones de dosis.",
            isCompleted: false
        ),
        CareReminder(
            id: 3,
            title: "Control mensual de peso",
            date: date(2026, 7, 5, 9),
            section: .health,
            notes: "Registrar el peso manualmente.",
            isCompleted: false
        )
    ]

    private static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 12,
        _ minute: Int = 0
    ) -> Date {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(identifier: "Europe/Madrid"),
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ).date!
    }
}
