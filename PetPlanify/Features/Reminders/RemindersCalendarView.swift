import SwiftUI

struct RemindersCalendarView: View {
    let overview: ReminderOverview
    let categoryFilter: ReminderCategoryFilter
    @Binding var displayedMonth: Date
    @Binding var selectedDay: Date
    let onShowDetail: (PetReminder) -> Void
    let onToggleCompletion: (PetReminder) -> Void

    private var days: [ReminderCalendarDay] {
        overview.calendarDays(for: displayedMonth, matching: categoryFilter)
    }

    private var selectedReminders: [PetReminder] {
        overview.reminders(on: selectedDay, matching: categoryFilter)
    }

    var body: some View {
        VStack(spacing: 18) {
            calendarCard
            ReminderListCard(
                title: selectedDayTitle,
                symbol: "calendar",
                reminders: selectedReminders,
                emptyMessage: "No hay recordatorios para este día.",
                identifier: "reminders.calendarSelection",
                onShowDetail: onShowDetail,
                onToggleCompletion: onToggleCompletion
            )
        }
        .accessibilityIdentifier("reminders.calendar")
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Button {
                    moveMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Mes anterior")

                Spacer()
                Text(ReminderFormatting.monthAndYear(displayedMonth))
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()

                Button {
                    moveMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Mes siguiente")
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7),
                spacing: 7
            ) {
                ForEach(Array(weekdayTitles.enumerated()), id: \.offset) { _, title in
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryInk)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }

                ForEach(days) { day in
                    CalendarDayCell(
                        day: day,
                        isSelected: ReminderFormatting.spanishCalendar.isDate(
                            day.date,
                            inSameDayAs: selectedDay
                        ),
                        onSelect: { selectedDay = day.date }
                    )
                }
            }
        }
        .padding(20)
        .appSurface()
    }

    private var selectedDayTitle: LocalizedStringKey {
        LocalizedStringKey(
            String(localized: "Recordatorios del \(ReminderFormatting.date(selectedDay))")
        )
    }

    private var weekdayTitles: [String] {
        let formatter = DateFormatter()
        formatter.locale = ReminderFormatting.spanishLocale
        let sundayFirst = formatter.shortStandaloneWeekdaySymbols ?? []
        guard sundayFirst.count == 7 else {
            return ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"]
        }
        return Array(sundayFirst[1...]) + [sundayFirst[0]]
    }

    private func moveMonth(by value: Int) {
        let calendar = ReminderFormatting.spanishCalendar
        guard
            let nextMonth = calendar.date(
                byAdding: .month,
                value: value,
                to: displayedMonth
            ),
            let interval = calendar.dateInterval(of: .month, for: nextMonth)
        else {
            return
        }
        displayedMonth = nextMonth
        selectedDay = interval.start
    }
}

private struct CalendarDayCell: View {
    let day: ReminderCalendarDay
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Text(ReminderFormatting.dayNumber(day.date))
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .monospacedDigit()

                if !day.reminders.isEmpty {
                    Text(day.reminders.count.formatted())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.surface)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(AppTheme.orange, in: Capsule())
                } else {
                    Color.clear
                        .frame(width: 18, height: 18)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(day.isInDisplayedMonth ? AppTheme.ink : AppTheme.secondaryInk.opacity(0.45))
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isSelected ? AppTheme.greenSoft.opacity(0.72) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(isSelected ? AppTheme.green : AppTheme.border, lineWidth: isSelected ? 1.4 : 0.6)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityLabel: String {
        let count = day.reminders.count
        let reminderCount = count == 1
            ? String(localized: "1 recordatorio")
            : String(localized: "\(count) recordatorios")
        return String(
            localized: "\(ReminderFormatting.date(day.date)), \(reminderCount)"
        )
    }
}

#Preview("Recordatorios · Calendario") {
    ScrollView {
        RemindersCalendarView(
            overview: RemindersPreviewData.neoOverview,
            categoryFilter: .all,
            displayedMonth: .constant(RemindersPreviewData.referenceDate),
            selectedDay: .constant(RemindersPreviewData.referenceDate),
            onShowDetail: { _ in },
            onToggleCompletion: { _ in }
        )
        .padding()
    }
    .frame(width: 760, height: 860)
    .appCanvas()
}
