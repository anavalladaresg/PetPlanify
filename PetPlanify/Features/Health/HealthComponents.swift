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
        case let .weight(record):
            if let record { HealthRecordDetailView(kind: .weight(record)) } else { WeightEditor(record: nil) }
        case let .vaccine(record):
            if let record { HealthRecordDetailView(kind: .vaccine(record)) } else { VaccinationEditor(record: nil) }
        case let .deworming(record, kind):
            if let record { HealthRecordDetailView(kind: .deworming(record, kind)) } else { DewormingEditor(record: nil, kind: kind) }
        case let .medication(record):
            if let record { HealthRecordDetailView(kind: .medication(record)) } else { MedicationEditor(record: nil) }
        case let .visit(record): VisitEditor(record: record)
        case let .visitDetail(id): VisitDetailView(visitID: id)
        case let .history(kind): HealthHistoryView(kind: kind)
        case .documents: HealthDocumentsView()
        }
    }
}

private enum HealthDetailKind { case weight(WeightRecord), vaccine(VaccinationRecord), deworming(DewormingRecord, DewormingKind), medication(MedicationRecord) }

private struct HealthRecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let kind: HealthDetailKind
    @State private var editor: HealthSheet?

    private var accent: Color {
        switch kind { case .weight: AppTheme.weight; case .vaccine: AppTheme.vaccine; case .deworming: AppTheme.deworming; case .medication: AppTheme.medication }
    }
    private var symbol: String {
        switch kind { case .weight: "scalemass"; case .vaccine: "syringe"; case .deworming: "pills"; case .medication: "pills.fill" }
    }
    private var title: String {
        switch kind { case let .weight(r): "Peso · \(AppFormat.number(r.weight)) kg"; case let .vaccine(r): "Vacuna · \(r.name)"; case let .deworming(r, _): "Desparasitación · \(r.category?.title ?? r.kind.shortTitle)"; case let .medication(r): "Medicación · \(r.name)" }
    }
    private var date: String {
        switch kind { case let .weight(r): AppFormat.date(r.date); case let .vaccine(r): AppFormat.date(r.dateAdministered); case let .deworming(r, _): AppFormat.date(r.applicationDate); case let .medication(r): AppFormat.date(r.startDate) }
    }
    var body: some View {
        NavigationStack {
            CarePage {
                VStack(spacing: AppTheme.Space.lg) {
                    CareSymbol(systemName: symbol, accent: accent, size: 58)
                    Text(title).font(.title2.weight(.bold)).multilineTextAlignment(.center).foregroundStyle(AppTheme.ink)
                    Text(date).font(.headline).foregroundStyle(accent)
                }.frame(maxWidth: .infinity).padding(.vertical, AppTheme.Space.lg)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                detailContent
            }
            .navigationTitle("Detalle")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("Editar") { editor = editingSheet } }
            }
        }
        .sheet(item: $editor) { HealthSheetContent(sheet: $0) }
    }
    @ViewBuilder private var detailContent: some View {
        switch kind {
        case let .weight(r): detailRows([(String(localized: "Peso"), "\(AppFormat.number(r.weight)) kg"), (String(localized: "Nota"), r.note ?? "—")])
        case let .vaccine(r): detailRows([(String(localized: "Administrada"), AppFormat.date(r.dateAdministered)), (String(localized: "Próxima"), r.nextDueDate.map(AppFormat.date) ?? "—"), (String(localized: "Notas"), r.notes ?? "—")])
        case let .deworming(r, _): detailRows([(String(localized: "Tipo"), r.kind.title), (String(localized: "Categoría"), r.category?.title ?? "—"), (String(localized: "Próxima"), r.nextDueDate.map(AppFormat.date) ?? "—"), (String(localized: "Notas"), r.notes ?? "—")])
        case let .medication(r): detailRows([(String(localized: "Inicio"), AppFormat.date(r.startDate)), (String(localized: "Fin"), r.endDate.map(AppFormat.date) ?? "Activa"), (String(localized: "Indicaciones"), r.notes)])
        }
    }
    private func detailRows(_ rows: [(String, String)]) -> some View { CareSection(title: "Información", style: .compact) { ForEach(Array(rows.enumerated()), id: \.offset) { _, row in LabeledContent(row.0, value: row.1) } } }
    private var editingSheet: HealthSheet { switch kind { case let .weight(r): .weight(r); case let .vaccine(r): .vaccine(r); case let .deworming(r, k): .deworming(r, k); case let .medication(r): .medication(r) } }
}

struct HealthRecordRow: View {
    let title: String
    let subtitle: String
    var symbol: String = "chevron.right"
    var status: String? = nil
    var statusColor: Color = AppTheme.secondaryInk
    var symbolAccent: Color = AppTheme.green
    var isHistorical = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                if symbol != "chevron.right" {
                    CareSymbol(systemName: symbol, accent: isHistorical ? AppTheme.secondaryInk : symbolAccent)
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
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(statusColor.opacity(0.12), in: Capsule())
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
            let status = visit.status()
            Text(status.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(status.displayColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(status.displayColor.opacity(0.12), in: Capsule())
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
    var message: LocalizedStringKey = "El registro se moverá a la papelera y podrás restaurarlo desde Ajustes."
    let action: () async -> Bool
    @State private var confirmsDeletion = false
    @State private var failed = false
    @State private var deleting = false

    var body: some View {
        Button { confirmsDeletion = true } label: {
            Label(title, systemImage: "trash")
                .font(.body.weight(.semibold))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
        }
            .disabled(deleting)
            .alert("¿Eliminar este registro?", isPresented: $confirmsDeletion) {
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

    var body: some View {
        Toggle(title, isOn: $isEnabled)
        if isEnabled {
            DatePicker("Fecha", selection: $date, displayedComponents: .date)
        }
    }
}
