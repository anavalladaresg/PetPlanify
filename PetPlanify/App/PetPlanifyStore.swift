import Foundation
import Observation
import UserNotifications

@MainActor @Observable
final class PetPlanifyStore {
    private(set) var snapshot: PetPlanifySnapshot
    private(set) var isLoaded = false
    private(set) var needsRecovery = false
    var message: String?
    var notificationStatus: UNAuthorizationStatus = .notDetermined
    private let storage: any SnapshotStorage
    let attachments: ManagedAttachmentStorage?
    private let notifications: LocalNotificationService?
    private var mutationInProgress = false
    private var mutationWaiters: [CheckedContinuation<Void, Never>] = []

    init(storage: any SnapshotStorage, attachments: ManagedAttachmentStorage? = nil, notifications: LocalNotificationService? = nil, initialSnapshot: PetPlanifySnapshot = PetPlanifySnapshot(), loaded: Bool = false) {
        self.storage = storage
        self.attachments = attachments
        self.notifications = notifications
        self.snapshot = initialSnapshot
        self.isLoaded = loaded
    }

    static func live() -> PetPlanifyStore {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--petplanify-validation-directory"), arguments.indices.contains(index + 1) {
            let directory = URL(fileURLWithPath: arguments[index + 1]).resolvingSymlinksInPath()
            let temporary = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().path + "/"
            if directory.path.hasPrefix(temporary) || directory.path.hasPrefix("/private/tmp/PetPlanify") {
                let isolated = LocalSnapshotStorage(directory: directory)
                return PetPlanifyStore(storage: isolated, attachments: ManagedAttachmentStorage(directory: directory))
            }
        }
        #endif
        let storage = LocalSnapshotStorage()
        return PetPlanifyStore(storage: storage, attachments: ManagedAttachmentStorage(directory: storage.directory), notifications: LocalNotificationService())
    }

    var currentWeight: Double? { snapshot.currentWeight }
    var upcomingCare: [CareReminder] { ReminderEngine.upcoming(snapshot.reminders) }
    var pendingReminderCount: Int { snapshot.reminders.filter { !$0.isCompleted }.count }

    func load() async {
        guard !isLoaded else { return }
        await lock()
        defer { unlock(); isLoaded = true }
        do {
            let result = try await storage.load()
            var value = result.snapshot ?? PetPlanifySnapshot()
            let previous = value
            ReminderEngine.reconcile(&value)
            if value != previous { try await storage.save(value) }
            snapshot = value
            message = result.recoveryNotice
            needsRecovery = false
            await synchronizeNotifications()
        } catch { needsRecovery = true; report(error) }
    }

    @discardableResult
    func update(_ mutation: (inout PetPlanifySnapshot) -> Void) async -> Bool {
        await lock()
        defer { unlock() }
        guard !needsRecovery else { return false }
        var value = snapshot
        mutation(&value)
        value.modifiedAt = .now
        ReminderEngine.reconcile(&value)
        if let error = value.validationError { message = error; return false }
        do {
            try await storage.save(value)
            snapshot = value
            await synchronizeNotifications()
            return true
        } catch { report(error); return false }
    }

    func saveProfile(_ profile: PetProfile, photoData: Data?, removePhoto: Bool, onboarding: Bool) async -> Bool {
        var value = profile
        var importedPath: String?
        do {
            if let photoData, let attachments {
                importedPath = try await attachments.storeProfileImage(photoData)
                value.photoPath = importedPath
            } else if removePhoto { value.photoPath = nil }
        } catch { report(error); return false }
        value.updatedAt = .now
        let saved = await update {
            let oldWeight = $0.currentWeight
            $0.pet = value
            if let weight = value.currentWeight, oldWeight != weight || $0.health.weights.isEmpty {
                $0.health.weights.append(WeightRecord(weight: weight))
            }
            if onboarding { $0.onboarding.isComplete = true }
        }
        if !saved, let importedPath { try? await attachments?.remove(relativePath: importedPath) }
        // Previous files are retained because the previous valid snapshot may still reference them.
        return saved
    }

    func profilePhotoURL() -> URL? { snapshot.pet.photoPath.flatMap { try? attachments?.url(for: $0) } }
    func documentURL(for document: DocumentAttachment) -> URL? { try? attachments?.url(for: document.relativeStoragePath) }

    func importDocument(from url: URL, visitID: UUID) async -> Bool {
        guard let attachments, snapshot.health.visits.contains(where: { $0.id == visitID }) else { return false }
        do {
            let imported = try await attachments.importDocument(from: url)
            let document = DocumentAttachment(displayName: imported.displayName, type: imported.type, relativeStoragePath: imported.relativeStoragePath, linkedVisitID: visitID)
            var linked = false
            let saved = await update {
                guard let index = $0.health.visits.firstIndex(where: { $0.id == visitID }) else { return }
                $0.health.documents.append(document)
                linked = true
                $0.health.visits[index].documentIDs.append(document.id)
            }
            if !saved || !linked { try? await attachments.remove(relativePath: imported.relativeStoragePath) }
            return saved && linked
        } catch { report(error); return false }
    }

    func deleteDocument(_ id: UUID) async -> Bool {
        await update {
            $0.health.documents.removeAll { $0.id == id }
            for index in $0.health.visits.indices { $0.health.visits[index].documentIDs.removeAll { $0 == id } }
        }
    }

    func setNotificationsEnabled(_ enabled: Bool) async {
        if enabled, let notifications {
            do {
                let granted = try await notifications.requestPermission()
                notificationStatus = await notifications.permissionStatus()
                guard granted else {
                    message = String(localized: "Las notificaciones están desactivadas en el sistema. Puedes activarlas en los ajustes del dispositivo; los recordatorios siguen disponibles aquí.")
                    return
                }
            } catch { report(error); return }
        }
        _ = await update { $0.preferences.reminders.notificationsEnabled = enabled }
    }

    func refreshNotificationStatus() async { if let notifications { notificationStatus = await notifications.permissionStatus() } }

    func exportBackup() async throws -> PetPlanifyBackupDocument {
        guard let local = storage as? LocalSnapshotStorage else { throw StorageError.invalidBackup }
        await lock(); defer { unlock() }
        return try await local.exportBackup(snapshot: snapshot)
    }

    func restoreBackup(_ backup: ValidatedBackup) async -> Bool {
        guard let local = storage as? LocalSnapshotStorage else { return false }
        await lock(); defer { unlock() }
        do {
            snapshot = try await local.restore(backup)
            needsRecovery = false
            message = String(localized: "La copia se ha restaurado. Los datos anteriores se han conservado como respaldo.")
            await synchronizeNotifications()
            return true
        } catch { report(error); return false }
    }

    func reset() async -> Bool {
        await lock(); defer { unlock() }
        do {
            try await storage.reset()
            snapshot = PetPlanifySnapshot()
            needsRecovery = false
            message = nil
            await synchronizeNotifications()
            return true
        } catch { report(error); return false }
    }

    func report(_ error: Error) {
        message = (error as? LocalizedError)?.errorDescription ?? String(localized: "No se ha podido completar la operación. Tus datos anteriores siguen disponibles.")
    }

    private func synchronizeNotifications() async {
        guard let notifications else { return }
        do {
            try await notifications.synchronize(reminders: snapshot.reminders, preferences: snapshot.preferences.reminders)
            notificationStatus = await notifications.permissionStatus()
        } catch { message = String(localized: "Los datos se han guardado, pero no se han podido actualizar las notificaciones. Los recordatorios siguen disponibles en la aplicación.") }
    }
    private func lock() async {
        if mutationInProgress { await withCheckedContinuation { mutationWaiters.append($0) } }
        else { mutationInProgress = true }
    }
    private func unlock() {
        if mutationWaiters.isEmpty { mutationInProgress = false }
        else { mutationWaiters.removeFirst().resume() }
    }
}
