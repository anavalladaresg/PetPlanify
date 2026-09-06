import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(PetPlanifyStore.self) private var store
    var body: some View {
        Group {
            if !store.isLoaded { ProgressView("Abriendo PetPlanify…").frame(maxWidth: .infinity, maxHeight: .infinity).appCanvas() }
            else if store.needsRecovery { RecoveryView() }
            else if !store.snapshot.onboarding.isComplete { OnboardingView() }
            else {
                #if os(macOS)
                MacAppShell()
                #else
                MobileAppShell()
                #endif
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let message = store.message {
                HStack(alignment: .top) {
                    Text(message).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 10)
                    Button("Cerrar aviso", systemImage: "xmark") { store.message = nil }.labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                }.padding(.horizontal, 16).padding(.vertical, 8).background(AppTheme.surfaceMuted)
                    .foregroundStyle(AppTheme.ink).accessibilityElement(children: .contain)
            }
        }
        .preferredColorScheme(store.snapshot.preferences.appearance == .system ? nil : store.snapshot.preferences.appearance == .dark ? .dark : .light)
        .task { await store.load() }
    }
}

private struct RecoveryView: View {
    @Environment(PetPlanifyStore.self) private var store
    @State private var importer = false
    @State private var backup: ValidatedBackup?
    @State private var confirmation = false
    @State private var resetConfirmation = false
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "externaldrive.badge.exclamationmark").font(.largeTitle).foregroundStyle(AppTheme.orange)
            Text("Tus archivos se han conservado").font(.title2).fontDesign(.serif)
            Text("Puedes cerrar la aplicación y volver a intentarlo, importar una copia válida o restablecer PetPlanify.").multilineTextAlignment(.center)
            Button("Importar copia de seguridad") { importer = true }.buttonStyle(.borderedProminent)
            Button("Restablecer PetPlanify", role: .destructive) { resetConfirmation = true }
        }.padding(30).frame(maxWidth: .infinity, maxHeight: .infinity).appCanvas()
        .fileImporter(isPresented: $importer, allowedContentTypes: [.petPlanifyBackup, .package]) { result in
            if case let .success(url) = result {
                Task { do { backup = try await BackupArchive.read(from: url); confirmation = true } catch { store.report(error) } }
            }
        }
        .alert("¿Restaurar la copia de \(backup?.snapshot.pet.name ?? "")?", isPresented: $confirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Restaurar", role: .destructive) { if let backup { Task { _ = await store.restoreBackup(backup) } } }
        } message: { Text("Se sustituirán los datos actuales y se conservarán los archivos anteriores como respaldo.") }
        .alert("¿Restablecer PetPlanify?", isPresented: $resetConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Restablecer", role: .destructive) { Task { _ = await store.reset() } }
        } message: { Text("Se retirarán los datos de la aplicación y volverás a la bienvenida.") }
    }
}

#Preview { ContentView().environment(PetPlanifyStore.preview()).environment(AppNavigation()) }
