import Foundation

enum DailyCarePreviewData {
    static let observations = [
        PetObservation(
            id: 0,
            context: .nutrition,
            title: "Desayuno tranquilo",
            body: "Neo comió más despacio de lo habitual y terminó toda la ración.",
            date: date(2026, 6, 3, 8, 15)
        ),
        PetObservation(
            id: 1,
            context: .health,
            title: "Después de la revisión",
            body: "Mantener el seguimiento del peso y revisar la próxima vacuna en la fecha indicada.",
            date: date(2026, 6, 12, 18, 20)
        ),
        PetObservation(
            id: 2,
            context: .training,
            title: "Mejor respuesta durante el paseo",
            body: "Neo mantuvo mejor la atención al aumentar la distancia respecto a otros perros.",
            date: date(2026, 6, 9, 21, 10)
        )
    ]

    static let reminders = [
        CareReminder(
            id: 0,
            title: "Revisión veterinaria anual",
            date: date(2026, 6, 12, 10, 30),
            section: .health,
            notes: "Revisión general y vacuna anual.",
            isCompleted: false
        ),
        CareReminder(
            id: 1,
            title: "Comprar comida",
            date: date(2026, 6, 18, 19),
            section: .nutrition,
            notes: "Queda aproximadamente una semana de alimento.",
            isCompleted: false
        ),
        CareReminder(
            id: 2,
            title: "Practicar «quieto»",
            date: date(2026, 6, 20, 18),
            section: .training,
            notes: "Sesión breve.",
            isCompleted: false
        ),
        CareReminder(
            id: 3,
            title: "Control mensual de peso",
            date: date(2026, 7, 1, 9),
            section: .evolution,
            notes: "Registrar el peso manualmente.",
            isCompleted: false
        ),
        CareReminder(
            id: 4,
            title: "Revisar cartilla veterinaria",
            date: date(2026, 5, 5, 12),
            section: .health,
            notes: "Pendiente desde el 5 de mayo.",
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
