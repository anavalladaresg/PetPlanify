import SwiftUI

struct ICloudSettingsRow: View {
    @Environment(PetPlanifyStore.self) private var store
    @State private var provider = ICloudSnapshotProvider()
    @State private var available = false
    @State private var busy = false
    @State private var status = String(localized: "No configurado")
    @State private var remote: ValidatedBackup?
    @State private var resolveConflict = false
    var body: some View {
        LabeledContent("iCloud", value: status)
        if available {
            Toggle("Usar iCloud", isOn: Binding(get: { store.snapshot.preferences.iCloudEnabled }, set: { value in Task { _ = await store.update { $0.preferences.iCloudEnabled = value } } }))
            if store.snapshot.preferences.iCloudEnabled {
                Button("Sincronizar ahora") { Task { await synchronize() } }.disabled(busy)
                Text("Comparte una copia entre tus dispositivos. Si las copias son distintas, podrás elegir cuál conservar.").font(.caption).foregroundStyle(AppTheme.secondaryInk)
            }
        } else {
            Text("La aplicación funciona completamente con los datos de este dispositivo.").font(.caption).foregroundStyle(AppTheme.secondaryInk)
        }
        if busy { ProgressView() }
        Group { EmptyView() }
            .task {
                guard store.externalServicesEnabled else { return }
                available = await provider.isAvailable()
                status = available ? String(localized: "Disponible") : String(localized: "No configurado")
            }
            .alert("Hay una copia distinta en iCloud", isPresented: $resolveConflict) {
                Button("Cancelar", role: .cancel) { remote = nil; status = String(localized: "Disponible") }
                Button("Usar la copia de iCloud", role: .destructive) {
                    guard let remote else { return }
                    Task {
                        busy = true
                        let success = await store.restoreBackup(remote)
                        status = success ? String(localized: "Sincronizado") : String(localized: "Error")
                        busy = false
                    }
                }
                Button("Conservar este dispositivo") { Task { await uploadLocal() } }
            } message: {
                if let remote {
                    Text("iCloud: \(remote.snapshot.pet.name), \(AppFormat.dateTime(remote.snapshot.modifiedAt)).\nEste dispositivo: \(store.snapshot.pet.name), \(AppFormat.dateTime(store.snapshot.modifiedAt)).\nSe conservará un respaldo de la copia que sustituyas.")
                }
            }
    }
    private func synchronize() async {
        busy = true; status = String(localized: "Sincronizando")
        do {
            if let remote = try await provider.fetch() {
                let local = try await store.exportBackup().validatedBackup
                if local.manifest.snapshotSHA256 != remote.manifest.snapshotSHA256 {
                    self.remote = remote; resolveConflict = true; busy = false; return
                }
                status = String(localized: "Sincronizado")
            } else {
                let archive = try await store.exportBackup().validatedBackup
                let uploaded = try await provider.upload(archive)
                status = uploaded ? String(localized: "Sincronizado") : String(localized: "Sincronizando")
            }
        } catch { store.report(error); status = String(localized: "Error") }
        busy = false
    }
    private func uploadLocal() async {
        busy = true; status = String(localized: "Sincronizando")
        do {
            let archive = try await store.exportBackup().validatedBackup
            let uploaded = try await provider.upload(archive)
            status = uploaded ? String(localized: "Sincronizado") : String(localized: "Sincronizando")
        } catch { store.report(error); status = String(localized: "Error") }
        busy = false; remote = nil
    }
}
