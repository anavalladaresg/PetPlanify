import Foundation

enum DailyCarePreviewData {
    static let observations = [
        PetObservation(
            id: 0,
            context: .nutrition,
            title: "Desayuno tranquilo",
            body: "Neo comió más despacio de lo habitual y terminó toda la ración.",
            date: PreviewData.date(daysFromReference: -7, hour: 8, minute: 15)
        )
    ]

    static var reminders: [CareReminder] {
        let health = HealthPreviewData.neoOverview
        var records: [CareReminder] = []

        if let vaccination = health.upcomingVaccination {
            records.append(
                CareReminder(
                    id: 0,
                    title: vaccination.title,
                    date: vaccination.date,
                    section: .health,
                    notes: "\(vaccination.details) · \(vaccination.clinic)",
                    isCompleted: false
                )
            )
        }

        if let visit = health.upcomingVisit {
            records.append(
                CareReminder(
                    id: 1,
                    title: "Próxima cita veterinaria",
                    date: visit.date,
                    section: .health,
                    notes: "\(visit.reason) · \(visit.clinic)",
                    isCompleted: false
                )
            )
        }

        records.append(contentsOf: health.dewormingRecords.compactMap { record in
            guard let dueDate = record.nextDueAt, dueDate > Date.now else { return nil }
            return CareReminder(
                id: record.kind == .internalDeworming ? 2 : 3,
                title: record.kind.reminderTitle,
                date: dueDate,
                section: .health,
                notes: record.productName ?? String(localized: "Cuidado registrado manualmente"),
                isCompleted: false
            )
        })

        records.append(
            CareReminder(
                id: 4,
                title: "Control mensual de peso",
                date: PreviewData.date(daysFromReference: 28, hour: 9),
                section: .health,
                notes: "Registrar el peso manualmente.",
                isCompleted: false
            )
        )

        return records.sorted { $0.date < $1.date }
    }
}
