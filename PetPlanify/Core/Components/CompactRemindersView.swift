import SwiftUI

struct AppReminderButton: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(AppNavigation.self) private var navigation
    @State private var presented = false
    var body: some View {
        Button("Próximos eventos", systemImage: store.pendingReminderCount > 0 ? "bell.badge" : "bell") { presented = true }
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
    var focusedReminderID: UUID? = nil
    @State private var adding = false
    @State private var editing: CareReminder?
    @State private var deleting: CareReminder?
    @State private var expandedNotes: Set<UUID> = []
    @State private var optimisticCompletion: [UUID: Bool] = [:]
    var body: some View {
        NavigationStack {
            List {
                if store.snapshot.reminders.filter({ $0.sourceKey != nil }).isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                        EmptyStateCard(
                            title: "Todavía no hay próximos eventos",
                            message: "Aquí aparecerán vacunas, desparasitaciones, medicación y visitas veterinarias.",
                            symbol: "calendar.badge.clock",
                            accent: AppTheme.reminder
                        )
                    }
                    .listRowBackground(Color.clear)
                }
                let derived = store.snapshot.reminders.filter { $0.sourceKey != nil }
                reminderSection("Fechas pasadas", values: derived.filter { !$0.isCompleted && $0.date <= .now })
                reminderSection("Eventos pendientes", values: derived.filter { !$0.isCompleted && $0.date > .now })
                reminderSection("Completados", values: derived.filter(\.isCompleted))
        }.scrollContentBackground(.hidden).appCanvas().navigationTitle("Próximos eventos")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
                }
        }
        #if os(macOS)
        .frame(minWidth: 440, idealWidth: 520, minHeight: 480)
        #endif
        .sheet(isPresented: $adding) { ReminderEditor() }
        .sheet(item: $editing) { ReminderEditor(record: $0) }
        .task(id: focusedReminderID) {
            guard let focusedReminderID,
                  let reminder = store.snapshot.reminders.first(where: { $0.id == focusedReminderID }) else { return }
            editing = reminder
        }
        .confirmationDialog("¿Eliminar este recordatorio?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("Eliminar", role: .destructive) {
                guard let id = deleting?.id else { return }
                Task { _ = await store.softDeleteReminder(id) }
            }
        }
    }
    @ViewBuilder private func reminderSection(_ title: LocalizedStringKey, values: [CareReminder]) -> some View {
        if !values.isEmpty {
            Section(title) {
                ForEach(values.sorted { $0.date < $1.date }) { reminder in
                    HStack(alignment: .top, spacing: 12) {
                        let completed = optimisticCompletion[reminder.id] ?? reminder.isCompleted
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                optimisticCompletion[reminder.id] = !completed
                            }
                            Task { _ = await store.update {
                                guard let index = $0.reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
                                $0.reminders[index].isCompleted.toggle()
                                $0.reminders[index].completedAt = $0.reminders[index].isCompleted ? .now : nil
                            } }
                        } label: { Image(systemName: completed ? "checkmark.circle.fill" : "circle").font(.title2).frame(minWidth: 44, minHeight: 44) }
                        .buttonStyle(.borderless).accessibilityLabel(completed ? "Reabrir cuidado" : "Completar cuidado")
                        VStack(alignment: .leading, spacing: 5) {
                                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                                    Image(systemName: reminderSymbol(reminder))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(reminderAccent(reminder))
                                        .frame(width: 32, height: 32)
                                        .background(reminderAccent(reminder).opacity(0.16), in: Circle())
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                                            Text(reminder.title)
                                                .font(.headline)
                                                .foregroundStyle(AppTheme.ink)
                                                .lineLimit(2)
                                                .truncationMode(.tail)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            Text(reminderRelativeDate(reminder.date))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(completed ? AppTheme.secondaryInk : reminderAccent(reminder))
                                                .lineLimit(1)
                                                .fixedSize(horizontal: true, vertical: false)
                                        }
                                    }
                                }
                                HStack(spacing: AppTheme.Space.sm) {
                                    Text(AppFormat.dateTime(reminder.date))
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryInk)
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                    StatusBadge(
                                        title: completed ? "Completado" : (reminder.date < .now ? "Pendiente" : "Próximamente"),
                                        symbol: completed ? "checkmark.circle.fill" : "clock.fill",
                                        tint: completed ? AppTheme.green : reminderAccent(reminder)
                                    )
                                }
                                if !reminder.notes.isEmpty {
                                    Text(reminder.notes)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryInk)
                                        .lineLimit(expandedNotes.contains(reminder.id) ? 6 : 2)
                                        .truncationMode(.tail)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    if reminder.notes.count > 96 {
                                        Button(expandedNotes.contains(reminder.id) ? "Ver menos" : "Ver más") {
                                            withAnimation(.easeInOut(duration: 0.18)) {
                                                if expandedNotes.contains(reminder.id) { expandedNotes.remove(reminder.id) }
                                                else { expandedNotes.insert(reminder.id) }
                                            }
                                        }
                                        .font(.caption.weight(.semibold))
                                        .buttonStyle(.plain)
                                        .foregroundStyle(reminderAccent(reminder))
                                    }
                                }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            navigation.selection = AppSection(context: reminder.relatedFeature)
                            dismiss()
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction {
                            navigation.selection = AppSection(context: reminder.relatedFeature)
                            dismiss()
                        }
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

    private func reminderSymbol(_ context: ObservationContext) -> String {
        switch context {
        case .nutrition: return "fork.knife"
        case .health: return "heart.text.square.fill"
        case .training: return "pawprint.fill"
        case .general: return "bell.fill"
        }
    }

    private func reminderSymbol(_ reminder: CareReminder) -> String {
        guard let key = reminder.sourceKey else { return reminderSymbol(reminder.relatedFeature) }
        if key.hasPrefix("vaccine.") { return "syringe.fill" }
        if key.hasPrefix("deworming.") { return "pills.fill" }
        if key.hasPrefix("medication.") { return "cross.case.fill" }
        if key.hasPrefix("visit.") || key.hasPrefix("followup.") { return "stethoscope" }
        return reminderSymbol(reminder.relatedFeature)
    }

    private func reminderAccent(_ context: ObservationContext) -> Color {
        switch context {
        case .nutrition: return AppTheme.orange
        case .health: return AppTheme.health
        case .training: return AppTheme.training
        case .general: return AppTheme.reminder
        }
    }

    private func reminderAccent(_ reminder: CareReminder) -> Color {
        guard let key = reminder.sourceKey else { return reminderAccent(reminder.relatedFeature) }
        if key.hasPrefix("vaccine.") { return AppTheme.vaccine }
        if key.hasPrefix("deworming.") { return AppTheme.deworming }
        if key.hasPrefix("medication.") { return AppTheme.training }
        if key.hasPrefix("visit.") || key.hasPrefix("followup.") { return AppTheme.health }
        return reminderAccent(reminder.relatedFeature)
    }

    private func reminderRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return String(localized: "Hoy") }
        if calendar.isDateInTomorrow(date) { return String(localized: "Mañana") }
        if date < .now { return String(localized: "Pendiente") }
        return date.formatted(.relative(presentation: .named))
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
        let saved = await store.update { $0.reminders.upsert(value) }
        if !saved { error = store.message ?? String(localized: "No se ha podido guardar el recordatorio.") }
        return saved
    }
}
