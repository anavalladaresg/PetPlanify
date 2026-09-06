import SwiftUI

struct AppReminderButton: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(AppNavigation.self) private var navigation
    @State private var presented = false
    var body: some View {
        Button("Recordatorios", systemImage: store.pendingReminderCount > 0 ? "bell.badge" : "bell") { presented = true }
            .labelStyle(.iconOnly)
            .accessibilityValue(String(localized: "\(store.pendingReminderCount) pendientes"))
            .accessibilityIdentifier("app.reminders")
            .sheet(isPresented: $presented) { CompactRemindersView() }
    }
}

struct CompactRemindersView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.dismiss) private var dismiss
    @State private var adding = false
    @State private var editing: CareReminder?
    @State private var deleting: CareReminder?
    var body: some View {
        NavigationStack {
            List {
                if store.snapshot.reminders.isEmpty { Text("No tienes recordatorios. Añade uno cuando lo necesites.") }
                reminderSection("Fechas pasadas", values: store.snapshot.reminders.filter { !$0.isCompleted && $0.date <= .now })
                reminderSection("Próximamente", values: store.upcomingCare)
                reminderSection("Completados", values: store.snapshot.reminders.filter(\.isCompleted))
            }.scrollContentBackground(.hidden).appCanvas().navigationTitle("Recordatorios")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
                    ToolbarItem(placement: .primaryAction) { Button("Añadir recordatorio", systemImage: "plus") { adding = true }.accessibilityIdentifier("reminder.add") }
                }
        }
        #if os(macOS)
        .frame(minWidth: 440, idealWidth: 520, minHeight: 480)
        #endif
        .sheet(isPresented: $adding) { ReminderEditor() }
        .sheet(item: $editing) { ReminderEditor(record: $0) }
        .confirmationDialog("¿Eliminar este recordatorio?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("Eliminar", role: .destructive) {
                guard let id = deleting?.id else { return }
                Task { _ = await store.update { $0.reminders.removeAll { $0.id == id } } }
            }
        }
    }
    @ViewBuilder private func reminderSection(_ title: LocalizedStringKey, values: [CareReminder]) -> some View {
        if !values.isEmpty {
            Section(title) {
                ForEach(values.sorted { $0.date < $1.date }) { reminder in
                    HStack(alignment: .top, spacing: 12) {
                        Button {
                            Task { _ = await store.update {
                                guard let index = $0.reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
                                $0.reminders[index].isCompleted.toggle()
                                $0.reminders[index].completedAt = $0.reminders[index].isCompleted ? .now : nil
                            } }
                        } label: { Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle").font(.title2).frame(minWidth: 44, minHeight: 44) }
                        .buttonStyle(.borderless).accessibilityLabel(reminder.isCompleted ? "Reabrir recordatorio" : "Completar recordatorio")
                        Button {
                            navigation.selection = AppSection(context: reminder.relatedFeature)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reminder.title).font(.headline).foregroundStyle(AppTheme.ink)
                                Text(AppFormat.dateTime(reminder.date)).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                                if !reminder.notes.isEmpty { Text(reminder.notes).font(.caption).foregroundStyle(AppTheme.secondaryInk) }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }.buttonStyle(.plain)
                        if reminder.sourceKey == nil {
                            Menu {
                                Button("Editar") { editing = reminder }
                                Button("Eliminar", role: .destructive) { deleting = reminder }
                            } label: { Label("Opciones", systemImage: "ellipsis") }.menuStyle(.borderlessButton).labelStyle(.iconOnly)
                        }
                    }
                }
            }
        }
    }
}

struct ReminderEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    var record: CareReminder?
    @State private var value = CareReminder(date: Date.now.addingTimeInterval(3_600))
    @State private var error: String?
    @State private var loaded = false
    var body: some View {
        CareForm(title: "Recordatorio", onSave: save) {
            Section {
                TextField("Qué quieres recordar", text: $value.title)
                DatePicker("Fecha y hora", selection: $value.date)
                Picker("Área", selection: $value.relatedFeature) { ForEach(ObservationContext.allCases) { Text($0.title).tag($0) } }
                TextField("Notas opcionales", text: $value.notes, axis: .vertical).lineLimit(2...5)
                Toggle("Notificar", isOn: $value.notificationEnabled)
                if !store.snapshot.preferences.reminders.notificationsEnabled { Text("Puedes activar las notificaciones del dispositivo en Ajustes. El recordatorio estará disponible en la aplicación.").font(.caption).foregroundStyle(AppTheme.secondaryInk) }
            }
            if let error { Text(error).foregroundStyle(.red) }
        }.onAppear { guard !loaded else { return }; loaded = true; if let record { value = record } }
    }
    private func save() async -> Bool {
        value.title = value.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.title.isEmpty else { error = String(localized: "Escribe un título."); return false }
        return await store.update { $0.reminders.upsert(value) }
    }
}
