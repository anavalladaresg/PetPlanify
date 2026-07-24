import Foundation

enum HealthPreviewData {
    static let neoOverview = HealthOverview(
        weightRecords: zip(
            (-5...0).map { PreviewData.monthStart(monthsFromReference: $0) },
            [7.3, 7.1, 7.0, 6.9, 6.8, 6.8]
        ).enumerated().map {
            HealthWeightRecord(id: $0.offset, date: $0.element.0, kilograms: $0.element.1)
        },
        healthyWeightRange: 6.5 ... 7.5,
        vaccinations: [
            VaccinationRecord(
                id: 0,
                date: PreviewData.date(daysFromReference: -500),
                title: "Puppy",
                details: "Moquillo y parvovirus",
                clinic: "Clínica VetSalud",
                status: .completed
            ),
            VaccinationRecord(
                id: 1,
                date: PreviewData.date(daysFromReference: -450),
                title: "Refuerzo puppy",
                details: "Moquillo, parvovirus y hepatitis",
                clinic: "Clínica VetSalud",
                status: .completed
            ),
            VaccinationRecord(
                id: 2,
                date: PreviewData.date(daysFromReference: -90),
                title: "Vacunación anual",
                details: "Polivalente y rabia",
                clinic: "Clínica VetSalud",
                status: .completed
            ),
            VaccinationRecord(
                id: 3,
                date: PreviewData.date(daysFromReference: 19, hour: 10, minute: 30),
                title: "Vacuna anual",
                details: "Revisión de la pauta indicada en la cartilla",
                clinic: "Clínica VetSalud",
                status: .upcoming
            )
        ],
        dewormingRecords: [
            DewormingRecord(
                id: UUID(uuidString: "6DB91D40-C1EA-4AA6-B1D8-05657420D175")!,
                kind: .internalDeworming,
                productName: String(localized: "Comprimido"),
                administeredAt: PreviewData.date(daysFromReference: -75, hour: 9),
                nextDueAt: PreviewData.date(daysFromReference: 8, hour: 9),
                notes: String(localized: "Registro personal sin instrucciones de dosis.")
            ),
            DewormingRecord(
                id: UUID(uuidString: "8AF96DB7-B88C-4E9D-8C82-B83DF90F04BD")!,
                kind: .externalDeworming,
                productName: String(localized: "Pipeta"),
                administeredAt: PreviewData.date(daysFromReference: -21, hour: 18),
                nextDueAt: PreviewData.date(daysFromReference: 15, hour: 18),
                notes: String(localized: "Aplicación registrada manualmente.")
            )
        ],
        medications: [
            MedicationRecord(
                id: 0,
                name: "Antiparasitario interno",
                startDate: PreviewData.date(daysFromReference: -45),
                endDate: PreviewData.date(daysFromReference: -43),
                notes: "Registro personal sin instrucciones de dosis.",
                status: .finished
            )
        ],
        visits: [
            VeterinaryVisit(
                id: 0,
                date: PreviewData.date(daysFromReference: 32, hour: 17),
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
                date: PreviewData.date(daysFromReference: -70),
                reason: "Consulta digestiva",
                clinic: "Clínica VetSalud",
                notes: "Valoración escrita manualmente: molestias digestivas puntuales.",
                medications: ["Dieta suave indicada durante la consulta"],
                followUpDate: PreviewData.date(daysFromReference: -63),
                documents: [
                    HealthDocument(
                        id: 0,
                        filename: "Informe_consulta_digestiva.pdf",
                        fileType: "PDF",
                        fileSize: "480 KB",
                        updatedDate: PreviewData.date(daysFromReference: -70)
                    )
                ],
                status: .completed
            ),
            VeterinaryVisit(
                id: 2,
                date: PreviewData.date(daysFromReference: -300),
                reason: "Revisión anual",
                clinic: "Clínica VetSalud",
                notes: "Revisión anual registrada manualmente.",
                medications: [],
                followUpDate: PreviewData.date(daysFromReference: -90),
                documents: [
                    HealthDocument(
                        id: 1,
                        filename: "Cartilla_vacunación.pdf",
                        fileType: "PDF",
                        fileSize: "1,2 MB",
                        updatedDate: PreviewData.date(daysFromReference: -300)
                    )
                ],
                status: .completed
            )
        ]
    )

}
