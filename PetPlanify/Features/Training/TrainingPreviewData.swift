import Foundation

enum TrainingPreviewData {
    static let referenceDate = date(2026, 5, 12, 20, 0)

    static let neoOverview = TrainingOverview(
        tricks: [
            TrainingTrick(
                id: 0,
                name: String(localized: "Sentado"),
                status: .mastered,
                progress: 100,
                successfulRepetitions: 24,
                lastPractised: .today,
                reward: .treats
            ),
            TrainingTrick(
                id: 1,
                name: String(localized: "Quieto"),
                status: .inProgress,
                progress: 80,
                successfulRepetitions: 16,
                lastPractised: .today,
                reward: .treats
            ),
            TrainingTrick(
                id: 2,
                name: String(localized: "Ven aquí"),
                status: .inProgress,
                progress: 60,
                successfulRepetitions: 11,
                lastPractised: .yesterday,
                reward: .treatsAndPraise
            ),
            TrainingTrick(
                id: 3,
                name: String(localized: "Toca"),
                status: .inProgress,
                progress: 40,
                successfulRepetitions: 7,
                lastPractised: .date(date(2026, 5, 10)),
                reward: .treats
            ),
            TrainingTrick(
                id: 4,
                name: String(localized: "Déjalo"),
                status: .notStarted,
                progress: 0,
                successfulRepetitions: 0,
                lastPractised: .never,
                reward: .treats
            )
        ],
        sessions: [
            TrainingSession(
                id: 0,
                date: date(2026, 5, 12, 18, 10),
                type: String(localized: "Sesión corta"),
                durationMinutes: 15,
                tricks: [String(localized: "Sentado"), String(localized: "Quieto")],
                result: String(localized: "Buena concentración")
            ),
            TrainingSession(
                id: 1,
                date: date(2026, 5, 11, 17, 30),
                type: String(localized: "Paseo y entrenamiento"),
                durationMinutes: 25,
                tricks: [String(localized: "Ven aquí")],
                result: String(localized: "Algunas distracciones")
            ),
            TrainingSession(
                id: 2,
                date: date(2026, 5, 10, 12, 0),
                type: String(localized: "Sesión corta"),
                durationMinutes: 10,
                tricks: [String(localized: "Quieto")],
                result: String(localized: "Progreso mantenido")
            )
        ],
        behaviorNotes: [
            BehaviorNote(
                id: 0,
                date: date(2026, 5, 9),
                title: String(localized: "Reactividad al ver otros perros"),
                description: String(localized: "Neo se excita al ver perros grandes y quiere acercarse. Mejoró al aumentar la distancia y usar premios de alto valor."),
                status: .working,
                tags: [String(localized: "Paseo"), String(localized: "Otros perros")]
            ),
            BehaviorNote(
                id: 1,
                date: date(2026, 5, 4),
                title: String(localized: "Inseguridad cerca del agua"),
                description: String(localized: "Mostró incomodidad al acercarse a la orilla. Se evitó forzar el contacto."),
                status: .observation,
                tags: [String(localized: "Agua"), String(localized: "Confianza")]
            ),
            BehaviorNote(
                id: 2,
                date: date(2026, 4, 28),
                title: String(localized: "Mejor respuesta a “quieto”"),
                description: String(localized: "Mantuvo la posición durante varios segundos con una distracción leve."),
                status: .improvement,
                tags: [String(localized: "Quieto"), String(localized: "Concentración")]
            )
        ],
        weeklyMinutes: 75
    )

    private static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 12,
        _ minute: Int = 0
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = TrainingFormatting.spanishLocale
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        return calendar.date(
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
