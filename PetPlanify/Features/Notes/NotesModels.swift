import Foundation

enum NotesSection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all
    case pinned
    case archived

    var id: Self { self }

    var title: String {
        switch self {
        case .all: String(localized: "Todas")
        case .pinned: String(localized: "Fijadas")
        case .archived: String(localized: "Archivadas")
        }
    }
}

enum NoteCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case general
    case health
    case nutrition
    case training

    var id: Self { self }

    var title: String {
        switch self {
        case .general: String(localized: "General")
        case .health: String(localized: "Salud")
        case .nutrition: String(localized: "Alimentación")
        case .training: String(localized: "Entrenamiento")
        }
    }

    var symbol: String {
        switch self {
        case .general: "note.text"
        case .health: "heart"
        case .nutrition: "fork.knife"
        case .training: "figure.walk"
        }
    }
}

enum NoteCategoryFilter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all
    case general
    case health
    case nutrition
    case training

    var id: Self { self }

    var title: String {
        switch self {
        case .all: String(localized: "Todas")
        case .general: String(localized: "General")
        case .health: String(localized: "Salud")
        case .nutrition: String(localized: "Alimentación")
        case .training: String(localized: "Entrenamiento")
        }
    }

    var category: NoteCategory? {
        switch self {
        case .all: nil
        case .general: .general
        case .health: .health
        case .nutrition: .nutrition
        case .training: .training
        }
    }
}

enum NoteSortOrder: String, CaseIterable, Identifiable, Hashable, Sendable {
    case newest
    case oldest
    case title

    var id: Self { self }

    var title: String {
        switch self {
        case .newest: String(localized: "Más recientes")
        case .oldest: String(localized: "Más antiguas")
        case .title: String(localized: "Título")
        }
    }
}

struct PetNote: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let body: String
    let createdAt: Date
    let updatedAt: Date?
    let category: NoteCategory
    let isPinned: Bool
    let isArchived: Bool
    let tags: [String]

    var hasBeenUpdated: Bool {
        guard let updatedAt else { return false }
        return updatedAt > createdAt
    }

    func updating(isPinned: Bool? = nil, isArchived: Bool? = nil) -> Self {
        Self(
            id: id,
            title: title,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt,
            category: category,
            isPinned: isPinned ?? self.isPinned,
            isArchived: isArchived ?? self.isArchived,
            tags: tags
        )
    }
}

struct NotesOverview: Hashable, Sendable {
    let notes: [PetNote]

    var activeNotes: [PetNote] {
        notes.filter { !$0.isArchived }
    }

    var pinnedNotes: [PetNote] {
        notes.filter { $0.isPinned && !$0.isArchived }
    }

    var archivedNotes: [PetNote] {
        notes.filter(\.isArchived)
    }

    var categoryCount: Int {
        Set(notes.map(\.category)).count
    }

    func filteredNotes(
        section: NotesSection,
        searchText: String,
        categoryFilter: NoteCategoryFilter,
        sortOrder: NoteSortOrder
    ) -> [PetNote] {
        let sectionNotes: [PetNote] = switch section {
        case .all: activeNotes
        case .pinned: pinnedNotes
        case .archived: archivedNotes
        }

        let normalizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = sectionNotes.filter { note in
            let matchesCategory = categoryFilter.category.map { note.category == $0 } ?? true
            let matchesSearch = normalizedQuery.isEmpty
                || note.title.localizedCaseInsensitiveContains(normalizedQuery)
                || note.body.localizedCaseInsensitiveContains(normalizedQuery)
                || note.tags.contains { $0.localizedCaseInsensitiveContains(normalizedQuery) }
            return matchesCategory && matchesSearch
        }

        let sorted = filtered.sorted { lhs, rhs in
            switch sortOrder {
            case .newest:
                lhs.createdAt > rhs.createdAt
            case .oldest:
                lhs.createdAt < rhs.createdAt
            case .title:
                lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
        }

        guard section == .all else { return sorted }
        return sorted.filter(\.isPinned) + sorted.filter { !$0.isPinned }
    }
}

enum NotesPresentation: Identifiable, Hashable, Sendable {
    case create
    case detail(PetNote)
    case edit(PetNote)

    var id: String {
        switch self {
        case .create: "create"
        case let .detail(note): "detail-\(note.id)"
        case let .edit(note): "edit-\(note.id)"
        }
    }
}

enum NotesFormatting {
    static let spanishLocale = Locale(identifier: "es_ES")

    static var spanishCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = spanishLocale
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        return calendar
    }

    static func dateAndTime(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle()
                .day()
                .month(.wide)
                .year()
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
                .locale(spanishLocale)
        )
    }

    static func date(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle()
                .day()
                .month(.wide)
                .year()
                .locale(spanishLocale)
        )
    }
}
