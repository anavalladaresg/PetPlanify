import Foundation

enum HealthPreviewData {
    static let neoOverview = HealthOverview(
        vaccinations: [
            VaccinationRecord(
                id: 0,
                date: date(2023, 9, 28),
                title: String(localized: "Puppy"),
                details: String(localized: "Moquillo y parvovirus"),
                status: .completed
            ),
            VaccinationRecord(
                id: 1,
                date: date(2023, 10, 25),
                title: String(localized: "Refuerzo puppy"),
                details: String(localized: "Moquillo, parvovirus y hepatitis"),
                status: .completed
            ),
            VaccinationRecord(
                id: 2,
                date: date(2023, 11, 23),
                title: String(localized: "Segundo refuerzo puppy"),
                details: String(localized: "Moquillo, parvovirus y hepatitis"),
                status: .completed
            ),
            VaccinationRecord(
                id: 3,
                date: date(2025, 5, 20),
                title: String(localized: "Revisión veterinaria anual"),
                details: String(localized: "Polivalente y rabia"),
                status: .completed
            ),
            VaccinationRecord(
                id: 4,
                date: date(2026, 6, 12),
                title: String(localized: "Vacunación anual"),
                details: String(localized: "Polivalente y rabia"),
                status: .upcoming
            )
        ],
        medicationHistory: [
            MedicationRecord(
                id: 0,
                name: String(localized: "Antiparasitario interno"),
                startDate: date(2026, 3, 1),
                endDate: date(2026, 3, 3),
                status: .finished
            )
        ],
        symptoms: [
            SymptomRecord(
                id: 0,
                date: date(2026, 5, 6),
                name: String(localized: "Heces blandas"),
                notes: String(localized: "Observado durante el paseo de la mañana."),
                severity: .mild,
                status: .resolved
            ),
            SymptomRecord(
                id: 1,
                date: date(2026, 2, 18),
                name: String(localized: "Picor en las orejas"),
                notes: String(localized: "Observado durante un día."),
                severity: .mild,
                status: .resolved
            )
        ],
        visits: [
            VeterinaryVisit(
                id: 0,
                date: date(2026, 6, 12),
                reason: String(localized: "Revisión anual y vacunación"),
                clinic: String(localized: "Clínica VetSalud"),
                status: .upcoming
            ),
            VeterinaryVisit(
                id: 1,
                date: date(2025, 5, 20),
                reason: String(localized: "Revisión anual"),
                clinic: String(localized: "Clínica VetSalud"),
                status: .completed
            ),
            VeterinaryVisit(
                id: 2,
                date: date(2025, 3, 3),
                reason: String(localized: "Consulta digestiva"),
                clinic: String(localized: "Clínica VetSalud"),
                status: .completed
            )
        ],
        documents: [
            HealthDocument(
                id: 0,
                filename: "Cartilla_vacunación.pdf",
                fileType: "PDF",
                fileSize: "1,2 MB",
                updatedDate: date(2025, 5, 20)
            ),
            HealthDocument(
                id: 1,
                filename: "Análisis_sangre_2025.pdf",
                fileType: "PDF",
                fileSize: "480 KB",
                updatedDate: date(2025, 3, 3)
            )
        ]
    )

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = HealthFormatting.spanishLocale
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
            ?? Date(timeIntervalSince1970: 0)
    }
}
