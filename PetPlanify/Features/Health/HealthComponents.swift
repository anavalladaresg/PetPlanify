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
    let vaccination: VaccinationRecord
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                Image(systemName: "syringe")
                    .font(.title3)
                    .foregroundStyle(AppTheme.orange)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.orange.opacity(0.1), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Próximo cuidado")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                    Text(vaccination.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("\(HealthFormatting.date(vaccination.date)) · \(vaccination.clinic)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer()
                HealthStatusBadge(status: vaccination.status)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .contentShape(Rectangle())
            .appSurface(cornerRadius: 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Próximo cuidado, \(vaccination.title), \(HealthFormatting.date(vaccination.date)), \(vaccination.clinic)")
        .accessibilityIdentifier("health.upcoming")
    }
}

struct VaccinationTimelineCard: View {
    let vaccinations: [VaccinationRecord]
    let onSelect: (VaccinationRecord) -> Void

    var body: some View {
        HealthGroupCard("Vacunas", symbol: "syringe", identifier: "health.vaccinations") {
            ForEach(vaccinations.sorted { $0.date > $1.date }) { record in
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
                if record.id != vaccinations.sorted(by: { $0.date > $1.date }).last?.id {
                    Divider().overlay(AppTheme.border)
                }
            }
        }
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
        .accessibilityIdentifier(identifier)
    }
}
