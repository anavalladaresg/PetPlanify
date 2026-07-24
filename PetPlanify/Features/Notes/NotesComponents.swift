import SwiftUI

struct NotesSectionSelector: View {
    @Binding var selection: NotesSection

    var body: some View {
        HStack(spacing: 6) {
            ForEach(NotesSection.allCases) { section in
                Button {
                    selection = section
                } label: {
                    Text(section.title)
                        .font(.subheadline.weight(selection == section ? .semibold : .regular))
                        .foregroundStyle(selection == section ? AppTheme.ink : AppTheme.secondaryInk)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(selection == section ? AppTheme.surfaceMuted : .clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == section ? .isSelected : [])
                .accessibilityIdentifier("notes.section.\(section.rawValue)")
            }
        }
        .padding(4)
        .background(AppTheme.surface.opacity(0.66), in: Capsule())
        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 0.75))
        .accessibilityIdentifier("notes.sectionPicker")
    }
}

struct NotesControls: View {
    @Binding var searchText: String
    @Binding var selectedCategory: NoteCategoryFilter
    @Binding var sortOrder: NoteSortOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    searchField
                    sortMenu
                        .frame(minWidth: 168)
                }
                VStack(alignment: .leading, spacing: 12) {
                    searchField
                    sortMenu
                }
            }

            categoryFilter
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryInk)
                .accessibilityHidden(true)
            TextField("Buscar notas", text: $searchText)
                .textFieldStyle(.plain)
                .accessibilityLabel("Buscar notas")
                .accessibilityHint("Filtra por título, contenido o etiqueta")
                .accessibilityIdentifier("notes.search")
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Borrar búsqueda")
            }
        }
        .frame(minHeight: 42)
        .padding(.horizontal, 14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 0.75)
        )
    }

    private var sortMenu: some View {
        Menu {
            ForEach(NoteSortOrder.allCases) { order in
                Button {
                    sortOrder = order
                } label: {
                    if sortOrder == order {
                        Label(order.title, systemImage: "checkmark")
                    } else {
                        Text(order.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "arrow.up.arrow.down")
                    .accessibilityHidden(true)
                Text(sortOrder.title)
                    .lineLimit(1)
                Spacer(minLength: 6)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .accessibilityHidden(true)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.ink)
            .frame(minHeight: 42)
            .padding(.horizontal, 14)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 0.75)
            )
        }
        .menuIndicator(.hidden)
        .accessibilityLabel("Orden de las notas")
        .accessibilityValue(sortOrder.title)
        .accessibilityIdentifier("notes.sort")
    }

    private var categoryFilter: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 112), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(NoteCategoryFilter.allCases) { filter in
                Button {
                    selectedCategory = filter
                } label: {
                    Text(filter.title)
                        .font(.caption.weight(selectedCategory == filter ? .semibold : .regular))
                        .foregroundStyle(
                            selectedCategory == filter ? AppTheme.ink : AppTheme.secondaryInk
                        )
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(
                                    selectedCategory == filter
                                        ? AppTheme.greenSoft.opacity(0.78)
                                        : AppTheme.surface
                                )
                        )
                        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 0.65))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedCategory == filter ? .isSelected : [])
                .accessibilityIdentifier("notes.filter.\(filter.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filtrar notas por categoría")
        .accessibilityIdentifier("notes.categoryFilter")
    }
}

struct NotesSummaryGrid: View {
    let overview: NotesOverview
    let compact: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columnCount: Int {
        compact && dynamicTypeSize.isAccessibilitySize ? 1 : (compact ? 2 : 4)
    }

    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 12),
                count: columnCount
            ),
            spacing: 12
        ) {
            NotesMetricCard(
                title: "Notas activas",
                value: overview.activeNotes.count.formatted(),
                symbol: "note.text",
                accent: AppTheme.green
            )
            NotesMetricCard(
                title: "Fijadas",
                value: overview.pinnedNotes.count.formatted(),
                symbol: "pin",
                accent: AppTheme.green
            )
            NotesMetricCard(
                title: "Archivadas",
                value: overview.archivedNotes.count.formatted(),
                symbol: "archivebox",
                accent: AppTheme.secondaryInk
            )
            NotesMetricCard(
                title: "Categorías",
                value: overview.categoryCount.formatted(),
                symbol: "tag",
                accent: AppTheme.orange
            )
        }
        .accessibilityIdentifier("notes.summary")
    }
}

private struct NotesMetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let symbol: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 34, height: 34)
                .background(accent.opacity(0.11), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(15)
        .appSurface(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }
}

