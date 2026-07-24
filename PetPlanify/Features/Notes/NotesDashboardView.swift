import SwiftUI

struct NotesMacView: View {
    let overview: NotesOverview
    @Binding var selectedSection: NotesSection
    @Binding var searchText: String
    @Binding var selectedCategory: NoteCategoryFilter
    @Binding var sortOrder: NoteSortOrder
    let onPresent: (NotesPresentation) -> Void
    let onTogglePin: (PetNote) -> Void
    let onToggleArchive: (PetNote) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                NotesHeader(includesTitle: true) {
                    onPresent(.create)
                }
                NotesSectionSelector(selection: $selectedSection)
                    .frame(maxWidth: 720)
                NotesControls(
                    searchText: $searchText,
                    selectedCategory: $selectedCategory,
                    sortOrder: $sortOrder
                )
                NotesContent(
                    overview: overview,
                    selectedSection: selectedSection,
                    searchText: searchText,
                    selectedCategory: selectedCategory,
                    sortOrder: sortOrder,
                    compact: false,
                    onPresent: onPresent,
                    onTogglePin: onTogglePin,
                    onToggleArchive: onToggleArchive
                )
            }
            .frame(maxWidth: 1_180, alignment: .leading)
            .padding(32)
        }
        .appCanvas()
        .accessibilityIdentifier("notes.screen")
    }
}

struct NotesPhoneView: View {
    let overview: NotesOverview
    @Binding var selectedSection: NotesSection
    @Binding var searchText: String
    @Binding var selectedCategory: NoteCategoryFilter
    @Binding var sortOrder: NoteSortOrder
    let onPresent: (NotesPresentation) -> Void
    let onTogglePin: (PetNote) -> Void
    let onToggleArchive: (PetNote) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                NotesHeader(includesTitle: false) {
                    onPresent(.create)
                }
                NotesSectionSelector(selection: $selectedSection)
                NotesControls(
                    searchText: $searchText,
                    selectedCategory: $selectedCategory,
                    sortOrder: $sortOrder
                )
                NotesContent(
                    overview: overview,
                    selectedSection: selectedSection,
                    searchText: searchText,
                    selectedCategory: selectedCategory,
                    sortOrder: sortOrder,
                    compact: true,
                    onPresent: onPresent,
                    onTogglePin: onTogglePin,
                    onToggleArchive: onToggleArchive
                )

                Button {
                    onPresent(.create)
                } label: {
                    Label("Nueva nota", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .appCanvas()
        .accessibilityIdentifier("notes.screen")
    }
}

private struct NotesHeader: View {
    let includesTitle: Bool
    let onAdd: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 20) {
                titleBlock
                Spacer(minLength: 12)
                addButton
            }
            VStack(alignment: .leading, spacing: 14) {
                titleBlock
                addButton
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            if includesTitle {
                Text("Notas")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("Observaciones de Neo, ordenadas y fáciles de encontrar.")
                .font(includesTitle ? .title3 : .subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Label("Nueva nota", systemImage: "plus")
                .frame(minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityHint("Abre una vista previa sin almacenamiento")
        .accessibilityIdentifier("notes.add")
    }
}

struct NotesContent: View {
    let overview: NotesOverview
    let selectedSection: NotesSection
    let searchText: String
    let selectedCategory: NoteCategoryFilter
    let sortOrder: NoteSortOrder
    let compact: Bool
    let onPresent: (NotesPresentation) -> Void
    let onTogglePin: (PetNote) -> Void
    let onToggleArchive: (PetNote) -> Void

    private var displayedNotes: [PetNote] {
        overview.filteredNotes(
            section: selectedSection,
            searchText: searchText,
            categoryFilter: selectedCategory,
            sortOrder: sortOrder
        )
    }

    private var featuredNote: PetNote? {
        displayedNotes.first(where: \.isPinned)
    }

    var body: some View {
        VStack(spacing: compact ? 16 : 18) {
            NotesSummaryGrid(overview: overview, compact: compact)

            if compact {
                notesList
            } else {
                if let featuredNote {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 18) {
                            notesList
                                .frame(minWidth: 660)
                            FeaturedNoteCard(
                                note: featuredNote,
                                onShowDetail: { onPresent(.detail($0)) }
                            )
                            .frame(minWidth: 300)
                        }
                        notesList
                    }
                } else {
                    notesList
                }
            }

            Text("Los cambios de fijado y archivo son temporales y solo se conservan durante esta sesión.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var notesList: some View {
        NotesListCard(
            section: selectedSection,
            notes: displayedNotes,
            onShowDetail: { onPresent(.detail($0)) },
            onTogglePin: onTogglePin,
            onToggleArchive: onToggleArchive
        )
    }
}

#Preview("Notas · macOS") {
    NotesMacView(
        overview: NotesPreviewData.neoOverview,
        selectedSection: .constant(.all),
        searchText: .constant(""),
        selectedCategory: .constant(.all),
        sortOrder: .constant(.newest),
        onPresent: { _ in },
        onTogglePin: { _ in },
        onToggleArchive: { _ in }
    )
    .frame(width: 1_180, height: 920)
}

#Preview("Notas · iPhone") {
    NavigationStack {
        NotesPhoneView(
            overview: NotesPreviewData.neoOverview,
            selectedSection: .constant(.all),
            searchText: .constant(""),
            selectedCategory: .constant(.all),
            sortOrder: .constant(.newest),
            onPresent: { _ in },
            onTogglePin: { _ in },
            onToggleArchive: { _ in }
        )
        .navigationTitle("Notas")
    }
    .frame(width: 393, height: 852)
}

#Preview("Notas · Fijadas") {
    ScrollView {
        NotesContent(
            overview: NotesPreviewData.neoOverview,
            selectedSection: .pinned,
            searchText: "",
            selectedCategory: .all,
            sortOrder: .newest,
            compact: true,
            onPresent: { _ in },
            onTogglePin: { _ in },
            onToggleArchive: { _ in }
        )
        .padding()
    }
    .frame(width: 430, height: 780)
    .appCanvas()
}

#Preview("Notas · Archivadas") {
    ScrollView {
        NotesContent(
            overview: NotesPreviewData.neoOverview,
            selectedSection: .archived,
            searchText: "",
            selectedCategory: .all,
            sortOrder: .newest,
            compact: true,
            onPresent: { _ in },
            onTogglePin: { _ in },
            onToggleArchive: { _ in }
        )
        .padding()
    }
    .frame(width: 430, height: 780)
    .appCanvas()
}
