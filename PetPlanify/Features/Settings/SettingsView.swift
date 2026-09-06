import SwiftUI
import UserNotifications
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(AppNavigation.self) private var navigation
    @State private var profile = false
    @State private var food = false
    @State private var exporter = false
    @State private var importer = false
    @State private var backupDocument: PetPlanifyBackupDocument?
    @State private var pendingBackup: ValidatedBackup?
    @State private var confirmImport = false
    @State private var confirmReset = false
    @State private var busy = false
    var body: some View {
        Form {
            Section("Perfil") {
                HStack(spacing: 12) {
                    PetAvatarView(size: 52, photoURL: store.profilePhotoURL())
                    VStack(alignment: .leading) {
                        Text(store.snapshot.pet.name).font(.headline)
                        Text(store.snapshot.pet.ageDescription()).foregroundStyle(AppTheme.secondaryInk)
                    }
                }
                Button("Editar perfil") { profile = true }.accessibilityIdentifier("profile.edit")
            }
            Section("Alimentación") {
                Button("Editar plan de alimentación") { food = true }
            }
            Section("Salud") {
                Button("Ver registros de salud") { navigation.selection = .health }
                Button("Editar clínica, microchip y rango de peso") { profile = true }
            }
            Section("Preferencias") {
                Picker("Peso", selection: preference(\.weightUnit)) { ForEach(WeightUnit.allCases) { Text($0.title).tag($0) } }
                Picker("Distancia", selection: preference(\.distanceUnit)) { ForEach(DistanceUnit.allCases) { Text($0.title).tag($0) } }
                Picker("Apariencia", selection: preference(\.appearance)) { ForEach(AppAppearance.allCases) { Text($0.title).tag($0) } }
                LabeledContent("Idioma", value: "Español")
            }
            Section("Recordatorios") {
                Toggle("Notificaciones del dispositivo", isOn: Binding(get: { store.snapshot.preferences.reminders.notificationsEnabled }, set: { value in Task { await store.setNotificationsEnabled(value) } }))
                    .accessibilityIdentifier("notifications.enable")
                if store.notificationStatus == .denied {
                    Text("El permiso está desactivado en los ajustes del sistema. Los recordatorios de la aplicación siguen funcionando.").font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                }
                if store.snapshot.preferences.reminders.notificationsEnabled {
                    Toggle("Salud", isOn: reminderPreference(\.healthEnabled))
                    Toggle("Alimentación", isOn: reminderPreference(\.nutritionEnabled))
                    Toggle("Entrenamiento", isOn: reminderPreference(\.trainingEnabled))
                }
                Picker("Avisar", selection: reminderPreference(\.advanceTime)) { ForEach(ReminderAdvanceTime.allCases) { Text($0.title).tag($0) } }
                Text("Las categorías se aplican a los cuidados y recordatorios que tú añadas. No se crean pautas automáticamente.").font(.caption).foregroundStyle(AppTheme.secondaryInk)
            }
            Section("Datos y privacidad") {
                LabeledContent("Almacenamiento", value: "En este dispositivo")
                ICloudSettingsRow()
                Button("Exportar copia de seguridad", systemImage: "square.and.arrow.up") {
                    busy = true
                    Task {
                        do { backupDocument = try await store.exportBackup(); exporter = true }
                        catch { store.report(error) }
                        busy = false
                    }
                }.accessibilityIdentifier("data.export").disabled(busy)
                Button("Importar copia de seguridad", systemImage: "square.and.arrow.down") { importer = true }.accessibilityIdentifier("data.import").disabled(busy)
                Button("Restablecer PetPlanify", systemImage: "arrow.counterclockwise", role: .destructive) { confirmReset = true }.accessibilityIdentifier("data.reset").disabled(busy)
                if busy { ProgressView("Preparando los datos…") }
                Text("PetPlanify guarda la información localmente. No vende tus datos, no incluye publicidad ni servicios de analítica y no envía los registros de tu mascota a servidores externos. Si activas iCloud, se utiliza tu entorno de Apple.")
                    .font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
            }
            Section("Acerca de") {
                LabeledContent("PetPlanify", value: "\(version) (\(build))")
                LabeledContent("Plataformas", value: "iPhone + Mac")
                LabeledContent("Tecnología", value: "SwiftUI")
                Text("Un lugar tranquilo para organizar el cuidado y la historia de tu mascota.")
                Text("Diseñado y desarrollado por Ana Valladares.").foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .formStyle(.grouped).scrollContentBackground(.hidden).appCanvas()
        .accessibilityIdentifier("settings.screen")
        .sheet(isPresented: $profile) { ProfileEditor() }
        .sheet(isPresented: $food) { FoodPlanEditor() }
        .fileExporter(isPresented: $exporter, document: backupDocument, contentType: .petPlanifyBackup, defaultFilename: "PetPlanify Backup.petplanify") { result in
            switch result {
            case .success: store.message = String(localized: "La copia de seguridad se ha exportado.")
            case .failure: store.message = String(localized: "No se ha podido exportar la copia. Los datos de la aplicación siguen disponibles.")
            }
            backupDocument = nil
        }
        .fileImporter(isPresented: $importer, allowedContentTypes: [.petPlanifyBackup, .package]) { result in
            if case let .success(url) = result {
                busy = true
                Task {
                    do { pendingBackup = try await BackupArchive.read(from: url); confirmImport = true }
                    catch { store.report(error) }
                    busy = false
                }
            } else if case .failure = result { store.message = String(localized: "No se ha podido abrir la copia seleccionada.") }
        }
        .alert("¿Restaurar esta copia?", isPresented: $confirmImport) {
            Button("Cancelar", role: .cancel) { pendingBackup = nil }
            Button("Restaurar", role: .destructive) {
                guard let backup = pendingBackup else { return }
                busy = true
                Task { _ = await store.restoreBackup(backup); busy = false; pendingBackup = nil }
            }
        } message: {
            if let backup = pendingBackup {
                Text("Mascota: \(backup.snapshot.pet.name)\nCopia del \(AppFormat.dateTime(backup.createdAt))\n\(backup.attachmentCount) archivos\nSe sustituirán los datos actuales. Se conservará un respaldo de los datos anteriores.")
            }
        }
        .alert("¿Restablecer PetPlanify?", isPresented: $confirmReset) {
            Button("Cancelar", role: .cancel) { }
            Button("Restablecer", role: .destructive) { Task { _ = await store.reset() } }
        } message: { Text("Se eliminarán de la aplicación el perfil, los registros, las fotos, los documentos y los ajustes. Volverás a la bienvenida. Exporta una copia si quieres conservarlos.") }
        .task { await store.refreshNotificationStatus() }
    }
    private var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0" }
    private var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1" }
    private func preference<Value>(_ key: WritableKeyPath<AppPreferences, Value>) -> Binding<Value> {
        Binding(get: { store.snapshot.preferences[keyPath: key] }, set: { value in Task { _ = await store.update { $0.preferences[keyPath: key] = value } } })
    }
    private func reminderPreference<Value>(_ key: WritableKeyPath<ReminderPreferences, Value>) -> Binding<Value> {
        Binding(get: { store.snapshot.preferences.reminders[keyPath: key] }, set: { value in Task { _ = await store.update { $0.preferences.reminders[keyPath: key] = value } } })
    }
}

#Preview { NavigationStack { SettingsView() }.environment(PetPlanifyStore.preview()).environment(AppNavigation()) }
