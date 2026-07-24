import SwiftUI

struct ReminderSectionSelector: View {
    @Binding var selection: ReminderSection

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ReminderSection.allCases) { section in
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
                .accessibilityIdentifier("reminders.section.\(section.rawValue)")
            }
        }
        .padding(4)
        .background(AppTheme.surface.opacity(0.66), in: Capsule())
        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 0.75))
        .accessibilityIdentifier("reminders.sectionPicker")
    }
}

struct ReminderCategoryFilterView: View {
    @Binding var selection: ReminderCategoryFilter

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 104), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(ReminderCategoryFilter.allCases) { filter in
                Button {
                    selection = filter
                } label: {
                    Text(filter.title)
                        .font(.caption.weight(selection == filter ? .semibold : .regular))
                        .foregroundStyle(selection == filter ? AppTheme.ink : AppTheme.secondaryInk)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(
                                    selection == filter
                                        ? AppTheme.greenSoft.opacity(0.78)
                                        : AppTheme.surface
                                )
                        )
                        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 0.65))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == filter ? .isSelected : [])
                .accessibilityIdentifier("reminders.filter.\(filter.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filtrar recordatorios por categoría")
        .accessibilityIdentifier("reminders.categoryFilter")
    }
}

struct ReminderSummaryGrid: View {
    let overview: ReminderOverview
    let compact: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columnCount: Int {
        if compact && dynamicTypeSize.isAccessibilitySize {
            return 1
        }
        return compact ? 2 : 4
    }

    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 12),
                count: columnCount
            ),
            spacing: 12
        ) {
            ReminderMetricCard(
                title: "Próximos",
                value: overview.upcoming.count.formatted(),
                detail: "Pendientes por llegar",
                symbol: "calendar.badge.clock",
                accent: AppTheme.orange
            )
            ReminderMetricCard(
                title: "Hoy",
                value: overview.todayCount.formatted(),
                detail: "12 de junio",
                symbol: "sun.max",
                accent: AppTheme.orange
            )
            ReminderMetricCard(
                title: "Vencidos",
                value: overview.overdue.count.formatted(),
                detail: "Pendientes anteriores",
                symbol: "clock.badge.exclamationmark",
                accent: AppTheme.secondaryInk
            )
            ReminderMetricCard(
                title: "Completados",
                value: overview.completed.count.formatted(),
                detail: "Registros locales",
                symbol: "checkmark.circle",
                accent: AppTheme.green
            )
        }
        .accessibilityIdentifier("reminders.summary")
    }
}

struct ReminderMetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let detail: LocalizedStringKey
    let symbol: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 32, height: 32)
                .background(accent.opacity(0.11), in: Circle())
                .accessibilityHidden(true)
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            Text(title)
                .font(.caption.weight(.medium))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
        .padding(16)
        .appSurface(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }
}

