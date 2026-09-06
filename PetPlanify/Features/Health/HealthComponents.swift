import SwiftUI

enum HealthSheet: Identifiable {
    case weight(WeightRecord?)
    case vaccine(VaccinationRecord?)
    case deworming(DewormingRecord?, DewormingKind)
    case medication(MedicationRecord?)
    case visit(VeterinaryVisit?)
    case visitDetail(UUID)
    case history(HealthHistoryKind)
    case documents

    var id: String {
        switch self {
        case let .weight(record): "weight-\(record?.id.uuidString ?? "new")"
        case let .vaccine(record): "vaccine-\(record?.id.uuidString ?? "new")"
        case let .deworming(record, kind): "deworming-\(record?.id.uuidString ?? kind.rawValue)"
        case let .medication(record): "medication-\(record?.id.uuidString ?? "new")"
        case let .visit(record): "visit-\(record?.id.uuidString ?? "new")"
        case let .visitDetail(id): "visit-detail-\(id)"
        case let .history(kind): "history-\(kind.rawValue)"
        case .documents: "documents"
        }
    }
}

enum HealthHistoryKind: String, Identifiable {
    case weights, vaccines, dewormings, medications, visits
    var id: Self { self }
    var title: String {
        switch self {
        case .weights: String(localized: "Historial de peso")
        case .vaccines: String(localized: "Historial de vacunas")
        case .dewormings: String(localized: "Historial de desparasitación")
        case .medications: String(localized: "Historial de medicación")
        case .visits: String(localized: "Visitas veterinarias")
        }
    }
    var createSheet: HealthSheet {
        switch self {
        case .weights: .weight(nil)
        case .vaccines: .vaccine(nil)
        case .dewormings: .deworming(nil, .internalDeworming)
        case .medications: .medication(nil)
        case .visits: .visit(nil)
        }
    }
}

struct HealthSheetContent: View {
    let sheet: HealthSheet
    var body: some View {
        switch sheet {
        case let .weight(record): WeightEditor(record: record)
        case let .vaccine(record): VaccinationEditor(record: record)
        case let .deworming(record, kind): DewormingEditor(record: record, kind: kind)
        case let .medication(record): MedicationEditor(record: record)
        case let .visit(record): VisitEditor(record: record)
        case let .visitDetail(id): VisitDetailView(visitID: id)
        case let .history(kind): HealthHistoryView(kind: kind)
        case .documents: HealthDocumentsView()
        }
    }
}

struct HealthRecordRow: View {
    let title: String
    let subtitle: String
    var symbol: String = "chevron.right"
    var status: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.body.weight(.medium)).foregroundStyle(AppTheme.ink)
                    Text(subtitle).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                    if let status {
                        Text(status).font(.caption).foregroundStyle(AppTheme.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: symbol).foregroundStyle(AppTheme.secondaryInk)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Abre los detalles y permite editar el registro")
    }
}

struct HealthSectionActions: View {
    let addTitle: LocalizedStringKey
    let onAdd: () -> Void
    let onHistory: () -> Void
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Button(addTitle, systemImage: "plus", action: onAdd)
                Spacer()
                Button("Ver historial", action: onHistory)
            }
            VStack(alignment: .leading, spacing: 12) {
                Button(addTitle, systemImage: "plus", action: onAdd)
                Button("Ver historial", action: onHistory)
            }
        }
        .buttonStyle(.bordered)
    }
}

struct HealthDeleteButton: View {
    @Environment(\.dismiss) private var dismiss
    let title: LocalizedStringKey
    var message: LocalizedStringKey = "Esta acción eliminará el registro de forma permanente."
    let action: () async -> Bool
    @State private var confirmsDeletion = false
    @State private var failed = false
    @State private var deleting = false

    var body: some View {
        Button(title, role: .destructive) { confirmsDeletion = true }
            .disabled(deleting)
            .confirmationDialog("¿Eliminar este registro?", isPresented: $confirmsDeletion, titleVisibility: .visible) {
                Button("Eliminar", role: .destructive) {
                    deleting = true
                    Task {
                        if await action() { dismiss() } else { failed = true }
                        deleting = false
                    }
                }
                Button("Cancelar", role: .cancel) { }
            } message: { Text(message) }
            .alert("No se pudo eliminar", isPresented: $failed) {
                Button("Aceptar", role: .cancel) { }
            } message: { Text("Tus datos se conservan. Vuelve a intentarlo.") }
    }
}

struct HealthOptionalDate: View {
    let title: LocalizedStringKey
    @Binding var isEnabled: Bool
    @Binding var date: Date
    var minimum: Date? = nil

    var body: some View {
        Toggle(title, isOn: $isEnabled)
        if isEnabled {
            if let minimum {
                DatePicker("Fecha", selection: $date, in: minimum..., displayedComponents: .date)
            } else {
                DatePicker("Fecha", selection: $date, displayedComponents: .date)
            }
        }
    }
}
