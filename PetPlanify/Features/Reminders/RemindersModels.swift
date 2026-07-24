import Foundation

enum ReminderSection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case upcoming
    case calendar
    case completed

    var id: Self { self }

    var title: String {
        switch self {
        case .upcoming: String(localized: "Próximos")
        case .calendar: String(localized: "Calendario")
        case .completed: String(localized: "Completados")
        }
    }
}

enum ReminderCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case health
    case medication
    case nutrition
    case training
    case weight

    var id: Self { self }

    var title: String {
        switch self {
        case .health: String(localized: "Salud")
        case .medication: String(localized: "Medicación")
        case .nutrition: String(localized: "Alimentación")
        case .training: String(localized: "Entrenamiento")
        case .weight: String(localized: "Peso")
        }
    }

    var symbol: String {
        switch self {
        case .health: "cross.case"
        case .medication: "pills"
        case .nutrition: "fork.knife"
        case .training: "figure.walk"
        case .weight: "scalemass"
        }
    }
}

enum ReminderCategoryFilter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all
    case health
    case medication
    case nutrition
    case training
    case weight

    var id: Self { self }

    var title: String {
        switch self {
        case .all: String(localized: "Todos")
        case .health: String(localized: "Salud")
        case .medication: String(localized: "Medicación")
        case .nutrition: String(localized: "Alimentación")
        case .training: String(localized: "Entrenamiento")
        case .weight: String(localized: "Peso")
        }
    }

    var category: ReminderCategory? {
        switch self {
        case .all: nil
        case .health: .health
        case .medication: .medication
        case .nutrition: .nutrition
        case .training: .training
        case .weight: .weight
        }
    }
}

enum ReminderPriority: Int, CaseIterable, Identifiable, Hashable, Sendable {
    case low
    case medium
    case high

    var id: Self { self }

    var title: String {
        switch self {
        case .low: String(localized: "Baja")
        case .medium: String(localized: "Media")
        case .high: String(localized: "Alta")
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .low: String(localized: "Prioridad baja")
        case .medium: String(localized: "Prioridad media")
        case .high: String(localized: "Prioridad alta")
        }
    }
}

enum ReminderStatus: String, Hashable, Sendable {
    case upcoming
    case overdue
    case completed

    var title: String {
        switch self {
        case .upcoming: String(localized: "Próximo")
        case .overdue: String(localized: "Vencido")
        case .completed: String(localized: "Completado")
        }
    }
}

enum ReminderRecurrence: String, CaseIterable, Identifiable, Hashable, Sendable {
    case none
    case monthly
    case yearly

    var id: Self { self }

    var title: String {
        switch self {
        case .none: String(localized: "Sin repetición")
        case .monthly: String(localized: "Mensual")
        case .yearly: String(localized: "Anual")
        }
    }
}

struct PetReminder: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let date: Date
    let category: ReminderCategory
    let priority: ReminderPriority
    let status: ReminderStatus
    let notes: String
    let recurrence: ReminderRecurrence

    var isCompleted: Bool {
        status == .completed
    }

    func updating(status: ReminderStatus) -> Self {
        Self(
            id: id,
            title: title,
            date: date,
            category: category,
            priority: priority,
            status: status,
            notes: notes,
            recurrence: recurrence
        )
    }
}

struct ReminderCalendarDay: Identifiable, Hashable, Sendable {
    let date: Date
    let isInDisplayedMonth: Bool
    let reminders: [PetReminder]

    var id: Date { date }
}

struct ReminderOverview: Hashable, Sendable {
    let reminders: [PetReminder]
    let referenceDate: Date

    var upcoming: [PetReminder] {
        reminders
            .filter { $0.status == .upcoming }
            .sorted { $0.date < $1.date }
    }

    var overdue: [PetReminder] {
        reminders
            .filter { $0.status == .overdue }
            .sorted { $0.date < $1.date }
    }

    var completed: [PetReminder] {
        reminders
            .filter { $0.status == .completed }
            .sorted { $0.date > $1.date }
    }

    var todayCount: Int {
        let calendar = ReminderFormatting.spanishCalendar
        return reminders.filter {
            $0.status != .completed
                && calendar.isDate($0.date, inSameDayAs: referenceDate)
        }.count
    }

    func reminders(
        in reminders: [PetReminder],
        matching filter: ReminderCategoryFilter
    ) -> [PetReminder] {
        guard let category = filter.category else { return reminders }
        return reminders.filter { $0.category == category }
    }

    func reminders(on date: Date, matching filter: ReminderCategoryFilter) -> [PetReminder] {
        let calendar = ReminderFormatting.spanishCalendar
        return reminders(
            in: reminders.filter { calendar.isDate($0.date, inSameDayAs: date) },
            matching: filter
        ).sorted { $0.date < $1.date }
    }

    func calendarDays(
        for month: Date,
        matching filter: ReminderCategoryFilter
    ) -> [ReminderCalendarDay] {
        let calendar = ReminderFormatting.spanishCalendar
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: month),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
            let lastDate = calendar.date(
                byAdding: .day,
                value: -1,
                to: monthInterval.end
            ),
            let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: lastDate)
        else {
            return []
        }

        var days: [ReminderCalendarDay] = []
        var date = firstWeek.start
        while date < lastWeek.end {
            days.append(
                ReminderCalendarDay(
                    date: date,
                    isInDisplayedMonth: calendar.isDate(date, equalTo: month, toGranularity: .month),
                    reminders: reminders(on: date, matching: filter)
                )
            )
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else {
                break
            }
            date = next
        }
        return days
    }

    func pendingStatus(for reminder: PetReminder) -> ReminderStatus {
        reminder.date < ReminderFormatting.startOfReferenceDay(referenceDate)
            ? .overdue
            : .upcoming
    }
}

enum ReminderPresentation: Identifiable, Hashable, Sendable {
    case create
    case detail(PetReminder)

    var id: String {
        switch self {
        case .create: "create"
        case let .detail(reminder): "detail-\(reminder.id)"
        }
    }
}

enum ReminderFormatting {
    static let spanishLocale = Locale(identifier: "es_ES")

    static var spanishCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = spanishLocale
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        calendar.firstWeekday = 2
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

    static func time(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle()
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
                .locale(spanishLocale)
        )
    }

    static func monthAndYear(_ value: Date) -> String {
        let formatted = value.formatted(
            Date.FormatStyle()
                .month(.wide)
                .year()
                .locale(spanishLocale)
        )
        guard let first = formatted.first else { return formatted }
        return String(first).uppercased(with: spanishLocale)
            + String(formatted.dropFirst())
    }

    static func dayNumber(_ value: Date) -> String {
        value.formatted(
            Date.FormatStyle()
                .day()
                .locale(spanishLocale)
        )
    }

    static func startOfReferenceDay(_ value: Date) -> Date {
        spanishCalendar.startOfDay(for: value)
    }
}
