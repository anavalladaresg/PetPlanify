import Foundation

enum TrickStatus: Hashable, Sendable {
    case mastered
    case inProgress
    case notStarted

    var title: String {
        switch self {
        case .mastered: String(localized: "Dominado")
        case .inProgress: String(localized: "En progreso")
        case .notStarted: String(localized: "Por empezar")
        }
    }
}

enum BehaviorNoteStatus: Hashable, Sendable {
    case working
    case observation
    case improvement

    var title: String {
        switch self {
        case .working: String(localized: "En trabajo")
        case .observation: String(localized: "Observación")
        case .improvement: String(localized: "Mejora")
        }
    }
}

enum TrainingReward: Hashable, Sendable {
    case treats
    case treatsAndPraise

    var title: String {
        switch self {
        case .treats: String(localized: "Premios")
        case .treatsAndPraise: String(localized: "Premios y elogios")
        }
    }
}

enum PracticeRecency: Hashable, Sendable {
    case today
    case yesterday
    case date(Date)
    case never

    var title: String {
        switch self {
        case .today: String(localized: "Hoy")
        case .yesterday: String(localized: "Ayer")
        case let .date(date): TrainingFormatting.date(date)
        case .never: String(localized: "Nunca")
        }
    }
}

struct TrainingTrick: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let status: TrickStatus
    let progress: Int
    let successfulRepetitions: Int
    let lastPractised: PracticeRecency
    let reward: TrainingReward
}

struct TrainingSession: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let type: String
    let durationMinutes: Int
    let tricks: [String]
    let result: String
}

struct BehaviorNote: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let title: String
    let description: String
    let status: BehaviorNoteStatus
    let tags: [String]
}

struct TrainingOverview: Hashable, Sendable {
    let tricks: [TrainingTrick]
    let sessions: [TrainingSession]
    let behaviorNotes: [BehaviorNote]
    let weeklyMinutes: Int

    var masteredCount: Int {
        tricks.filter { $0.status == .mastered }.count
    }

    var inProgressCount: Int {
        tricks.filter { $0.status == .inProgress }.count
    }

}

enum TrainingDetail: Identifiable, Hashable, Sendable {
    case addTrick
    case addSession
    case trick(TrainingTrick)
    case session(TrainingSession)
    case behaviorNote(BehaviorNote)

    var id: String {
        switch self {
        case .addTrick: "add-trick"
        case .addSession: "add-session"
        case let .trick(trick): "trick-\(trick.id)"
        case let .session(session): "session-\(session.id)"
        case let .behaviorNote(note): "behavior-note-\(note.id)"
        }
    }
}

enum TrainingFormatting {
    static let spanishLocale = Locale(identifier: "es_ES")

    static func date(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle()
                .day()
                .month(.wide)
                .year()
                .locale(spanishLocale)
        )
    }

    static func sessionDate(_ value: Date) -> String {
        let calendar = spanishCalendar
        let day: String

        if calendar.isDate(value, inSameDayAs: TrainingPreviewData.referenceDate) {
            day = String(localized: "Hoy")
        } else if let yesterday = calendar.date(
            byAdding: .day,
            value: -1,
            to: TrainingPreviewData.referenceDate
        ), calendar.isDate(value, inSameDayAs: yesterday) {
            day = String(localized: "Ayer")
        } else {
            day = date(value)
        }

        return String(
            localized: "\(day), \(time(value))"
        )
    }

    static func time(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle()
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
                .locale(spanishLocale)
        )
    }

    private static var spanishCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = spanishLocale
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        return calendar
    }
}
