import SwiftUI

struct HealthDetailSheet: View {
    let detail: HealthDetail
    let overview: HealthOverview
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(title)
                        .font(.system(.title2, design: .serif, weight: .semibold))
                    Spacer()
                    Button("Cerrar", action: onDismiss)
                        .buttonStyle(.bordered)
                }
                content
            }
            .frame(maxWidth: 580, alignment: .leading)
            .padding(26)
        }
        .appCanvas()
        .accessibilityIdentifier("health.detail")
    }

    private var title: String {
        switch detail {
        case .addRecord: "Añadir registro"
        case .registerWeight: "Registrar peso"
        case let .vaccination(record): record.title
        case .medicationHistory: "Historial de medicación"
        case let .visit(visit): visit.reason
        }
    }

    @ViewBuilder
    private var content: some View {
        switch detail {
        case .addRecord:
            futureState(
                symbol: "cross.case",
                message: "Las visitas, vacunas y medicaciones podrán añadirse cuando definamos el formulario y el modelo definitivo."
            )
        case .registerWeight:
            futureState(
                symbol: "scalemass",
                message: "El registro de peso será uno de los primeros formularios funcionales de PetPlanify."
            )
        case let .vaccination(record):
            detailCard {
                HealthDetailRow(title: "Fecha", value: HealthFormatting.date(record.date))
                HealthDetailRow(title: "Estado", value: record.status.title)
                HealthDetailRow(title: "Clínica", value: record.clinic)
                HealthDetailRow(title: "Detalle", value: record.details)
            }
        case .medicationHistory:
            detailCard {
                if overview.medications.isEmpty {
                    Text("Todavía no hay medicación registrada.")
                }
                ForEach(overview.medications) { medication in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(medication.name).font(.headline)
                        Text(medication.notes)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryInk)
                        Text("\(HealthFormatting.shortDate(medication.startDate)) · \(medication.status.title)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryInk)
                    }
                    .padding(.vertical, 8)
                }
            }
        case let .visit(visit):
            visitContent(visit)
        }
    }

    private func visitContent(_ visit: VeterinaryVisit) -> some View {
        let followUp = visit.followUpDate.map { HealthFormatting.date($0) } ?? "No indicado"
        return VStack(alignment: .leading, spacing: 14) {
            detailCard {
                HealthDetailRow(title: "Fecha", value: HealthFormatting.date(visit.date))
                HealthDetailRow(title: "Clínica", value: visit.clinic)
                HealthDetailRow(title: "Estado", value: visit.status.title)
                HealthDetailRow(title: "Valoración manual", value: visit.notes)
                HealthDetailRow(
                    title: "Tratamiento",
                    value: visit.medications.isEmpty ? "No registrado" : visit.medications.joined(separator: ", ")
                )
                HealthDetailRow(
                    title: "Próximo seguimiento",
                    value: followUp
                )
            }

            if !visit.documents.isEmpty {
                Text("Documentos de esta visita")
                    .font(.headline)
                ForEach(visit.documents) { document in
                    HStack {
                        Label(document.filename, systemImage: "doc.text")
                        Spacer()
                        Text("\(document.fileType) · \(document.fileSize)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryInk)
                    }
                    .padding(12)
                    .background(AppTheme.surfaceMuted.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("\(document.filename), vinculado a \(visit.reason)")
                }
            }

            Text("La información es un registro manual y no sustituye la valoración veterinaria.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private func futureState(symbol: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .appSurface()
    }

    private func detailCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10, content: content)
            .padding(18)
            .appSurface()
    }
}

private struct HealthDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(title)
                .foregroundStyle(AppTheme.secondaryInk)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 330, alignment: .trailing)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}
