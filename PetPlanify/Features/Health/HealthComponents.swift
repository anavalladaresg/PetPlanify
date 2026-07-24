import SwiftUI

struct HealthStatusBadge: View {
    let status: HealthRecordStatus

    var body: some View {
        Text(status.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.isUpcoming ? AppTheme.orange : AppTheme.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (status.isUpcoming ? AppTheme.orange : AppTheme.green).opacity(0.1),
                in: Capsule()
            )
    }
}

struct UpcomingHealthCard: View {
    let title: String
    let date: Date
    let context: String
    let symbol: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(AppTheme.orange)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.orange.opacity(0.1), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Próximo cuidado")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("\(HealthFormatting.date(date)) · \(context)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer()
                Text("Próxima")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.orange.opacity(0.1), in: Capsule())
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .contentShape(Rectangle())
            .appSurface(cornerRadius: 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Próximo cuidado, \(title), \(HealthFormatting.date(date)), \(context)")
        .accessibilityIdentifier("health.upcoming")
    }
}

struct VaccinationTimelineCard: View {
    let vaccinations: [VaccinationRecord]
    let maxRecords: Int
    let onSelect: (VaccinationRecord) -> Void
    let onShowHistory: () -> Void

    private var displayedRecords: [VaccinationRecord] {
        Array(vaccinations.sorted { $0.date > $1.date }.prefix(maxRecords))
    }

    var body: some View {
        HealthGroupCard("Vacunas", symbol: "syringe", identifier: "health.vaccinations") {
            ForEach(displayedRecords) { record in
                Button {
                    onSelect(record)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: record.status.isUpcoming ? "calendar.badge.clock" : "checkmark.circle")
                            .foregroundStyle(record.status.isUpcoming ? AppTheme.orange : AppTheme.green)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.title).font(.subheadline.weight(.semibold))
                            Text("\(HealthFormatting.shortDate(record.date)) · \(record.details)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryInk)
                        }
                        Spacer()
                        HealthStatusBadge(status: record.status)
                    }
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.ink)
                if record.id != displayedRecords.last?.id {
                    Divider().overlay(AppTheme.border)
                }
            }
            if vaccinations.count > displayedRecords.count {
                Button("Ver historial completo", action: onShowHistory)
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.green)
                    .frame(minHeight: 36)
            }
        }
    }
}

struct DewormingCard: View {
    let records: [DewormingRecord]
    let onShowHistory: () -> Void
    let onAdd: () -> Void

    var body: some View {
        HealthGroupCard(
            "Desparasitación",
            symbol: "shield.lefthalf.filled",
            identifier: "health.deworming"
        ) {
            ForEach(DewormingKind.allCases) { kind in
                if let record = records.first(where: { $0.kind == kind }) {
                    DewormingRow(record: record)
                    if kind != DewormingKind.allCases.last {
                        Divider().overlay(AppTheme.border)
                    }
                }
            }

            HStack {
                Button("Ver historial", action: onShowHistory)
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.green)
                Spacer()
                Button(action: onAdd) {
                    Label("Añadir desparasitación", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("health.addDeworming")
            }
            .padding(.top, 4)
        }
    }
}

private struct DewormingRow: View {
    let record: DewormingRecord

    private var status: DewormingStatus {
        record.status()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: record.kind.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(record.kind == .internalDeworming ? AppTheme.orange : AppTheme.green)
                .frame(width: 34, height: 34)
                .background(
                    (record.kind == .internalDeworming ? AppTheme.orange : AppTheme.green).opacity(0.1),
                    in: Circle()
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.kind.title)
                    .font(.subheadline.weight(.semibold))
                if let administeredAt = record.administeredAt {
                    Text("Última aplicación: \(HealthFormatting.shortDate(administeredAt))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                if let nextDueAt = record.nextDueAt {
                    Text("Próxima aplicación: \(HealthFormatting.shortDate(nextDueAt))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                if let productName = record.productName {
                    Text("Producto: \(productName)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
            }
            Spacer(minLength: 8)
            Text(status.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(status == .overdue ? AppTheme.secondaryInk : AppTheme.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.surfaceMuted, in: Capsule())
        }
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityIdentifier(
            record.kind == .internalDeworming
                ? "health.internalDeworming"
                : "health.externalDeworming"
        )
    }

    private var accessibilityDescription: String {
        let last = formattedDate(
            record.administeredAt,
            fallback: String(localized: "Sin registro anterior")
        )
        let next = formattedDate(
            record.nextDueAt,
            fallback: String(localized: "Sin próxima fecha")
        )
        return "\(record.kind.title), última aplicación \(last), próxima aplicación \(next), \(status.title)"
    }

    private func formattedDate(_ date: Date?, fallback: String) -> String {
        guard let date else { return fallback }
        return HealthFormatting.date(date)
    }
}

struct MedicationCard: View {
    let overview: HealthOverview
    let onShowHistory: () -> Void

    var body: some View {
        HealthGroupCard("Medicación actual", symbol: "pills", identifier: "health.medications") {
            if overview.activeMedications.isEmpty {
                Label("No hay medicamentos activos", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.green)
                    .padding(.vertical, 10)
            } else {
                ForEach(overview.activeMedications) { medication in
                    Text(medication.name).font(.subheadline.weight(.semibold))
                }
            }
            Button("Ver historial", action: onShowHistory)
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.green)
                .frame(minHeight: 36)
        }
    }
}

struct VisitsCard: View {
    let visits: [VeterinaryVisit]
    let onSelect: (VeterinaryVisit) -> Void

    var body: some View {
        HealthGroupCard("Visitas veterinarias", symbol: "cross.case", identifier: "health.visits") {
            ForEach(visits.sorted { $0.date > $1.date }) { visit in
                Button {
                    onSelect(visit)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(visit.reason).font(.subheadline.weight(.semibold))
                            Text("\(HealthFormatting.date(visit.date)) · \(visit.clinic)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryInk)
                            if !visit.documents.isEmpty {
                                Label(
                                    visit.documents.count == 1 ? "1 documento vinculado" : "\(visit.documents.count) documentos vinculados",
                                    systemImage: "paperclip"
                                )
                                .font(.caption)
                                .foregroundStyle(AppTheme.green)
                            }
                        }
                        Spacer()
                        HealthStatusBadge(status: visit.status)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryInk)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.ink)
                if visit.id != visits.sorted(by: { $0.date > $1.date }).last?.id {
                    Divider().overlay(AppTheme.border)
                }
            }
        }
    }
}

struct HealthGroupCard<Content: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    let identifier: String
    @ViewBuilder let content: Content

    init(_ title: LocalizedStringKey, symbol: String, identifier: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.symbol = symbol
        self.identifier = identifier
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
            content
        }
        .padding(18)
        .appSurface()
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier(identifier)
    }
}
