import SwiftUI

struct EvolutionMilestoneDetailSheet: View {
    let milestone: EvolutionMilestone
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detalle del hito")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                    Text("Registro local de la evolución de Neo")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer(minLength: 16)
                Button("Cerrar", action: onDismiss)
                    .buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: 17) {
                EvolutionDetailRow(title: "Hito", value: milestone.title)
                EvolutionDetailRow(title: "Fecha", value: EvolutionFormatting.date(milestone.date))
                EvolutionDetailRow(title: "Categoría", value: milestone.category.title)
                EvolutionDetailRow(title: "Contexto", value: milestone.context)
                EvolutionDetailRow(title: "Descripción", value: milestone.description)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .appSurface()

            Text("Este hito utiliza datos de ejemplo y no contiene una valoración automática.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 560, alignment: .leading)
        .padding(28)
        .appCanvas()
        .accessibilityIdentifier("evolution.milestoneDetail")
    }
}

private struct EvolutionDetailRow: View {
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
