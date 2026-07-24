import SwiftUI

struct RemindersMacView: View {
    let overview: ReminderOverview
    @Binding var selectedSection: ReminderSection
    @Binding var selectedCategory: ReminderCategoryFilter
    @Binding var displayedMonth: Date
    @Binding var selectedCalendarDay: Date
    let onPresent: (ReminderPresentation) -> Void
    let onToggleCompletion: (PetReminder) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                RemindersHeader(includesTitle: true, onAdd: { onPresent(.create) })
                ReminderSectionSelector(selection: $selectedSection)
                    .frame(maxWidth: 720)

                RemindersSectionContent(
                    section: selectedSection,
                    overview: overview,
                    selectedCategory: $selectedCategory,
                    displayedMonth: $displayedMonth,
                    selectedCalendarDay: $selectedCalendarDay,
                    compact: false,
                    onPresent: onPresent,
                    onToggleCompletion: onToggleCompletion
                )
            }
            .frame(maxWidth: 1_180, alignment: .leading)
            .padding(32)
        }
        .appCanvas()
        .accessibilityIdentifier("reminders.screen")
    }
}

struct RemindersPhoneView: View {
    let overview: ReminderOverview
    @Binding var selectedSection: ReminderSection
    @Binding var selectedCategory: ReminderCategoryFilter
    @Binding var displayedMonth: Date
    @Binding var selectedCalendarDay: Date
    let onPresent: (ReminderPresentation) -> Void
    let onToggleCompletion: (PetReminder) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RemindersHeader(includesTitle: false, onAdd: { onPresent(.create) })
                ReminderSectionSelector(selection: $selectedSection)

                RemindersSectionContent(
                    section: selectedSection,
                    overview: overview,
                    selectedCategory: $selectedCategory,
                    displayedMonth: $displayedMonth,
                    selectedCalendarDay: $selectedCalendarDay,
                    compact: true,
                    onPresent: onPresent,
                    onToggleCompletion: onToggleCompletion
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .appCanvas()
        .accessibilityIdentifier("reminders.screen")
    }
}

private struct RemindersHeader: View {
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
                Text("Recordatorios")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("Las tareas importantes de Neo, ordenadas con calma.")
                .font(includesTitle ? .title3 : .subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Label("Nuevo recordatorio", systemImage: "plus")
                .frame(minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityHint("Abre una vista previa sin almacenamiento ni notificaciones")
        .accessibilityIdentifier("reminders.add")
    }
}

struct RemindersSectionContent: View {
    let section: ReminderSection
    let overview: ReminderOverview
    @Binding var selectedCategory: ReminderCategoryFilter
    @Binding var displayedMonth: Date
    @Binding var selectedCalendarDay: Date
    let compact: Bool
    let onPresent: (ReminderPresentation) -> Void
    let onToggleCompletion: (PetReminder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 16 : 18) {
            ReminderCategoryFilterView(selection: $selectedCategory)

            switch section {
            case .upcoming:
                RemindersUpcomingSection(
                    overview: overview,
                    categoryFilter: selectedCategory,
                    compact: compact,
                    onPresent: onPresent,
                    onToggleCompletion: onToggleCompletion
                )
            case .calendar:
                RemindersCalendarView(
                    overview: overview,
                    categoryFilter: selectedCategory,
                    displayedMonth: $displayedMonth,
                    selectedDay: $selectedCalendarDay,
                    onShowDetail: { onPresent(.detail($0)) },
                    onToggleCompletion: onToggleCompletion
                )
            case .completed:
                RemindersCompletedSection(
                    overview: overview,
                    categoryFilter: selectedCategory,
                    onPresent: onPresent,
                    onToggleCompletion: onToggleCompletion
                )
            }
        }
    }
}

private struct RemindersUpcomingSection: View {
    let overview: ReminderOverview
    let categoryFilter: ReminderCategoryFilter
    let compact: Bool
    let onPresent: (ReminderPresentation) -> Void
    let onToggleCompletion: (PetReminder) -> Void

    private var upcoming: [PetReminder] {
        overview.reminders(in: overview.upcoming, matching: categoryFilter)
    }

    private var overdue: [PetReminder] {
        overview.reminders(in: overview.overdue, matching: categoryFilter)
    }

