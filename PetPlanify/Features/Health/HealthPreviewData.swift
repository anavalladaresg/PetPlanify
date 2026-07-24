import Foundation

enum HealthPreviewData {
    static let neoOverview = HealthOverview(
        weightRecords: zip(
            (1...6).map { date(2026, $0, 1) },
            [7.3, 7.1, 7.0, 6.9, 6.8, 6.8]
        ).enumerated().map {
            HealthWeightRecord(id: $0.offset, date: $0.element.0, kilograms: $0.element.1)
        },
        healthyWeightRange: 6.5 ... 7.5,
        vaccinations: [
            VaccinationRecord(
                id: 0,
                date: date(2023, 9, 28),
                title: "Puppy",
                details: "Moquillo y parvovirus",
                clinic: "Clínica VetSalud",
                status: .completed
            ),
            VaccinationRecord(
                id: 1,
                date: date(2023, 10, 25),
                title: "Refuerzo puppy",
                details: "Moquillo, parvovirus y hepatitis",
                clinic: "Clínica VetSalud",
                status: .completed
            ),
            VaccinationRecord(
                id: 2,
                date: date(2025, 5, 20),
                title: "Vacunación anual",
                details: "Polivalente y rabia",
                clinic: "Clínica VetSalud",
                status: .completed
            ),
            VaccinationRecord(
                id: 3,
                date: date(2026, 6, 12),
                title: "Vacuna anual",
                details: "Revisión de la pauta indicada en la cartilla",
                clinic: "Clínica VetSalud",
                status: .upcoming
            )
        ],
        medications: [
            MedicationRecord(
                id: 0,
                name: "Antiparasitario interno",
                startDate: date(2026, 3, 1),
                endDate: date(2026, 3, 3),
                notes: "Registro personal sin instrucciones de dosis.",
                status: .finished
            )
        ],
        visits: [
            VeterinaryVisit(
                id: 0,
                date: date(2026, 6, 25),
                reason: "Seguimiento general",
                clinic: "Clínica VetSalud",
                notes: "Cita futura. La valoración se añadirá manualmente después de la visita.",
                medications: [],
                followUpDate: nil,
                documents: [],
                status: .upcoming
            ),
            VeterinaryVisit(
                id: 1,
                date: date(2026, 3, 3),
                reason: "Consulta digestiva",
                clinic: "Clínica VetSalud",
                notes: "Valoración escrita manualmente: molestias digestivas puntuales.",
                medications: ["Dieta suave indicada durante la consulta"],
                followUpDate: date(2026, 3, 10),
                documents: [
                    HealthDocument(
                        id: 0,
                        filename: "Informe_consulta_digestiva.pdf",
                        fileType: "PDF",
                        fileSize: "480 KB",
                        updatedDate: date(2026, 3, 3)
                    )
                ],
                status: .completed
            ),
            VeterinaryVisit(
                id: 2,
                date: date(2025, 5, 20),
                reason: "Revisión anual",
                clinic: "Clínica VetSalud",
                notes: "Revisión anual registrada manualmente.",
                medications: [],
                followUpDate: date(2026, 6, 12),
                documents: [
                    HealthDocument(
                        id: 1,
                        filename: "Cartilla_vacunación.pdf",
                        fileType: "PDF",
                        fileSize: "1,2 MB",
                        updatedDate: date(2025, 5, 20)
                    )
                ],
                status: .completed
            )
        ]
    )

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = HealthFormatting.spanishLocale
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
