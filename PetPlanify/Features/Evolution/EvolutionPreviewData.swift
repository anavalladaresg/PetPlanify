import Foundation

enum EvolutionPreviewData {
    static let neoOverview = EvolutionOverview(
        weightHistory: zip(
            monthDates,
            [7.3, 7.1, 7.0, 6.9, 6.8, 6.8]
        ).enumerated().map {
            WeightHistoryPoint(id: $0.offset, date: $0.element.0, kilograms: $0.element.1)
        },
        activityHistory: zip(
            monthDates,
            [24, 27, 29, 31, 34, 35]
        ).enumerated().map {
            ActivityHistoryPoint(
                id: $0.offset,
                date: $0.element.0,
                averageMinutesPerDay: $0.element.1
            )
        },
        trainingHistory: zip(
            monthDates,
            [1, 1, 2, 2, 3, 4]
        ).enumerated().map {
            TrainingProgressPoint(
                id: $0.offset,
                date: $0.element.0,
                masteredTricks: $0.element.1
            )
        },
        milestones: [
            EvolutionMilestone(
                id: 0,
                date: date(2026, 6, 12),
                title: String(localized: "Revisión veterinaria anual"),
                category: .health,
                description: String(localized: "Revisión general y vacunación anual registradas en el seguimiento de Neo."),
                context: String(localized: "Seguimiento veterinario")
            ),
            EvolutionMilestone(
                id: 1,
                date: date(2026, 5, 10),
                title: String(localized: "Inicio del plan de alimentación actual"),
                category: .nutrition,
                description: String(localized: "Comenzó el plan de ejemplo con dos comidas diarias de 120 g."),
                context: String(localized: "Cambio de rutina")
            ),
            EvolutionMilestone(
                id: 2,
                date: date(2026, 5, 9),
                title: String(localized: "Mejor respuesta al ver otros perros"),
                category: .training,
                description: String(localized: "Respondió mejor al aumentar la distancia y mantener una sesión tranquila."),
                context: String(localized: "Observación personal")
            ),
            EvolutionMilestone(
                id: 3,
                date: date(2026, 4, 28),
                title: String(localized: "Primer paseo largo de primavera"),
                category: .activity,
                description: String(localized: "Paseo prolongado registrado como parte de su actividad cotidiana."),
                context: String(localized: "Actividad registrada")
            ),
            EvolutionMilestone(
                id: 4,
                date: date(2026, 3, 3),
                title: String(localized: "Consulta digestiva"),
                category: .health,
                description: String(localized: "Consulta veterinaria registrada en el historial de salud."),
                context: String(localized: "Seguimiento veterinario")
            ),
            EvolutionMilestone(
                id: 5,
                date: date(2026, 1, 15),
                title: String(localized: "Peso registrado: 7,3 kg"),
                category: .weight,
                description: String(localized: "Primer registro de peso incluido en este periodo de seguimiento."),
                context: String(localized: "Dato manual")
            )
        ],
        healthyWeightRange: 6.5 ... 7.5
    )

    private static let monthDates = (1...6).map { month in
        date(2026, month, 1)
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = EvolutionFormatting.spanishLocale
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
            ?? Date(timeIntervalSince1970: 0)
    }
}