    private var nextReminder: PetReminder? {
        upcoming.first
    }

    var body: some View {
        VStack(spacing: compact ? 16 : 18) {
            ReminderSummaryGrid(overview: overview, compact: compact)

            if compact {
                VStack(spacing: 16) {
                    nextReminderContent
                    overdueContent
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        nextReminderContent
                            .frame(minWidth: 620)
                        overdueContent
                            .frame(minWidth: 340)
                    }
                    VStack(spacing: 18) {
                        nextReminderContent
                        overdueContent
                    }
                }
            }

            ReminderListCard(
                title: "Próximos recordatorios",
                symbol: "list.bullet",
                reminders: upcoming,
                emptyMessage: "No hay recordatorios próximos en esta categoría.",
                identifier: "reminders.upcomingList",
                onShowDetail: { onPresent(.detail($0)) },
                onToggleCompletion: onToggleCompletion
            )

            if compact {
                Button {
                    onPresent(.create)
                } label: {
                    Label("Nuevo recordatorio", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private var nextReminderContent: some View {
        if let nextReminder {
            NextReminderCard(
                reminder: nextReminder,
                onShowDetail: { onPresent(.detail(nextReminder)) },
                onToggleCompletion: { onToggleCompletion(nextReminder) }
            )
        } else {
            EmptyReminderSurface(
                title: "Sin próximos recordatorios",
                message: "No hay recordatorios próximos en esta categoría.",
                symbol: "calendar"
            )
            .accessibilityIdentifier("reminders.next")
        }
    }

    private var overdueContent: some View {
        OverdueReminderCard(
            reminders: overdue,
            onShowDetail: { onPresent(.detail($0)) },
            onToggleCompletion: onToggleCompletion
        )
    }
}

private struct RemindersCompletedSection: View {
    let overview: ReminderOverview
    let categoryFilter: ReminderCategoryFilter
    let onPresent: (ReminderPresentation) -> Void
    let onToggleCompletion: (PetReminder) -> Void

    private var completed: [PetReminder] {
        overview.reminders(in: overview.completed, matching: categoryFilter)
    }

    var body: some View {
        VStack(spacing: 18) {
            ReminderListCard(
                title: "Recordatorios completados",
                symbol: "checkmark.circle",
                reminders: completed,
                emptyMessage: "Todavía no hay recordatorios completados",
                identifier: "reminders.completed",
                onShowDetail: { onPresent(.detail($0)) },
                onToggleCompletion: onToggleCompletion
            )

            Text("Los cambios de estado son temporales y solo se conservan durante esta sesión.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct EmptyReminderSurface: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let symbol: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 170)
        .padding(20)
        .appSurface()
    }
}

#Preview("Recordatorios · macOS") {
    RemindersMacView(
        overview: RemindersPreviewData.neoOverview,
        selectedSection: .constant(.upcoming),
        selectedCategory: .constant(.all),
        displayedMonth: .constant(RemindersPreviewData.referenceDate),
        selectedCalendarDay: .constant(RemindersPreviewData.referenceDate),
        onPresent: { _ in },
        onToggleCompletion: { _ in }
    )
    .frame(width: 1_180, height: 920)
}

#Preview("Recordatorios · iPhone") {
    NavigationStack {
        RemindersPhoneView(
            overview: RemindersPreviewData.neoOverview,
            selectedSection: .constant(.upcoming),
            selectedCategory: .constant(.all),
            displayedMonth: .constant(RemindersPreviewData.referenceDate),
            selectedCalendarDay: .constant(RemindersPreviewData.referenceDate),
            onPresent: { _ in },
            onToggleCompletion: { _ in }
        )
        .navigationTitle("Recordatorios")
    }
    .frame(width: 393, height: 852)
}

#Preview("Recordatorios · Completados") {
    ScrollView {
        RemindersSectionContent(
            section: .completed,
            overview: RemindersPreviewData.neoOverview,
            selectedCategory: .constant(.all),
            displayedMonth: .constant(RemindersPreviewData.referenceDate),
            selectedCalendarDay: .constant(RemindersPreviewData.referenceDate),
            compact: true,
            onPresent: { _ in },
            onToggleCompletion: { _ in }
        )
        .padding()
    }
    .frame(width: 430, height: 780)
    .appCanvas()
}
