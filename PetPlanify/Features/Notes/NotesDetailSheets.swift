import SwiftUI

struct NotesDetailSheet: View {
    let presentation: NotesPresentation
    let onTogglePin: (PetNote) -> Void
    let onToggleArchive: (PetNote) -> Void
    let onEdit: (PetNote) -> Void
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
                    NoteFutureState(note: nil)
                case let .edit(note):
                    NoteFutureState(note: note)
                case let .detail(note):
                    NoteDetailContent(
                        note: note,
                        onTogglePin: { onTogglePin(note) },
                        onToggleArchive: { onToggleArchive(note) },
                        onEdit: { onEdit(note) }
                    )
                }
            }
            .frame(maxWidth: 620, alignment: .leading)
            .padding(28)
        }
        .appCanvas()
        .accessibilityIdentifier("notes.detail")
    }

    private var sheetTitle: String {
        switch presentation {
        case .create: String(localized: "Nueva nota")
        case .edit: String(localized: "Editar nota")
        case .detail: String(localized: "Detalle de la nota")
        }
    }

    private var sheetSubtitle: String {
        switch presentation {
        case .create: String(localized: "Vista previa sin almacenamiento")
        case .edit: String(localized: "Edición de ejemplo sin guardado")
        case .detail: String(localized: "Observación personal sobre Neo")
        }
    }
}

private struct NoteDetailContent: View {
    let note: PetNote
    let onTogglePin: () -> Void
    let onToggleArchive: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 13) {
                Image(systemName: note.category.symbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.green)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.greenSoft.opacity(0.8), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(note.title)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                    HStack(spacing: 8) {
                        NoteCategoryBadge(category: note.category)
                        if note.isPinned {
                            Label("Fijada", systemImage: "pin.fill")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(AppTheme.green)
                        }
                        if note.isArchived {
                            Label("Archivada", systemImage: "archivebox")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(AppTheme.secondaryInk)
                        }
                    }
                }
            }

            Text(note.body)
                .font(.body)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .appSurface()

            VStack(alignment: .leading, spacing: 15) {
                NoteDetailRow(
                    title: "Creada",
                    value: NotesFormatting.dateAndTime(note.createdAt)
                )
                if let updatedAt = note.updatedAt, note.hasBeenUpdated {
                    NoteDetailRow(
                        title: "Actualizada",
                        value: NotesFormatting.dateAndTime(updatedAt)
                    )
                }
                NoteDetailRow(title: "Categoría", value: note.category.title)
                NoteDetailRow(title: "Etiquetas", value: note.tags.joined(separator: " · "))
                NoteDetailRow(
                    title: "Estado",
                    value: stateDescription
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .appSurface()

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    pinButton
                    archiveButton
                    editButton
                }
                VStack(spacing: 10) {
                    pinButton
                    archiveButton
                    editButton
                }
            }

            if note.category == .health {
                Label(
                    "Este registro es una observación personal y no sustituye la valoración de un profesional veterinario.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
            }

            Text("Los cambios solo se conservan durante esta sesión.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private var pinButton: some View {
        Button(action: onTogglePin) {
            Label(
                note.isPinned ? "Desfijar nota" : "Fijar nota",
                systemImage: note.isPinned ? "pin.slash" : "pin"
            )
            .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(.bordered)
    }

    private var archiveButton: some View {
        Button(action: onToggleArchive) {
            Label(
                note.isArchived ? "Restaurar" : "Archivar",
                systemImage: note.isArchived ? "arrow.uturn.backward" : "archivebox"
            )
            .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(.bordered)
    }

    private var editButton: some View {
        Button(action: onEdit) {
            Label("Editar", systemImage: "pencil")
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(.borderedProminent)
    }

    private var stateDescription: String {
        let pinned = note.isPinned ? String(localized: "Fijada") : String(localized: "No fijada")
        let archived = note.isArchived
            ? String(localized: "Archivada")
            : String(localized: "Activa")
        return "\(pinned) · \(archived)"
    }
}

private struct NoteFutureState: View {
    let note: PetNote?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 2) {
                FutureNoteField(
                    title: "Título",
                    value: note?.title ?? String(localized: "Sin configurar"),
                    symbol: "text.cursor"
                )
                Divider().overlay(AppTheme.border)
                FutureNoteField(
                    title: "Categoría",
                    value: note?.category.title ?? String(localized: "Sin configurar"),
                    symbol: "tag"
                )
                Divider().overlay(AppTheme.border)
                FutureNoteField(
                    title: "Contenido",
                    value: note?.body ?? String(localized: "Sin configurar"),
                    symbol: "text.alignleft"
                )
                Divider().overlay(AppTheme.border)
                FutureNoteField(
                    title: "Etiquetas",
                    value: note?.tags.joined(separator: " · ") ?? String(localized: "Sin configurar"),
                    symbol: "number"
                )
            }
            .padding(20)
            .appSurface()

            Label(
                "La creación y edición estarán disponibles cuando se añada el almacenamiento de PetPlanify.",
                systemImage: "info.circle"
            )
            .font(.subheadline)
            .foregroundStyle(AppTheme.secondaryInk)
            .fixedSize(horizontal: false, vertical: true)

            Text("Esta vista no guarda ni modifica información.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }
}

private struct FutureNoteField: View {
    let title: LocalizedStringKey
    let value: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.green)
                .frame(width: 32, height: 32)
                .background(AppTheme.green.opacity(0.09), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                Text(value)
                    .font(.body.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

private struct NoteDetailRow: View {
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

#Preview("Notas · detalle") {
    NotesDetailSheet(
        presentation: .detail(NotesPreviewData.neoNotes[0]),
        onTogglePin: { _ in },
        onToggleArchive: { _ in },
        onEdit: { _ in },
        onDismiss: {}
    )
    .frame(width: 660, height: 840)
}
