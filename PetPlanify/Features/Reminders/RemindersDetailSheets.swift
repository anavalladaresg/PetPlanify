import SwiftUI

struct RemindersDetailSheet: View {
    let presentation: ReminderPresentation
    let onToggleCompletion: (PetReminder) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sheetTitle)
                            .font(.system(.title2, design: .serif, weight: .semibold))
                        Text(sheetSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryInk)
                    }
                    Spacer(minLength: 12)
                    Button("Cerrar", action: onDismiss)
                        .buttonStyle(.bordered)
                }

                switch presentation {
                case .create:
                    NewReminderFutureState()
                case let .detail(reminder):
                    ReminderDetailContent(
                        reminder: reminder,
                        onToggleCompletion: { onToggleCompletion(reminder) }
                    )
                }
            }
            .frame(maxWidth: 580, alignment: .leading)
            .padding(28)
        }
        .appCanvas()
        .accessibilityIdentifier("reminders.detail")
    }

    private var sheetTitle: String {
        switch presentation {
        case .create: String(localized: "Nuevo recordatorio")
        case .detail: String(localized: "Detalle del recordatorio")
        }
    }

    private var sheetSubtitle: String {
        switch presentation {
        case .create: String(localized: "Vista previa sin almacenamiento")
        case .detail: String(localized: "Información local de ejemplo para Neo")
        }
    }
}

private struct ReminderDetailContent: View {
    let reminder: PetReminder
    let onToggleCompletion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 13) {
                Image(systemName: reminder.category.symbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.green)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.greenSoft.opacity(0.8), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                    ReminderStatusBadge(status: reminder.status)
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                ReminderDetailRow(
                    title: "Fecha y hora",
                    value: ReminderFormatting.dateAndTime(reminder.date)
                )
                ReminderDetailRow(title: "Categoría", value: reminder.category.title)
                ReminderDetailRow(
                    title: "Prioridad",
                    value: reminder.priority.accessibilityTitle
                )
                ReminderDetailRow(title: "Estado", value: reminder.status.title)
                ReminderDetailRow(title: "Notas", value: reminder.notes)
                ReminderDetailRow(title: "Repetición", value: reminder.recurrence.title)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .appSurface()

            Button(action: onToggleCompletion) {
                Label(completionActionTitle, systemImage: completionSymbol)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("El cambio solo se conserva durante esta sesión")

            Text("Este recordatorio utiliza datos de ejemplo y no programa notificaciones ni eventos.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var completionActionTitle: String {
        reminder.isCompleted
            ? String(localized: "Marcar como pendiente")
            : String(localized: "Marcar como completado")
    }

    private var completionSymbol: String {
        reminder.isCompleted ? "arrow.uturn.backward" : "checkmark"
    }
}

private struct NewReminderFutureState: View {
    private let fields: [(LocalizedStringKey, LocalizedStringKey, String)] = [
        ("Título", "Sin configurar", "text.cursor"),
        ("Fecha", "Sin configurar", "calendar"),
        ("Categoría", "Sin configurar", "tag"),
        ("Prioridad", "Sin configurar", "exclamationmark.circle"),
        ("Notas", "Sin configurar", "note.text"),
        ("Repetición", "Sin repetición", "repeat")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(fields.enumerated()), id: \.offset) { index, field in
                    HStack(spacing: 13) {
                        Image(systemName: field.2)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.green)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.green.opacity(0.09), in: Circle())
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(field.0)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryInk)
                            Text(field.1)
                                .font(.body.weight(.medium))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 10)
                    .accessibilityElement(children: .combine)

                    if index < fields.count - 1 {
                        Divider().overlay(AppTheme.border)
                    }
                }
            }
            .padding(20)
            .appSurface()

            Label(
                "La creación y las notificaciones estarán disponibles cuando se añada el almacenamiento de PetPlanify.",
                systemImage: "info.circle"
            )
            .font(.subheadline)
            .foregroundStyle(AppTheme.secondaryInk)
            .fixedSize(horizontal: false, vertical: true)

            Text("Esta vista no guarda información, no solicita permisos y no programa recordatorios.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ReminderDetailRow: View {
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
