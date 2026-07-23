import SwiftUI

struct TrainingDetailSheet: View {
    let detail: TrainingDetail
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
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
        }
        .appCanvas()
        .accessibilityIdentifier("training.detailSheet")
    }

    private var title: String {
        switch detail {
        case .addTrick: String(localized: "Añadir truco")
        case .addSession: String(localized: "Registrar sesión")
        case .trick: String(localized: "Detalle del truco")
        case .session: String(localized: "Detalle de la sesión")
        case .behaviorNote: String(localized: "Detalle de la nota")
        }
    }

    private var subtitle: String {
        switch detail {
        case .addTrick, .addSession:
            String(localized: "Vista previa sin almacenamiento")
        case .trick:
            String(localized: "Progreso de entrenamiento de Neo")
        case .session:
            String(localized: "Registro local de ejemplo")
        case .behaviorNote:
            String(localized: "Observación personal sobre Neo")
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch detail {
        case .addTrick:
            FutureTrainingContent(
                symbol: "sparkles",
                message: "La creación y el almacenamiento de trucos estarán disponibles más adelante. Esta versión utiliza únicamente datos de ejemplo."
            )
        case .addSession:
            FutureTrainingContent(
                symbol: "stopwatch",
                message: "El registro de sesiones estará disponible más adelante. Esta vista previa no inicia un temporizador ni guarda información."
            )
        case let .trick(trick):
            TrickDetailContent(trick: trick)
        case let .session(session):
            SessionDetailContent(session: session)
        case let .behaviorNote(note):
            BehaviorNoteDetailContent(note: note)
        }
    }
}

private struct FutureTrainingContent: View {
    let symbol: String
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text(message)
                .foregroundStyle(AppTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .appSurface()
    }
}

private struct TrickDetailContent: View {
    let trick: TrainingTrick

    var body: some View {
        VStack(spacing: 14) {
            TrainingDetailSurface {
                TrainingDetailRow(title: "Truco", value: trick.name)
                TrainingDetailRow(title: "Estado", value: trick.status.title)
                TrainingDetailRow(title: "Progreso", value: "\(trick.progress) %")
                TrainingProgressDots(progress: trick.progress, accent: accent)
                TrainingDetailRow(
                    title: "Repeticiones correctas",
                    value: trick.successfulRepetitions.formatted()
                )
                TrainingDetailRow(title: "Última práctica", value: trick.lastPractised.title)
                TrainingDetailRow(title: "Recompensa", value: trick.reward.title)
            }

            Label(
                "Sesiones breves y consistentes ayudan a mantener la concentración de Neo.",
                systemImage: "info.circle"
            )
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryInk)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var accent: Color {
        switch trick.status {
        case .mastered: AppTheme.green
        case .inProgress: AppTheme.orange
        case .notStarted: AppTheme.secondaryInk
        }
    }
}

private struct SessionDetailContent: View {
    let session: TrainingSession

    var body: some View {
        TrainingDetailSurface {
            TrainingDetailRow(
                title: "Fecha y hora",
                value: TrainingFormatting.sessionDate(session.date)
            )
            TrainingDetailRow(title: "Tipo de sesión", value: session.type)
            TrainingDetailRow(
                title: "Duración",
                value: String(localized: "\(session.durationMinutes) minutos")
            )
            TrainingDetailRow(
                title: "Trucos practicados",
                value: session.tricks.joined(separator: ", ")
            )
            TrainingDetailRow(title: "Observación", value: session.result)
            TrainingDetailRow(title: "Estado", value: String(localized: "Registro de ejemplo"))
        }
    }
}

private struct BehaviorNoteDetailContent: View {
    let note: BehaviorNote

    var body: some View {
        VStack(spacing: 14) {
            TrainingDetailSurface {
                TrainingDetailRow(title: "Título", value: note.title)
                TrainingDetailRow(title: "Fecha", value: TrainingFormatting.date(note.date))
                TrainingDetailRow(title: "Estado", value: note.status.title)
                TrainingDetailRow(title: "Etiquetas", value: note.tags.joined(separator: ", "))
                TrainingDetailRow(title: "Observación", value: note.description)
            }

            Text("Estas notas son observaciones personales y no sustituyen la valoración de un educador canino o profesional veterinario.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct TrainingDetailSurface<Content: View>: View {
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

private struct TrainingDetailRow: View {
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
