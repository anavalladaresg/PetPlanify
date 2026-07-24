import SwiftUI

struct RemindersView: View {
    @State private var selectedSection: ReminderSection = .upcoming
    @State private var selectedCategory: ReminderCategoryFilter = .all
    @State private var reminders = RemindersPreviewData.neoReminders
    @State private var displayedMonth = RemindersPreviewData.referenceDate
    @State private var selectedCalendarDay = RemindersPreviewData.referenceDate
    @State private var presentedSheet: ReminderPresentation?

    private var overview: ReminderOverview {
        ReminderOverview(
            reminders: reminders,
            referenceDate: RemindersPreviewData.referenceDate
        )
    }

    var body: some View {
        Group {
            #if os(macOS)
            RemindersMacView(
                overview: overview,
                selectedSection: $selectedSection,
                selectedCategory: $selectedCategory,
                displayedMonth: $displayedMonth,
                selectedCalendarDay: $selectedCalendarDay,
                onPresent: { presentedSheet = $0 },
                onToggleCompletion: toggleCompletion
            )
            #else
            RemindersPhoneView(
                overview: overview,
                selectedSection: $selectedSection,
                selectedCategory: $selectedCategory,
                displayedMonth: $displayedMonth,
                selectedCalendarDay: $selectedCalendarDay,
                onPresent: { presentedSheet = $0 },
                onToggleCompletion: toggleCompletion
            )
            #endif
        }
        .environment(\.locale, ReminderFormatting.spanishLocale)
        .sheet(item: $presentedSheet) { presentation in
            RemindersDetailSheet(
                presentation: presentation,
                onToggleCompletion: { reminder in
                    toggleCompletion(reminder)
                    presentedSheet = nil
                },
                onDismiss: { presentedSheet = nil }
            )
        }
    }

    private func toggleCompletion(_ reminder: PetReminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else {
            return
        }
        let nextStatus: ReminderStatus = reminder.isCompleted
            ? overview.pendingStatus(for: reminder)
            : .completed
        reminders[index] = reminder.updating(status: nextStatus)
    }
}
