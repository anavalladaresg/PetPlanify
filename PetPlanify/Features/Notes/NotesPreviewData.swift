import Foundation

enum NotesPreviewData {
    static let neoNotes: [PetNote] = [
        PetNote(
            id: 0,
            title: String(localized: "Después de la revisión veterinaria"),
            body: String(localized: "La revisión anual fue bien. Mantener seguimiento del peso y revisar la próxima vacuna en la fecha indicada."),
            createdAt: date(2026, 6, 12, 18, 20),
            updatedAt: date(2026, 6, 12, 19, 5),
            category: .health,
            isPinned: true,
            isArchived: false,
            tags: [String(localized: "revisión"), String(localized: "peso"), String(localized: "vacuna")]
        ),
        PetNote(
            id: 1,
            title: String(localized: "Mejor respuesta durante el paseo"),
            body: String(localized: "Neo mantuvo mejor la atención al aumentar la distancia respecto a otros perros y usar premios de alto valor."),
            createdAt: date(2026, 6, 9, 21, 10),
            updatedAt: nil,
            category: .training,
            isPinned: true,
            isArchived: false,
            tags: [String(localized: "paseo"), String(localized: "atención")]
        ),
        PetNote(
            id: 2,
            title: String(localized: "Cambio en el apetito"),
            body: String(localized: "Comió más despacio de lo habitual durante el desayuno, pero terminó toda la ración."),
            createdAt: date(2026, 6, 3, 8, 15),
            updatedAt: nil,
            category: .nutrition,
            isPinned: false,
            isArchived: false,
            tags: [String(localized: "desayuno"), String(localized: "apetito")]
        ),
        PetNote(
            id: 3,
            title: String(localized: "Paseo largo por Aldán"),
            body: String(localized: "Estuvo activo y tranquilo durante casi una hora. Descansó bien al volver a casa."),
            createdAt: date(2026, 5, 28, 19, 45),
            updatedAt: nil,
            category: .general,
            isPinned: false,
            isArchived: false,
            tags: [String(localized: "paseo"), String(localized: "descanso")]
        ),
        PetNote(
            id: 4,
            title: String(localized: "Observación sobre el agua"),
            body: String(localized: "Mostró inseguridad al acercarse a la orilla. No se forzó el contacto y se mantuvo una distancia cómoda."),
            createdAt: date(2026, 5, 20, 12, 30),
            updatedAt: date(2026, 5, 21, 9, 10),
            category: .training,
            isPinned: false,
            isArchived: false,
            tags: [String(localized: "agua"), String(localized: "paseo")]
        ),
        PetNote(
            id: 5,
            title: String(localized: "Peso registrado"),
            body: String(localized: "Peso manual registrado: 6,8 kg."),
            createdAt: date(2026, 5, 15, 9, 0),
            updatedAt: nil,
            category: .health,
            isPinned: false,
            isArchived: false,
            tags: [String(localized: "peso"), String(localized: "registro manual")]
        ),
        PetNote(
            id: 6,
            title: String(localized: "Nueva comida"),
            body: String(localized: "Inicio progresivo del alimento actual con buena tolerancia."),
            createdAt: date(2026, 5, 2, 17, 40),
            updatedAt: nil,
            category: .nutrition,
            isPinned: false,
            isArchived: true,
            tags: [String(localized: "alimento"), String(localized: "transición")]
        ),
        PetNote(
            id: 7,
            title: String(localized: "Nota general de primavera"),
            body: String(localized: "Más interés por los paseos al aumentar las horas de luz."),
            createdAt: date(2026, 4, 22, 20, 0),
            updatedAt: nil,
            category: .general,
            isPinned: false,
            isArchived: true,
            tags: [String(localized: "primavera"), String(localized: "paseo")]
        )
    ]

    static let neoOverview = NotesOverview(notes: neoNotes)

    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int
    ) -> Date {
        NotesFormatting.spanishCalendar.date(
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
