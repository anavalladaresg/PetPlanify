import SwiftUI

struct AppReminderButton: View {
    @Binding var reminders: [CareReminder]
    let onOpenSection: (AppSection) -> Void
    @State private var isPresented = false

    private var pendingCount: Int {
        reminders.filter { !$0.isCompleted }.count
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label("Próximamente", systemImage: pendingCount > 0 ? "bell.badge" : "bell")
        }
        .labelStyle(.iconOnly)
        .help("Próximamente")
        .accessibilityLabel("\(pendingCount) recordatorios pendientes")
        .accessibilityIdentifier("app.reminders")
        #if os(macOS)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            content
                .frame(width: 380)
        }
        #else
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                content
                    .navigationTitle("Próximamente")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Cerrar") { isPresented = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        #endif
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                #if os(macOS)
                Text("Próximamente")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .padding(.bottom, 12)
                #endif

                ForEach(reminders.sorted { $0.date < $1.date }) { reminder in
                    reminderRow(reminder)
                    if reminder.id != reminders.sorted(by: { $0.date < $1.date }).last?.id {
                        Divider().overlay(AppTheme.border)
                    }
                }
            }
            .padding(18)
        }
        .appCanvas()
    }

    private func reminderRow(_ reminder: CareReminder) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                toggle(reminder)
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(reminder.isCompleted ? AppTheme.green : AppTheme.secondaryInk)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                reminder.isCompleted ? "Marcar \(reminder.title) como pendiente" : "Marcar \(reminder.title) como completado"
            )

            Button {
                isPresented = false
                onOpenSection(reminder.section)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(reminder.date.formatted(
                        Date.FormatStyle(date: .abbreviated, time: .shortened)
                            .locale(Locale(identifier: "es_ES"))
                    ))
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    if reminder.isOverdue {
                        Text("Pendiente")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                "\(reminder.title), \(reminder.section.titleText), \(reminder.isCompleted ? "completado" : "pendiente")"
            )
        }
        .padding(.vertical, 11)
    }

    private func toggle(_ reminder: CareReminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].isCompleted.toggle()
    }
}

extension AppSection {
    var titleText: String {
        switch self {
        case .home: "Inicio"
        case .nutrition: "Alimentación"
        case .health: "Salud"
        case .training: "Entrenamiento"
        case .settings: "Ajustes"
        }
    }
}
