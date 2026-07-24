import SwiftUI

struct HealthDetailSheet: View {
    let detail: HealthDetail
    let overview: HealthOverview
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.title2, design: .serif, weight: .semibold))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer(minLength: 16)
                Button("Cerrar", action: onDismiss)
                    .buttonStyle(.bordered)
            }

            detailContent
        }
        .frame(maxWidth: 560, alignment: .leading)
        .padding(28)
        .appCanvas()
        .accessibilityIdentifier("health.detailSheet")
    }

    private var title: String {
        switch detail {
        case .addRecord: String(localized: "Añadir registro")
        case .vaccination: String(localized: "Detalle de vacuna")
        case .medicationHistory: String(localized: "Historial de medicamentos")
        case .symptom: String(localized: "Detalle de observación")
        case .visit: String(localized: "Detalle de visita")
        case .document: String(localized: "Metadatos del documento")
        }
    }

    private var subtitle: String {
        switch detail {
        case .addRecord:
            String(localized: "Vista previa sin almacenamiento")
        case .vaccination:
            String(localized: "Registro de vacunación de Neo")
        case .medicationHistory:
            String(localized: "Tratamientos anteriores registrados")
        case .symptom:
            String(localized: "Observación personal registrada")
        case .visit:
            String(localized: "Información de la visita veterinaria")
        case .document:
            String(localized: "Información local de ejemplo")
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch detail {
        case .addRecord:
            FutureRecordContent()
        case let .vaccination(record):
            VaccinationDetailContent(record: record)
        case .medicationHistory:
            MedicationHistoryContent(records: overview.medicationHistory)
        case let .symptom(record):
            SymptomDetailContent(record: record)
        case let .visit(record):
            VisitDetailContent(record: record)
        case let .document(document):
            DocumentDetailContent(document: document)
        }
    }
}

private struct FutureRecordContent: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text("La creación y el almacenamiento de registros estarán disponibles más adelante. Esta versión utiliza únicamente datos de ejemplo.")
                .foregroundStyle(AppTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .appSurface()
    }
}

private struct VaccinationDetailContent: View {
    let record: VaccinationRecord

    var body: some View {
        HealthDetailSurface {
            HealthDetailRow(title: "Vacuna", value: record.title)
            HealthDetailRow(title: "Fecha", value: HealthFormatting.date(record.date))
            HealthDetailRow(title: "Cobertura registrada", value: record.details)
            HealthDetailRow(title: "Estado", value: record.status.title)
        }
    }
}

private struct MedicationHistoryContent: View {
    let records: [MedicationRecord]

    var body: some View {
        HealthDetailSurface {
            ForEach(records) { record in
                HealthDetailRow(title: "Medicamento", value: record.name)
                HealthDetailRow(
                    title: "Periodo",
                    value: "\(HealthFormatting.date(record.startDate)) – \(HealthFormatting.date(record.endDate))"
                )
                HealthDetailRow(title: "Estado", value: record.status.title)
            }
        }
    }
}

private struct SymptomDetailContent: View {
    let record: SymptomRecord

    var body: some View {
        VStack(spacing: 14) {
            HealthDetailSurface {
                HealthDetailRow(title: "Observación", value: record.name)
                HealthDetailRow(title: "Fecha", value: HealthFormatting.date(record.date))
                HealthDetailRow(title: "Intensidad", value: record.severity.title)
                HealthDetailRow(title: "Estado", value: record.status.title)
                HealthDetailRow(title: "Observación", value: record.notes)
            }
            Text("Estos registros son observaciones personales y no sustituyen la valoración de un profesional veterinario.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct VisitDetailContent: View {
    let record: VeterinaryVisit

    var body: some View {
        HealthDetailSurface {
            HealthDetailRow(title: "Motivo", value: record.reason)
            HealthDetailRow(title: "Clínica", value: record.clinic)
            HealthDetailRow(title: "Fecha", value: HealthFormatting.date(record.date))
            HealthDetailRow(title: "Estado", value: record.status.title)
        }
    }
}

private struct DocumentDetailContent: View {
    let document: HealthDocument

    var body: some View {
        VStack(spacing: 14) {
            HealthDetailSurface {
                HealthDetailRow(title: "Nombre", value: document.filename)
                HealthDetailRow(title: "Tipo", value: document.fileType)
                HealthDetailRow(title: "Tamaño", value: document.fileSize)
                HealthDetailRow(
                    title: "Última actualización",
                    value: HealthFormatting.date(document.updatedDate)
                )
            }
            Text("Este elemento representa metadatos de ejemplo. No hay ningún archivo almacenado.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct HealthDetailSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .appSurface()
    }
}

private struct HealthDetailRow: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(value)
                .font(.body.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
