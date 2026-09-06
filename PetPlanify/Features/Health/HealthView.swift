import SwiftUI

struct HealthView: View {
    @Environment(PetPlanifyStore.self) private var store
    @State private var sheet: HealthSheet?
    @State private var showObservation = false
    @State private var observation: PetObservation?
    @State private var showsAllObservations = false

    private var health: HealthData { store.snapshot.health }

    var body: some View {
        CarePage {
            if let next = nextCare {
                CareSection(title: "Próximo cuidado") {
                    HealthRecordRow(title: next.title, subtitle: AppFormat.date(next.date), symbol: next.symbol) {
                        sheet = next.sheet
                    }
                }
            }
            HealthWeightCard(onRegister: { sheet = .weight(nil) }, onHistory: { sheet = .history(.weights) })
            vaccines
            dewormings
            medications
            visits
            observations
            Text("Estos registros no sustituyen la valoración de un profesional veterinario.")
                .font(.caption).foregroundStyle(AppTheme.secondaryInk)
        }
        .accessibilityIdentifier("health.screen")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Registrar peso", systemImage: "scalemass") { sheet = .weight(nil) }
                    Button("Añadir vacuna", systemImage: "syringe") { sheet = .vaccine(nil) }
                    Button("Añadir desparasitación", systemImage: "pills") { sheet = .deworming(nil, .internalDeworming) }
                    Button("Añadir medicación", systemImage: "pills.fill") { sheet = .medication(nil) }
                    Button("Añadir cita veterinaria", systemImage: "cross.case") { sheet = .visit(nil) }
                    Button("Añadir observación", systemImage: "text.bubble") { observation = nil; showObservation = true }
                } label: { Label("Añadir registro", systemImage: "plus") }
                .accessibilityIdentifier("health.addRecord")
            }
        }
        .sheet(item: $sheet) { HealthSheetContent(sheet: $0) }
        .sheet(isPresented: $showObservation) { ObservationEditor(context: .health, record: observation) }
    }

    private var vaccines: some View {
        CareSection(title: "Vacunas") {
            if health.vaccines.isEmpty {
                Text("Añade las vacunas para conservar su historial.").foregroundStyle(AppTheme.secondaryInk)
            } else {
                ForEach(health.vaccines.sorted { $0.dateAdministered > $1.dateAdministered }.prefix(2)) { record in
                    HealthRecordRow(title: record.name, subtitle: vaccineSubtitle(record), status: record.status().title) {
                        sheet = .vaccine(record)
                    }
                }
            }
            HealthSectionActions(addTitle: "Añadir vacuna", onAdd: { sheet = .vaccine(nil) }, onHistory: { sheet = .history(.vaccines) })
        }
    }

    private var dewormings: some View {
        CareSection(title: "Desparasitación") {
            ForEach(DewormingKind.allCases) { kind in
                if let record = health.dewormings.filter({ $0.kind == kind }).max(by: { $0.applicationDate < $1.applicationDate }) {
                    HealthRecordRow(title: kind.title, subtitle: dewormingSubtitle(record), status: record.status().title) {
                        sheet = .deworming(record, kind)
                    }
                } else {
                    Button { sheet = .deworming(nil, kind) } label: {
                        Label("Añadir desparasitación \(kind.shortTitle.lowercased())", systemImage: kind.symbol)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.green)
                }
            }
            HealthSectionActions(addTitle: "Añadir aplicación", onAdd: { sheet = .deworming(nil, .internalDeworming) }, onHistory: { sheet = .history(.dewormings) })
        }
    }

    private var medications: some View {
        CareSection(title: "Medicación") {
            let active = health.medications.filter { $0.isActive() }.sorted { $0.startDate > $1.startDate }
            if active.isEmpty {
                Text("No hay medicamentos activos").foregroundStyle(AppTheme.secondaryInk)
            } else {
                ForEach(active.prefix(3)) { record in
                    HealthRecordRow(title: record.name, subtitle: String(localized: "Desde \(AppFormat.date(record.startDate))"), status: record.status().title) {
                        sheet = .medication(record)
                    }
                }
                if active.count > 3 {
                    Button("Ver los \(active.count) medicamentos activos") { sheet = .history(.medications) }
                }
            }
            HealthSectionActions(addTitle: "Añadir medicación", onAdd: { sheet = .medication(nil) }, onHistory: { sheet = .history(.medications) })
        }
    }

    private var visits: some View {
        CareSection(title: "Visitas veterinarias") {
            if health.visits.isEmpty {
                Text("Guarda citas, valoraciones y documentos en un mismo lugar.").foregroundStyle(AppTheme.secondaryInk)
            } else {
                ForEach(health.visits.sorted { $0.date > $1.date }.prefix(3)) { visit in
                    HealthRecordRow(title: visit.reason, subtitle: "\(AppFormat.date(visit.date))\(visit.clinic.isEmpty ? "" : " · \(visit.clinic)")", status: visit.status().title) {
                        sheet = .visitDetail(visit.id)
                    }
                }
            }
            HealthSectionActions(addTitle: "Añadir visita", onAdd: { sheet = .visit(nil) }, onHistory: { sheet = .history(.visits) })
            if !health.documents.isEmpty {
                Button("Documentos", systemImage: "doc") { sheet = .documents }
            }
        }
    }

    private var observations: some View {
        CareSection(title: "Observaciones de salud") {
            let records = health.observations.filter { $0.context == .health || $0.context == .general }.sorted { $0.date > $1.date }
            if records.isEmpty {
                Text("Anota cambios o detalles que quieras comentar en la próxima visita.").foregroundStyle(AppTheme.secondaryInk)
            }
            ForEach(Array(records.prefix(showsAllObservations ? records.count : 2))) { record in
                HealthRecordRow(title: record.title, subtitle: "\(AppFormat.date(record.date)) · \(record.body)") {
                    observation = record
                    showObservation = true
                }
            }
            if records.count > 2 {
                Button(showsAllObservations ? "Mostrar menos" : "Ver todas las observaciones") { showsAllObservations.toggle() }
            }
            Button("Añadir observación", systemImage: "plus") { observation = nil; showObservation = true }
                .buttonStyle(.bordered)
        }
    }

    private struct UpcomingCare {
        let title: String
        let date: Date
        let symbol: String
        let sheet: HealthSheet
    }

    private var nextCare: UpcomingCare? {
        let now = Date.now
        var items: [UpcomingCare] = []
        for record in health.vaccines {
            if let date = record.nextDueDate, date > now {
                items.append(.init(title: record.name, date: date, symbol: "syringe", sheet: .vaccine(record)))
            }
        }
        for kind in DewormingKind.allCases {
            if let record = health.dewormings.filter({ $0.kind == kind }).max(by: { $0.applicationDate < $1.applicationDate }),
               let date = record.nextDueDate, date > now {
                items.append(.init(title: kind.title, date: date, symbol: kind.symbol, sheet: .deworming(record, kind)))
            }
        }
        for visit in health.visits {
            if visit.date > now { items.append(.init(title: visit.reason, date: visit.date, symbol: "cross.case", sheet: .visitDetail(visit.id))) }
            if let date = visit.followUpDate, date > now {
                items.append(.init(title: String(localized: "Seguimiento: \(visit.reason)"), date: date, symbol: "cross.case", sheet: .visitDetail(visit.id)))
            }
        }
        for record in health.medications where record.isActive(relativeTo: now) {
            if let date = record.endDate, date > now {
                items.append(.init(title: String(localized: "Fin de medicación: \(record.name)"), date: date, symbol: "pills", sheet: .medication(record)))
            }
        }
        return items.min { $0.date < $1.date }
    }
}

func vaccineSubtitle(_ record: VaccinationRecord) -> String {
    let applied = String(localized: "Administrada: \(AppFormat.date(record.dateAdministered))")
    guard let next = record.nextDueDate else { return applied }
    return applied + " · " + String(localized: "Próxima: \(AppFormat.date(next))")
}

func dewormingSubtitle(_ record: DewormingRecord) -> String {
    let applied = String(localized: "Última aplicación: \(AppFormat.date(record.applicationDate))")
    guard let next = record.nextDueDate else { return applied }
    return applied + " · " + String(localized: "Próxima: \(AppFormat.date(next))")
}
