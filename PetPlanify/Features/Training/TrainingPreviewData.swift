import Foundation

enum TrainingPreviewData {
    static let library: [TrickDefinition] = [
        trick("sentado", "Sentado", "figure.seated.side", .easy, .basic),
        trick("quieto", "Quieto", "hand.raised", .medium, .safety, prerequisites: ["Sentado"]),
        trick("ven-aqui", "Ven aquí", "arrow.down.to.line", .medium, .safety),
        trick("tumba", "Tumba", "arrow.down", .easy, .basic, prerequisites: ["Sentado"]),
        trick("dejalo", "Déjalo", "hand.raised.slash", .medium, .safety),
        trick("suelta", "Suelta", "mouth", .medium, .safety),
        trick("junto", "Junto", "figure.walk", .advanced, .coexistence),
        trick("a-tu-sitio", "A tu sitio", "house", .medium, .coexistence),
        trick("pata", "Pata", "hand.wave", .easy, .fun, prerequisites: ["Sentado"]),
        trick("toca", "Toca", "hand.point.up.left", .easy, .fun),
        trick("gira", "Gira", "arrow.trianglehead.2.clockwise", .medium, .fun)
    ]

    static let neoOverview = TrainingOverview(
        selectedTricks: [
            SelectedTrick(definition: library[0], status: .mastered, progress: 100),
            SelectedTrick(definition: library[1], status: .learning, progress: 75),
            SelectedTrick(definition: library[2], status: .learning, progress: 55),
            SelectedTrick(definition: library[3], status: .notStarted, progress: 0),
            SelectedTrick(definition: library[8], status: .notStarted, progress: 0)
        ],
        library: library,
        behaviorObservations: [
            BehaviorObservation(
                id: 0,
                date: date(2026, 6, 9),
                title: "Mejor respuesta al ver otros perros",
                body: "Neo mantuvo mejor la atención al aumentar la distancia.",
                helpfulContext: "Ayudó mantener una distancia cómoda y usar premios."
            ),
            BehaviorObservation(
                id: 1,
                date: date(2026, 5, 20),
                title: "Inseguridad cerca del agua",
                body: "Se detuvo antes de acercarse a la orilla.",
                helpfulContext: "Ayudó no forzar el contacto y permitirle observar."
            )
        ]
    )

    private static func trick(
        _ id: String,
        _ name: String,
        _ symbol: String,
        _ difficulty: TrickDifficulty,
        _ category: TrickCategory,
        prerequisites: [String] = []
    ) -> TrickDefinition {
        TrickDefinition(
            id: id,
            name: name,
            symbol: symbol,
            difficulty: difficulty,
            category: category,
            prerequisites: prerequisites,
            guide: TrickGuide(
                objective: "Asociar la señal «\(name.lowercased())» con una conducta clara y voluntaria.",
                materials: "Premios pequeños, un entorno tranquilo y sesiones breves.",
                steps: [
                    "Empieza en un lugar con pocas distracciones.",
                    "Guía la conducta con calma y marca el momento correcto.",
                    "Añade la señal verbal cuando Neo anticipe el movimiento.",
                    "Reduce la ayuda poco a poco y practica en contextos sencillos."
                ],
                commonMistakes: [
                    "Repetir la señal muchas veces.",
                    "Alargar el intento cuando Neo pierde atención."
                ],
                recommendedAttempt: "Entre 2 y 4 minutos, con pausas.",
                reward: "Un premio pequeño o una actividad que Neo valore.",
                advancement: "Avanza cuando responda con calma en varias repeticiones sencillas.",
                precautions: "No fuerces posturas ni continúes si muestra incomodidad o estrés."
            )
        )
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
