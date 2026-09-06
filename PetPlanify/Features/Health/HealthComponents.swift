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
    var statusColor: Color = AppTheme.secondaryInk
    var isHistorical = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                if symbol != "chevron.right" {
                    CareSymbol(systemName: symbol, accent: isHistorical ? AppTheme.secondaryInk : AppTheme.green)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(isHistorical ? .regular : .medium))
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    if let status {
                        Text(status)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(statusColor)
                    }
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryInk.opacity(0.65))
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

/// A visit keeps its date and attachments together, like an entry in a care journal.
struct HealthVisitRow: View {
    @Environment(PetPlanifyStore.self) private var store
    let visit: VeterinaryVisit
    let action: () -> Void

    private var attachmentCount: Int {
        store.snapshot.health.documents.filter { $0.linkedVisitID == visit.id }.count
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Space.md) {
                VStack(spacing: 2) {
                    Text(visit.date, format: .dateTime.day())
                        .font(.title3.weight(.medium)).monospacedDigit()
                    Text(visit.date, format: .dateTime.month(.abbreviated))
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(visit.date > .now ? AppTheme.green : AppTheme.secondaryInk)
                .frame(width: 48)
                .frame(minHeight: 52)
                .background(AppTheme.surfaceMuted.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text(visit.reason).font(.body.weight(.medium)).foregroundStyle(AppTheme.ink)
                    if !visit.clinic.isEmpty {
                        Text(visit.clinic).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: AppTheme.Space.sm) { metadata }
                        VStack(alignment: .leading, spacing: AppTheme.Space.xs) { metadata }
                    }
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryInk.opacity(0.65))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, AppTheme.Space.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Abre los detalles y permite editar el registro")
    }

    @ViewBuilder private var metadata: some View {
        Text(AppFormat.date(visit.date)).font(.caption).foregroundStyle(AppTheme.secondaryInk)
        if visit.date > .now {
            Text(visit.status().title).font(.caption.weight(.medium)).foregroundStyle(AppTheme.green)
        }
        if attachmentCount > 0 {
            Label("\(attachmentCount)", systemImage: "paperclip")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryInk)
                .accessibilityLabel("\(attachmentCount) documentos adjuntos")
        }
    }
}

extension HealthRecordStatus {
    var displayColor: Color {
        switch self {
        case .upcoming, .active: AppTheme.green
        case .overdue: AppTheme.orange
        case .completed, .finished: AppTheme.secondaryInk
        }
    }
}

struct HealthSectionActions: View {
    let addTitle: LocalizedStringKey
    let onAdd: () -> Void
    let onHistory: () -> Void
    var body: some View {
        VStack(spacing: AppTheme.Space.xs) {
            Divider().overlay(AppTheme.border.opacity(0.5))
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppTheme.Space.lg) {
                    addButton
                    Spacer(minLength: AppTheme.Space.sm)
                    historyButton
                }
                VStack(alignment: .leading, spacing: 0) {
                    addButton
                    historyButton
                }
            }
        }
        .font(.subheadline.weight(.medium))
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Label(addTitle, systemImage: "plus")
                .frame(minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .foregroundStyle(AppTheme.green)
    }

    private var historyButton: some View {
        Button(action: onHistory) {
            Text("Ver historial")
                .frame(minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .foregroundStyle(AppTheme.secondaryInk)
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
