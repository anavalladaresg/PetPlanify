import SwiftUI

struct HealthSectionSelector: View {
    @Binding var selection: HealthSection

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(HealthSection.allCases) { section in
                    Button {
                        selection = section
                    } label: {
                        Text(section.title)
                            .font(.subheadline.weight(selection == section ? .semibold : .regular))
                            .foregroundStyle(selection == section ? AppTheme.ink : AppTheme.secondaryInk)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 40)
                            .background(
                                Capsule()
                                    .fill(selection == section ? AppTheme.surfaceMuted : .clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == section ? .isSelected : [])
                    .accessibilityIdentifier("health.section.\(section.rawValue)")
                }
            }
            .padding(4)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.surface.opacity(0.66), in: Capsule())
        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 0.75))
        .accessibilityIdentifier("health.sectionPicker")
    }
}

struct HealthStatusBadge: View {
    let status: HealthRecordStatus

    var body: some View {
        Text(status.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(accent)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(accent.opacity(0.11), in: Capsule())
            .accessibilityLabel(String(localized: "Estado: \(status.title)"))
    }

    private var accent: Color {
        status.isUpcoming ? AppTheme.orange : AppTheme.green
    }
}

struct UpcomingHealthCard: View {
    let vaccination: VaccinationRecord
    let visit: VeterinaryVisit?
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 20) {
                    eventIcon
                    details
                    Spacer(minLength: 12)
                    dateBlock
                }
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        eventIcon
                        Spacer()
                        HealthStatusBadge(status: vaccination.status)
                    }
                    details
                    dateBlock
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSurface()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(localized: "Próxima vacuna: \(vaccination.title), \(vaccination.details), \(HealthFormatting.date(vaccination.date)), \(visit?.clinic ?? "")")
        )
        .accessibilityHint("Abre los detalles de la vacuna")
        .accessibilityIdentifier("health.upcoming")
    }

    private var eventIcon: some View {
        Image(systemName: "cross.case.fill")
            .font(.system(size: 27, weight: .medium))
            .foregroundStyle(AppTheme.orange)
            .frame(width: 56, height: 56)
            .background(AppTheme.orange.opacity(0.11), in: Circle())
            .accessibilityHidden(true)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text("Próximo cuidado")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryInk)
                HealthStatusBadge(status: vaccination.status)
            }
            Text(vaccination.title)
                .font(.system(.title3, design: .serif, weight: .semibold))
            Text(vaccination.details)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
            if let visit {
                Text(visit.clinic)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.green)
            }
        }
        .multilineTextAlignment(.leading)
    }

    private var dateBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(HealthFormatting.date(vaccination.date))
                .font(.headline)
            Text("Revisión anual")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }
}

struct VaccinationTimelineCard: View {
    let vaccinations: [VaccinationRecord]
    let onSelect: (VaccinationRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HealthCardHeader(title: "Calendario de vacunas", symbol: "syringe")
                .padding(.bottom, 8)

            ForEach(Array(vaccinations.enumerated()), id: \.element.id) { index, record in
                VaccinationTimelineRow(
                    record: record,
                    isLast: index == vaccinations.count - 1,
                    onSelect: { onSelect(record) }
                )
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("health.vaccinations")
    }
}

private struct VaccinationTimelineRow: View {
    let record: VaccinationRecord
    let isLast: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 13) {
                timeline
                VStack(alignment: .leading, spacing: 4) {
                    Text(HealthFormatting.shortDate(record.date))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(record.status.isUpcoming ? AppTheme.orange : AppTheme.secondaryInk)
                    Text(record.title)
                        .font(.subheadline.weight(.semibold))
                    Text(record.details)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                HealthStatusBadge(status: record.status)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(HealthFormatting.date(record.date)), \(record.title), \(record.details), \(record.status.title)"
        )
        .accessibilityHint("Abre los detalles de la vacuna")
    }

    private var timeline: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(record.status.isUpcoming ? AppTheme.orange : AppTheme.green)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(AppTheme.surface, lineWidth: 2))
            if !isLast {
                Rectangle()
                    .fill(AppTheme.border)
                    .frame(width: 1.5)
                    .frame(minHeight: 54)
            }
        }
        .padding(.top, 4)
        .accessibilityHidden(true)
    }
}

struct MedicationCard: View {
    let history: [MedicationRecord]
    let showsHistory: Bool
    let onShowHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HealthCardHeader(title: "Medicamentos actuales", symbol: "pills")

            HStack(spacing: 13) {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(AppTheme.green)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("No hay medicamentos activos")
                        .font(.subheadline.weight(.semibold))
                    Text("El historial permanece disponible como referencia.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
            }
            .padding(14)
            .background(AppTheme.greenSoft.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))

