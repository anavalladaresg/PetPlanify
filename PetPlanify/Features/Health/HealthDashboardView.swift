import SwiftUI

struct HealthHistoryView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let kind: HealthHistoryKind
    @State private var sheet: HealthSheet?

    var body: some View {
        NavigationStack {
            List {
                records
                    .listRowBackground(AppTheme.surface)
            }
            .overlay {
                if recordCount == 0 {
                    ContentUnavailableView {
                        Label("Todavía no hay registros", systemImage: "cross.case")
                    } actions: {
                        Button("Añadir registro", systemImage: "plus") { sheet = kind.createSheet }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .appCanvas()
            .navigationTitle(kind.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Añadir registro", systemImage: "plus") { sheet = kind.createSheet }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, idealWidth: 620, minHeight: 420, idealHeight: 640)
        #endif
        .sheet(item: $sheet) { HealthSheetContent(sheet: $0) }
    }

    @ViewBuilder private var records: some View {
        switch kind {
        case .weights:
            ForEach(store.snapshot.health.weights.sorted { $0.date > $1.date }) { record in
                HealthRecordRow(title: AppFormat.weight(record.weight, unit: store.snapshot.preferences.weightUnit), subtitle: AppFormat.date(record.date) + (record.note.map { " · \($0)" } ?? ""), symbol: "scalemass", isHistorical: true) {
                    sheet = .weight(record)
                }
            }
        case .vaccines:
            ForEach(store.snapshot.health.vaccines.sorted { $0.dateAdministered > $1.dateAdministered }) { record in
                HealthRecordRow(title: record.name, subtitle: vaccineSubtitle(record), symbol: "syringe", status: record.status().title, statusColor: record.status().displayColor, isHistorical: record.nextDueDate == nil) { sheet = .vaccine(record) }
            }
        case .dewormings:
            ForEach(store.snapshot.health.dewormings.sorted { $0.applicationDate > $1.applicationDate }) { record in
                HealthRecordRow(title: record.kind.title + (record.productName.map { " · \($0)" } ?? ""), subtitle: dewormingSubtitle(record), symbol: record.kind.symbol, status: record.status().title, statusColor: record.status().displayColor, isHistorical: record.nextDueDate == nil) {
                    sheet = .deworming(record, record.kind)
                }
            }
        case .medications:
            ForEach(store.snapshot.health.medications.sorted { $0.startDate > $1.startDate }) { record in
                HealthRecordRow(title: record.name, subtitle: AppFormat.date(record.startDate) + (record.endDate.map { " – \(AppFormat.date($0))" } ?? ""), symbol: "pills", status: record.status().title, statusColor: record.status().displayColor, isHistorical: !record.isActive()) {
                    sheet = .medication(record)
                }
            }
        case .visits:
            ForEach(store.snapshot.health.visits.sorted { $0.date > $1.date }) { visit in
                HealthVisitRow(visit: visit) { sheet = .visitDetail(visit.id) }
            }
        }
    }

    private var recordCount: Int {
        switch kind {
        case .weights: store.snapshot.health.weights.count
        case .vaccines: store.snapshot.health.vaccines.count
        case .dewormings: store.snapshot.health.dewormings.count
        case .medications: store.snapshot.health.medications.count
        case .visits: store.snapshot.health.visits.count
        }
    }
}
