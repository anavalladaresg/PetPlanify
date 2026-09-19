import SwiftUI
import UserNotifications
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var profile = false
    @State private var profiles = false
    @State private var confirmsSignOut = false
    @State private var confirmsCalendarUnlink = false
    @AppStorage("petplanify.apple.signedIn") private var signedIn = true
    var body: some View {
        CarePage {
            VStack(alignment: .leading, spacing: settingsSectionSpacing) {
                PetProfileHeroCard(
                    name: store.snapshot.pet.name,
                    subtitle: profileSubtitle,
                    photoURL: store.profilePhotoURL()
                ) { profile = true } manageAction: { profiles = true }
                    .accessibilityIdentifier("profile.edit")

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: AppTheme.Space.lg) {
                        preferencesCard
                        appearanceCard
                    }
                    VStack(spacing: settingsCardSpacing) {
                        preferencesCard
                        appearanceCard
                    }
                }

                remindersCard

                calendarCard

                SettingsSectionCard(title: "Sesión", symbol: "rectangle.portrait.and.arrow.right", accent: AppTheme.health) {
                    Text("Cerrar sesión volverá a la bienvenida. Tus mascotas y cuidados seguirán guardados en tu cuenta.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        confirmsSignOut = true
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("settings.signOut")
                }

                HStack(spacing: AppTheme.Space.sm) {
                    Image(systemName: "pawprint.fill").foregroundStyle(AppTheme.green)
                    Text("PetPlanify · versión \(version)")
                        .font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.secondaryInk)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .accessibilityIdentifier("settings.screen")
        .sheet(isPresented: $profile) { ProfileEditor() }
        .sheet(isPresented: $profiles) { PetProfilesView() }
        .confirmationDialog("¿Cerrar sesión en este dispositivo?", isPresented: $confirmsSignOut, titleVisibility: .visible) {
            Button("Cerrar sesión", role: .destructive) {
                Task { if await store.signOut() { signedIn = false } }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Tus mascotas y cuidados no se borrarán. Podrás recuperarlos al volver a iniciar sesión.")
        }
        .confirmationDialog("¿Qué hacemos con los eventos de PetPlanify?", isPresented: $confirmsCalendarUnlink, titleVisibility: .visible) {
            Button("Mantenerlos en Calendario") {
                Task { await store.setAppleCalendarLinked(false) }
            }
            Button("Eliminar eventos", role: .destructive) {
                Task {
                    do {
                        try await AppleCalendarExportService.shared.deletePetPlanifyEvents()
                        await store.setAppleCalendarLinked(false)
                    } catch { store.message = error.localizedDescription }
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Puedes mantener los eventos en Calendario de Apple o eliminar solamente los que creó PetPlanify.")
        }
        .task {
            await store.refreshNotificationStatus()
        }
    }
    private var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0" }
    private var settingsSectionSpacing: CGFloat {
        horizontalSizeClass == .compact ? AppTheme.Space.md : AppTheme.Space.xl
    }
    private var settingsCardSpacing: CGFloat {
        horizontalSizeClass == .compact ? AppTheme.Space.md : AppTheme.Space.lg
    }
    private var profileSubtitle: String {
        [store.snapshot.pet.ageDescription(), store.snapshot.pet.breed]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
    private func preference<Value>(_ key: WritableKeyPath<AppPreferences, Value>) -> Binding<Value> {
        Binding(get: { store.snapshot.preferences[keyPath: key] }, set: { value in Task { _ = await store.update { $0.preferences[keyPath: key] = value } } })
    }
    private func reminderPreference<Value>(_ key: WritableKeyPath<ReminderPreferences, Value>) -> Binding<Value> {
        Binding(get: { store.snapshot.preferences.reminders[keyPath: key] }, set: { value in Task { _ = await store.update { $0.preferences.reminders[keyPath: key] = value } } })
    }

    private var preferencesCard: some View {
        SettingsSectionCard(title: "Preferencias", symbol: "slider.horizontal.3", accent: AppTheme.green) {
            SettingRow(title: "Unidad de peso", symbol: "scalemass") { Picker("Peso", selection: preference(\.weightUnit)) { ForEach(WeightUnit.allCases) { Text($0.title).tag($0) } }.labelsHidden() }
            Divider().opacity(0.35)
            SettingRow(title: "Unidad de distancia", symbol: "location") { Picker("Distancia", selection: preference(\.distanceUnit)) { ForEach(DistanceUnit.allCases) { Text($0.title).tag($0) } }.labelsHidden() }
        }
    }

    private var appearanceCard: some View {
        SettingsSectionCard(title: "Apariencia", symbol: "circle.lefthalf.filled", accent: AppTheme.training) {
            SettingRow(title: "Tema", detail: "Claro, oscuro o según el sistema", symbol: "paintpalette", accent: AppTheme.training) { Picker("Tema", selection: preference(\.appearance)) { ForEach(AppAppearance.allCases) { Text($0.title).tag($0) } }.labelsHidden() }
        }
    }

    private var remindersCard: some View {
        SettingsSectionCard(title: "Recordatorios", symbol: "bell.fill", accent: AppTheme.reminder) {
            SettingRow(
                title: "Notificaciones del dispositivo",
                detail: store.notificationStatus == .denied ? "Actívalas en Ajustes del sistema > PetPlanify > Notificaciones" : "Notificaciones de PetPlanify para próximos cuidados",
                symbol: "bell.fill",
                accent: AppTheme.reminder
            ) {
                Toggle("Notificaciones del dispositivo", isOn: Binding(
                    get: { store.snapshot.preferences.reminders.notificationsEnabled },
                    set: { value in Task { await store.setNotificationsEnabled(value) } }
                ))
                .labelsHidden()
                .accessibilityIdentifier("notifications.enable")
                .accessibilityLabel("Notificaciones del dispositivo")
            }
            if store.notificationStatus == .denied {
                HStack {
                    StatusBadge(title: "Permiso pendiente", symbol: "info.circle.fill", tint: AppTheme.reminder)
                    Spacer()
                    Button("Abrir Ajustes", systemImage: "gear") { openNotificationSettings() }
                        .buttonStyle(.bordered)
                }
            }
            if store.snapshot.preferences.reminders.notificationsEnabled {
                Toggle("Salud", isOn: reminderPreference(\.healthEnabled))
                Toggle("Alimentación", isOn: reminderPreference(\.nutritionEnabled))
                Toggle("Entrenamiento", isOn: reminderPreference(\.trainingEnabled))
            }
            SettingRow(title: "Anticipación", symbol: "clock") { Picker("Avisar", selection: reminderPreference(\.advanceTime)) { ForEach(ReminderAdvanceTime.allCases) { Text($0.title).tag($0) } }.labelsHidden() }
        }
    }

    private var calendarCard: some View {
        SettingsSectionCard(title: "Calendario", symbol: "calendar", accent: AppTheme.blue) {
            SettingRow(
                title: "Vincular con Calendario de Apple",
                detail: "Añade y mantiene tus cuidados en el calendario del dispositivo",
                symbol: "calendar.badge.plus",
                accent: AppTheme.blue
            ) {
                Toggle("Vincular con Calendario de Apple", isOn: Binding(
                    get: { store.snapshot.preferences.appleCalendarLinked },
                    set: { value in
                        if value {
                            Task { await store.setAppleCalendarLinked(true); await syncExistingCalendarEvents() }
                        } else {
                            confirmsCalendarUnlink = true
                        }
                    }
                ))
                    .labelsHidden()
                    .accessibilityIdentifier("settings.appleCalendar")
            }
            Text("Al activarlo, los eventos de salud y cuidados se vincularán automáticamente. PetPlanify seguirá siendo la fuente principal de tus registros.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
            if store.snapshot.preferences.appleCalendarLinked {
                Text("Los avisos se enviarán desde PetPlanify. El calendario de Apple solo conservará los eventos.")
                    .font(.caption).foregroundStyle(AppTheme.secondaryInk)
            }
        }
    }

    private func openNotificationSettings() {
        #if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #elseif os(macOS)
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
        #endif
    }

    private func syncExistingCalendarEvents() async {
        let health = store.snapshot.health
        var items: [AppleCalendarExportService.CalendarItem] = []
        items += health.vaccines.map {
            AppleCalendarExportService.CalendarItem(title: "Vacuna: \($0.name)", date: $0.dateAdministered, endDate: nil, notes: $0.notes)
        }
        items += health.vaccines.compactMap {
            guard let date = $0.nextDueDate else { return nil }
            return AppleCalendarExportService.CalendarItem(title: "Próxima vacuna: \($0.name)", date: date, endDate: nil, notes: $0.notes)
        }
        items += health.dewormings.map {
            AppleCalendarExportService.CalendarItem(title: "Desparasitación: \($0.kind.title)", date: $0.applicationDate, endDate: nil, notes: $0.productName)
        }
        items += health.dewormings.compactMap {
            guard let date = $0.nextDueDate else { return nil }
            return AppleCalendarExportService.CalendarItem(title: "Próxima desparasitación: \($0.kind.title)", date: date, endDate: nil, notes: $0.productName)
        }
        items += health.medications.map {
            AppleCalendarExportService.CalendarItem(title: "Medicación: \($0.name)", date: $0.startDate, endDate: $0.endDate, notes: $0.notes)
        }
        items += health.visits.map {
            AppleCalendarExportService.CalendarItem(title: "Visita veterinaria: \($0.reason)", date: $0.date, endDate: $0.followUpDate, notes: [$0.clinic, $0.notes, $0.treatmentNotes].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n"))
        }
        items += store.snapshot.reminders.filter { !$0.isCompleted }.map {
            AppleCalendarExportService.CalendarItem(title: $0.title, date: $0.date, endDate: nil, notes: $0.notes)
        }
        guard !items.isEmpty else { return }
        do {
            let name = store.snapshot.pet.name.trimmingCharacters(in: .whitespacesAndNewlines)
            try await AppleCalendarExportService.shared.exportAll(
                items,
                petName: name.isEmpty ? String(localized: "Tu mascota") : name,
                alertAdvance: store.snapshot.preferences.appleCalendarAlertAdvance
            )
        } catch {
            store.message = error.localizedDescription
        }
    }
}

private struct SettingsSectionCard<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let title: LocalizedStringKey
    let symbol: String
    let accent: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: horizontalSizeClass == .compact ? AppTheme.Space.sm : AppTheme.Space.lg) {
            HStack(spacing: AppTheme.Space.md) {
                AccentIcon(systemName: symbol, accent: accent, size: 34)
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
            }
            content
        }
        .padding(horizontalSizeClass == .compact ? AppTheme.Space.md : AppTheme.Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(elevated: false)
    }
}

#Preview { NavigationStack { SettingsView() }.environment(PetPlanifyStore.preview()).environment(AppNavigation()) }