            if showsHistory {
                ForEach(history) { medication in
                    Divider().overlay(AppTheme.border)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(medication.name)
                                .font(.headline)
                            Spacer()
                            HealthStatusBadge(status: medication.status)
                        }
                        Text(
                            "\(HealthFormatting.shortDate(medication.startDate)) – \(HealthFormatting.shortDate(medication.endDate))"
                        )
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                    }
                    .accessibilityElement(children: .combine)
                }
            } else {
                Button("Ver historial", action: onShowHistory)
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.green)
                    .frame(minHeight: 44)
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("health.medications")
    }
}

struct SymptomsCard: View {
    let symptoms: [SymptomRecord]
    let showsAll: Bool
    let onSelect: (SymptomRecord) -> Void

    private var displayedSymptoms: [SymptomRecord] {
        showsAll ? symptoms : Array(symptoms.prefix(1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HealthCardHeader(title: "Síntomas recientes", symbol: "waveform.path.ecg")
                .padding(.bottom, 7)

            ForEach(displayedSymptoms) { symptom in
                Button {
                    onSelect(symptom)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(HealthFormatting.shortDate(symptom.date))
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryInk)
                            Text(symptom.name)
                                .font(.subheadline.weight(.semibold))
                            Text(symptom.notes)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                Text(symptom.severity.title)
                                Text("•")
                                Text(symptom.status.title)
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.green)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryInk)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(HealthFormatting.date(symptom.date)), \(symptom.name), intensidad \(symptom.severity.title), \(symptom.status.title), \(symptom.notes)"
                )
                .accessibilityHint("Abre los detalles de la observación")

                if symptom.id != displayedSymptoms.last?.id {
                    Divider().overlay(AppTheme.border)
                }
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("health.symptoms")
    }
}

struct VisitsCard: View {
    let visits: [VeterinaryVisit]
    let showsAll: Bool
    let onSelect: (VeterinaryVisit) -> Void

    private var displayedVisits: [VeterinaryVisit] {
        showsAll ? visits : Array(visits.prefix(1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HealthCardHeader(title: showsAll ? "Visitas veterinarias" : "Próxima visita", symbol: "cross.case")
                .padding(.bottom, 7)

            ForEach(displayedVisits) { visit in
                Button {
                    onSelect(visit)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: visit.status.isUpcoming ? "calendar.badge.clock" : "checkmark.circle")
                            .foregroundStyle(visit.status.isUpcoming ? AppTheme.orange : AppTheme.green)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(HealthFormatting.date(visit.date))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(visit.status.isUpcoming ? AppTheme.orange : AppTheme.secondaryInk)
                            Text(visit.reason)
                                .font(.subheadline.weight(.semibold))
                            Text(visit.clinic)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryInk)
                        }
                        Spacer(minLength: 8)
                        HealthStatusBadge(status: visit.status)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(HealthFormatting.date(visit.date)), \(visit.reason), \(visit.clinic), \(visit.status.title)"
                )
                .accessibilityHint("Abre los detalles de la visita")

                if visit.id != displayedVisits.last?.id {
                    Divider().overlay(AppTheme.border)
                }
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("health.visits")
    }
}

struct DocumentsCard: View {
    let documents: [HealthDocument]
    let showsStorageNote: Bool
    let onSelect: (HealthDocument) -> Void
    let onShowAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HealthCardHeader(title: "Documentos", symbol: "doc.text")
                .padding(.bottom, 7)

            ForEach(documents) { document in
                Button {
                    onSelect(document)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "doc.richtext")
                            .foregroundStyle(AppTheme.orange)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.filename)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(2)
                            Text("\(document.fileType) · \(document.fileSize)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryInk)
                            Text(String(localized: "Actualizado el \(HealthFormatting.shortDate(document.updatedDate))"))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.secondaryInk)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryInk)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(document.filename), \(document.fileType), \(document.fileSize), actualizado el \(HealthFormatting.date(document.updatedDate))"
                )
                .accessibilityHint("Abre los metadatos del documento")

                if document.id != documents.last?.id {
                    Divider().overlay(AppTheme.border)
                }
            }

            if showsStorageNote {
                Text("El almacenamiento de documentos estará disponible más adelante.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            } else {
                Button("Ver todos", action: onShowAll)
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.green)
                    .frame(minHeight: 44)
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("health.documents")
    }
}

struct HealthCardHeader: View {
    let title: LocalizedStringKey
    let symbol: String

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .foregroundStyle(AppTheme.ink)
    }
}

#Preview("Calendario de vacunas") {
    VaccinationTimelineCard(
        vaccinations: HealthPreviewData.neoOverview.vaccinations,
        onSelect: { _ in }
    )
    .frame(width: 520)
    .padding()
    .appCanvas()
}