struct NextReminderCard: View {
    let reminder: PetReminder
    let onShowDetail: () -> Void
    let onToggleCompletion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: reminder.category.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.orange)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.orange.opacity(0.11), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Siguiente recordatorio")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryInk)
                    Text(reminder.title)
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                ReminderStatusBadge(status: reminder.status)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 28) {
                    reminderDetails
                    Spacer(minLength: 12)
                    actions
                }
                VStack(alignment: .leading, spacing: 16) {
                    reminderDetails
                    actions
                }
            }
        }
        .padding(22)
        .appSurface()
        .accessibilityIdentifier("reminders.next")
    }

    private var reminderDetails: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(ReminderFormatting.dateAndTime(reminder.date), systemImage: "calendar")
                .font(.headline)
            Text(reminder.notes)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                ReminderCategoryBadge(category: reminder.category)
                ReminderPriorityBadge(priority: reminder.priority)
            }
        }
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                detailButton
                completionButton
            }
            VStack(spacing: 10) {
                detailButton
                    .frame(maxWidth: .infinity)
                completionButton
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var detailButton: some View {
        Button("Ver detalle", action: onShowDetail)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityHint("Abre todos los datos del recordatorio")
    }

    private var completionButton: some View {
        Button(action: onToggleCompletion) {
            Label("Marcar como completado", systemImage: "checkmark")
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

struct ReminderListCard: View {
    let title: LocalizedStringKey
    let symbol: String
    let reminders: [PetReminder]
    let emptyMessage: LocalizedStringKey
    let identifier: String
    let onShowDetail: (PetReminder) -> Void
    let onToggleCompletion: (PetReminder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ReminderCardHeader(title: title, symbol: symbol)
                .padding(.bottom, 6)

            if reminders.isEmpty {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                    ReminderRow(
                        reminder: reminder,
                        onShowDetail: { onShowDetail(reminder) },
                        onToggleCompletion: { onToggleCompletion(reminder) }
                    )
                    if index < reminders.count - 1 {
                        Divider().overlay(AppTheme.border)
                    }
                }
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier(identifier)
    }
}

struct ReminderRow: View {
    let reminder: PetReminder
    let onShowDetail: () -> Void
    let onToggleCompletion: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Button(action: onToggleCompletion) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(reminder.isCompleted ? AppTheme.green : AppTheme.secondaryInk)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(completionActionTitle)
            .accessibilityHint("El cambio solo se conserva durante esta sesión")

            Button(action: onShowDetail) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        rowDetails
                        Spacer(minLength: 8)
                        rowMetadata
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        rowDetails
                        rowMetadata
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
            .accessibilityHint("Abre el detalle del recordatorio")
            .accessibilityAddTraits(.isButton)
        }
        .padding(.vertical, 9)
    }

    private var rowDetails: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(reminder.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(ReminderFormatting.dateAndTime(reminder.date))
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
            HStack(spacing: 7) {
                ReminderCategoryBadge(category: reminder.category)
                ReminderPriorityBadge(priority: reminder.priority)
            }
        }
        .multilineTextAlignment(.leading)
    }

    private var rowMetadata: some View {
        HStack(spacing: 8) {
            ReminderStatusBadge(status: reminder.status)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryInk)
                .accessibilityHidden(true)
        }
    }

    private var completionActionTitle: String {
        reminder.isCompleted
            ? String(localized: "Marcar como pendiente")
            : String(localized: "Marcar como completado")
    }

    private var accessibilitySummary: String {
        String(
            localized: "\(reminder.title), \(ReminderFormatting.dateAndTime(reminder.date)), categoría \(reminder.category.title), \(reminder.priority.accessibilityTitle), estado \(reminder.status.title)"
        )
    }
}

struct OverdueReminderCard: View {
    let reminders: [PetReminder]
    let onShowDetail: (PetReminder) -> Void
    let onToggleCompletion: (PetReminder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ReminderCardHeader(title: "Pendientes anteriores", symbol: "clock")
                .padding(.bottom, 6)

            if reminders.isEmpty {
                Text("No hay recordatorios vencidos en esta categoría.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ForEach(reminders) { reminder in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(
                            String(
                                localized: "Pendiente desde el \(ReminderFormatting.date(reminder.date))"
                            )
                        )
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryInk)
                        ReminderRow(
                            reminder: reminder,
                            onShowDetail: { onShowDetail(reminder) },
                            onToggleCompletion: { onToggleCompletion(reminder) }
                        )
                    }
                }
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("reminders.overdue")
    }
}

struct ReminderStatusBadge: View {
    let status: ReminderStatus

    var body: some View {
        Text(status.title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(accent.opacity(0.11), in: Capsule())
            .accessibilityLabel(String(localized: "Estado: \(status.title)"))
    }

    private var accent: Color {
        switch status {
        case .upcoming: AppTheme.orange
        case .overdue: AppTheme.secondaryInk
        case .completed: AppTheme.green
        }
    }
}

struct ReminderCategoryBadge: View {
    let category: ReminderCategory

    var body: some View {
        Label(category.title, systemImage: category.symbol)
            .font(.caption2.weight(.medium))
            .foregroundStyle(AppTheme.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppTheme.green.opacity(0.10), in: Capsule())
    }
}

struct ReminderPriorityBadge: View {
    let priority: ReminderPriority

    var body: some View {
        Text(priority.accessibilityTitle)
            .font(.caption2.weight(.medium))
            .foregroundStyle(priority == .high ? AppTheme.orange : AppTheme.secondaryInk)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                (priority == .high ? AppTheme.orange : AppTheme.secondaryInk)
                    .opacity(0.09),
                in: Capsule()
            )
    }
}

struct ReminderCardHeader: View {
    let title: LocalizedStringKey
    let symbol: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(.title3, design: .serif, weight: .semibold))
            Spacer(minLength: 0)
        }
    }
}

#Preview("Recordatorio · fila") {
    ReminderListCard(
        title: "Próximos recordatorios",
        symbol: "list.bullet",
        reminders: Array(RemindersPreviewData.neoReminders.prefix(1)),
        emptyMessage: "No hay recordatorios próximos en esta categoría.",
        identifier: "preview.reminderRow",
        onShowDetail: { _ in },
        onToggleCompletion: { _ in }
    )
    .padding()
    .frame(width: 720)
    .appCanvas()
}