struct NotesListCard: View {
    let section: NotesSection
    let notes: [PetNote]
    let onShowDetail: (PetNote) -> Void
    let onTogglePin: (PetNote) -> Void
    let onToggleArchive: (PetNote) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: sectionSymbol)
                    .foregroundStyle(AppTheme.green)
                    .accessibilityHidden(true)
                Text(sectionTitle)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                Spacer()
                Text(notes.count.formatted())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(AppTheme.surfaceMuted, in: Capsule())
                    .accessibilityLabel(String(localized: "\(notes.count) notas"))
            }
            .padding(.bottom, 6)

            if notes.isEmpty {
                NotesEmptyState(section: section)
            } else {
                ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                    NoteRow(
                        note: note,
                        onShowDetail: { onShowDetail(note) },
                        onTogglePin: { onTogglePin(note) },
                        onToggleArchive: { onToggleArchive(note) }
                    )
                    if index < notes.count - 1 {
                        Divider().overlay(AppTheme.border)
                    }
                }
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier(listIdentifier)
    }

    private var sectionTitle: LocalizedStringKey {
        switch section {
        case .all: "Notas de Neo"
        case .pinned: "Notas fijadas"
        case .archived: "Notas archivadas"
        }
    }

    private var sectionSymbol: String {
        switch section {
        case .all: "note.text"
        case .pinned: "pin"
        case .archived: "archivebox"
        }
    }

    private var listIdentifier: String {
        switch section {
        case .all: "notes.list"
        case .pinned: "notes.pinned"
        case .archived: "notes.archived"
        }
    }
}

struct NoteRow: View {
    let note: PetNote
    let onShowDetail: () -> Void
    let onTogglePin: () -> Void
    let onToggleArchive: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onShowDetail) {
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: note.category.symbol)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(note.isArchived ? AppTheme.secondaryInk : AppTheme.green)
                        .frame(width: 38, height: 38)
                        .background(
                            (note.isArchived ? AppTheme.surfaceMuted : AppTheme.greenSoft)
                                .opacity(0.72),
                            in: Circle()
                        )
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Text(note.title)
                                .font(.headline)
                                .foregroundStyle(AppTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            if note.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.green)
                                    .accessibilityHidden(true)
                            }
                        }
                        Text(note.body)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryInk)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 8) {
                                NoteCategoryBadge(category: note.category)
                                noteDate
                            }
                            VStack(alignment: .leading, spacing: 7) {
                                NoteCategoryBadge(category: note.category)
                                noteDate
                            }
                        }
                    }
                    Spacer(minLength: 6)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
            .accessibilityHint("Abre el detalle de la nota")

            VStack(spacing: 6) {
                Button(action: onTogglePin) {
                    Image(systemName: note.isPinned ? "pin.slash" : "pin")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(pinActionTitle)

                Button(action: onToggleArchive) {
                    Image(systemName: note.isArchived ? "arrow.uturn.backward" : "archivebox")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(archiveActionTitle)
            }
        }
        .padding(.vertical, 11)
    }

    private var noteDate: some View {
        HStack(spacing: 7) {
            Text(NotesFormatting.date(note.createdAt))
            if note.hasBeenUpdated {
                Text("Actualizada")
                    .foregroundStyle(AppTheme.orange)
            }
        }
        .font(.caption)
        .foregroundStyle(AppTheme.secondaryInk)
    }

    private var pinActionTitle: String {
        note.isPinned ? String(localized: "Desfijar nota") : String(localized: "Fijar nota")
    }

    private var archiveActionTitle: String {
        note.isArchived ? String(localized: "Restaurar") : String(localized: "Archivar")
    }

    private var accessibilitySummary: String {
        let pinned = note.isPinned ? String(localized: "Fijada") : String(localized: "No fijada")
        let archived = note.isArchived
            ? String(localized: "Archivada")
            : String(localized: "No archivada")
        return String(
            localized: "\(note.title), categoría \(note.category.title), \(NotesFormatting.date(note.createdAt)), \(note.body), \(pinned), \(archived)"
        )
    }
}

struct FeaturedNoteCard: View {
    let note: PetNote
    let onShowDetail: (PetNote) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 9) {
                Image(systemName: "pin.fill")
                    .foregroundStyle(AppTheme.green)
                    .accessibilityHidden(true)
                Text("Nota destacada")
                    .font(.system(.title3, design: .serif, weight: .semibold))
            }

            Text(note.title)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(note.body)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
            NoteCategoryBadge(category: note.category)
            Spacer(minLength: 0)
            Button("Leer nota completa") {
                onShowDetail(note)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        .padding(22)
        .appSurface()
    }
}

struct NoteCategoryBadge: View {
    let category: NoteCategory

    var body: some View {
        Label(category.title, systemImage: category.symbol)
            .font(.caption2.weight(.medium))
            .foregroundStyle(AppTheme.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppTheme.green.opacity(0.10), in: Capsule())
    }
}

private struct NotesEmptyState: View {
    let section: NotesSection

    var body: some View {
        VStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
            Text("Prueba con otra búsqueda o categoría.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .multilineTextAlignment(.center)
    }

    private var title: LocalizedStringKey {
        switch section {
        case .all: "No hay notas que coincidan"
        case .pinned: "Todavía no hay notas fijadas"
        case .archived: "Todavía no hay notas archivadas"
        }
    }

    private var symbol: String {
        switch section {
        case .all: "magnifyingglass"
        case .pinned: "pin"
        case .archived: "archivebox"
        }
    }
}

#Preview("Nota · tarjeta") {
    NotesListCard(
        section: .all,
        notes: Array(NotesPreviewData.neoNotes.prefix(1)),
        onShowDetail: { _ in },
        onTogglePin: { _ in },
        onToggleArchive: { _ in }
    )
    .padding()
    .frame(width: 760)
    .appCanvas()
}
