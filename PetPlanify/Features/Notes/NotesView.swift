import SwiftUI

struct NotesView: View {
    @State private var selectedSection: NotesSection = .all
    @State private var searchText = ""
    @State private var selectedCategory: NoteCategoryFilter = .all
    @State private var sortOrder: NoteSortOrder = .newest
    @State private var notes = NotesPreviewData.neoNotes
    @State private var presentedSheet: NotesPresentation?

    private var overview: NotesOverview {
        NotesOverview(notes: notes)
    }

    var body: some View {
        Group {
            #if os(macOS)
            NotesMacView(
                overview: overview,
                selectedSection: $selectedSection,
                searchText: $searchText,
                selectedCategory: $selectedCategory,
                sortOrder: $sortOrder,
                onPresent: { presentedSheet = $0 },
                onTogglePin: togglePin,
                onToggleArchive: toggleArchive
            )
            #else
            NotesPhoneView(
                overview: overview,
                selectedSection: $selectedSection,
                searchText: $searchText,
                selectedCategory: $selectedCategory,
                sortOrder: $sortOrder,
                onPresent: { presentedSheet = $0 },
                onTogglePin: togglePin,
                onToggleArchive: toggleArchive
            )
            #endif
        }
        .environment(\.locale, NotesFormatting.spanishLocale)
        .sheet(item: $presentedSheet) { presentation in
            NotesDetailSheet(
                presentation: presentation,
                onTogglePin: { note in
                    togglePin(note)
                    presentedSheet = .detail(updatedNote(for: note))
                },
                onToggleArchive: { note in
                    toggleArchive(note)
                    presentedSheet = .detail(updatedNote(for: note))
                },
                onEdit: { note in
                    presentedSheet = .edit(updatedNote(for: note))
                },
                onDismiss: { presentedSheet = nil }
            )
        }
    }

    private func togglePin(_ note: PetNote) {
        update(note) {
            $0.updating(isPinned: !$0.isPinned)
        }
    }

    private func toggleArchive(_ note: PetNote) {
        update(note) {
            $0.updating(
                isPinned: $0.isArchived ? $0.isPinned : false,
                isArchived: !$0.isArchived
            )
        }
    }

    private func update(_ note: PetNote, transform: (PetNote) -> PetNote) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index] = transform(notes[index])
    }

    private func updatedNote(for note: PetNote) -> PetNote {
        notes.first(where: { $0.id == note.id }) ?? note
    }
}
