import Foundation
import Observation
import UserNotifications

@MainActor @Observable
final class PetPlanifyStore {
    private(set) var snapshot: PetPlanifySnapshot
    private(set) var isLoaded = false
    private(set) var cloudKitUnavailable = false
    var message: String?
    var notificationStatus: UNAuthorizationStatus = .notDetermined
    private let storage: any PetPlanifyPersistence
    let attachments: ManagedAttachmentStorage?
    private let notifications: (any ReminderSchedulingService)?
    private let familySharing: any FamilySharingService
    private let syncStatusProvider: any SyncStatusProvider
    private(set) var syncStatus = PetPlanifySyncStatus(mode: .cloudKit, title: "iCloud", detail: "", lastSuccessfulSync: nil)
    private var mutationInProgress = false
    private var mutationWaiters: [CheckedContinuation<Void, Never>] = []

    init(
        storage: any PetPlanifyPersistence,
        attachments: ManagedAttachmentStorage? = nil,
        notifications: (any ReminderSchedulingService)? = nil,
        familySharing: any FamilySharingService = CloudKitFamilySharingService(),
        syncStatusProvider: any SyncStatusProvider = CloudKitSyncStatusProvider(),
        initialSnapshot: PetPlanifySnapshot = PetPlanifySnapshot(),
        loaded: Bool = false
    ) {
        self.storage = storage
        self.attachments = attachments
        self.notifications = notifications
        self.familySharing = familySharing
        self.syncStatusProvider = syncStatusProvider
        self.snapshot = initialSnapshot
        self.isLoaded = loaded
    }

    static func live() -> PetPlanifyStore {
        let storage = CloudKitPersistenceService()
        return PetPlanifyStore(storage: storage, attachments: ManagedAttachmentStorage(), notifications: LocalReminderSchedulingService(), familySharing: CloudKitFamilySharingService(), syncStatusProvider: CloudKitSyncStatusProvider())
    }

    var externalServicesEnabled: Bool { notifications != nil }
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
            value.pet.species = "Perro"
            for index in value.pets.indices { value.pets[index].pet.species = "Perro" }
            value.migratePetWorkspaces()
            let previous = value
            ReminderEngine.reconcile(&value)
            value.syncActiveWorkspace()
            if value != previous { try await storage.save(value) }
            snapshot = value
            syncStatus = await syncStatusProvider.currentStatus()
            message = result.recoveryNotice
            cloudKitUnavailable = false
            await synchronizeNotifications()
        } catch {
            // Never offer reset/import for a CloudKit connectivity or account
            // problem. The remote record remains untouched and can be retried.
            cloudKitUnavailable = true
            message = nil
        }
    }

    func retryCloudKitLoad() async {
        guard cloudKitUnavailable else { return }
        cloudKitUnavailable = false
        isLoaded = false
        await load()
    }

    @discardableResult
    func update(_ mutation: (inout PetPlanifySnapshot) -> Void) async -> Bool {
        await lock()
        defer { unlock() }
        return await commitMutation(mutation)
    }

    private func commitMutation(_ mutation: (inout PetPlanifySnapshot) -> Void) async -> Bool {
        var value = snapshot
        mutation(&value)
        value.modifiedAt = .now
        ReminderEngine.reconcile(&value)
        value.syncActiveWorkspace()
        if let error = value.validationError { message = error; return false }
        do {
            try await storage.save(value)
            snapshot = value
            await synchronizeNotifications()
            return true
        } catch { report(error); return false }
    }

    func saveProfile(_ profile: PetProfile, photoData: Data?, removePhoto: Bool, onboarding: Bool) async -> Bool {
        await lock()
        defer { unlock() }
        var value = profile
        value.species = "Perro"
        var importedPath: String?
        do {
            if let photoData, let attachments {
                importedPath = try await attachments.storeProfileImage(photoData)
                value.photoPath = importedPath
            } else if removePhoto { value.photoPath = nil }
        } catch { report(error); return false }
        value.updatedAt = .now
        let saved = await commitMutation {
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
        await lock()
        defer { unlock() }
        guard let attachments, snapshot.health.visits.contains(where: { $0.id == visitID }) else { return false }
        do {
            let imported = try await attachments.importDocument(from: url)
            let document = DocumentAttachment(displayName: imported.displayName, type: imported.type, relativeStoragePath: imported.relativeStoragePath, linkedVisitID: visitID)
            var linked = false
            let saved = await commitMutation {
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

    var deletedRecordsForActivePet: [DeletedCareRecord] {
        snapshot.trash.filter { $0.petID == snapshot.pet.id }.sorted { $0.deletedAt > $1.deletedAt }
    }

    func softDeleteWeight(_ id: UUID) async -> Bool {
        await softDelete(kind: .weight, id: id, title: String(localized: "Registro de peso")) { (value: inout PetPlanifySnapshot) -> WeightRecord? in
            guard let record = value.health.weights.first(where: { $0.id == id }) else { return nil }
            value.health.weights.removeAll { $0.id == id }
            value.pet.currentWeight = value.health.weights.max { $0.date < $1.date }?.weight
            value.pet.updatedAt = .now
            return record
        }
    }

    func softDeleteVaccine(_ id: UUID) async -> Bool {
        let title = snapshot.health.vaccines.first(where: { $0.id == id })?.name ?? String(localized: "Vacuna")
        return await softDelete(kind: .vaccine, id: id, title: title) { (value: inout PetPlanifySnapshot) -> VaccinationRecord? in
            guard let record = value.health.vaccines.first(where: { $0.id == id }) else { return nil }
            value.health.vaccines.removeAll { $0.id == id }
            return record
        }
    }

    func softDeleteDeworming(_ id: UUID) async -> Bool {
        let title = snapshot.health.dewormings.first(where: { $0.id == id })?.kind.title ?? String(localized: "Desparasitación")
        return await softDelete(kind: .deworming, id: id, title: title) { (value: inout PetPlanifySnapshot) -> DewormingRecord? in
            guard let record = value.health.dewormings.first(where: { $0.id == id }) else { return nil }
            value.health.dewormings.removeAll { $0.id == id }
            return record
        }
    }

    func softDeleteMedication(_ id: UUID) async -> Bool {
        let title = snapshot.health.medications.first(where: { $0.id == id })?.name ?? String(localized: "Medicación")
        return await softDelete(kind: .medication, id: id, title: title) { (value: inout PetPlanifySnapshot) -> MedicationRecord? in
            guard let record = value.health.medications.first(where: { $0.id == id }) else { return nil }
            value.health.medications.removeAll { $0.id == id }
            return record
        }
    }

    func softDeleteVisit(_ id: UUID) async -> Bool {
        let title = snapshot.health.visits.first(where: { $0.id == id })?.reason ?? String(localized: "Visita veterinaria")
        return await softDelete(kind: .visit, id: id, title: title) { (value: inout PetPlanifySnapshot) -> VeterinaryVisit? in
            guard let record = value.health.visits.first(where: { $0.id == id }) else { return nil }
            value.health.visits.removeAll { $0.id == id }
            return record
        }
    }

    func softDeleteObservation(_ record: PetObservation) async -> Bool {
        let kind: DeletedCareRecordKind
        switch record.context {
        case .nutrition: kind = .nutritionObservation
        default: kind = .healthObservation
        }
        return await softDelete(kind: kind, id: record.id, title: record.title.isEmpty ? kind.title : record.title) { (value: inout PetPlanifySnapshot) -> PetObservation? in
            switch record.context {
            case .nutrition:
                guard let found = value.nutrition.observations.first(where: { $0.id == record.id }) else { return nil }
                value.nutrition.observations.removeAll { $0.id == record.id }
                return found
            default:
                guard let found = value.health.observations.first(where: { $0.id == record.id }) else { return nil }
                value.health.observations.removeAll { $0.id == record.id }
                return found
            }
        }
    }

    func softDeleteTrainingObservation(_ id: UUID) async -> Bool {
        let title = snapshot.training.observations.first(where: { $0.id == id })?.title ?? String(localized: "Observación")
        return await softDelete(kind: .trainingObservation, id: id, title: title) { (value: inout PetPlanifySnapshot) -> BehaviorObservation? in
            guard let record = value.training.observations.first(where: { $0.id == id }) else { return nil }
            value.training.observations.removeAll { $0.id == id }
            return record
        }
    }

    func softDeleteReminder(_ id: UUID) async -> Bool {
        guard let reminder = snapshot.reminders.first(where: { $0.id == id }) else { return false }
        return await softDelete(kind: .reminder, id: id, title: reminder.title, sourceKey: reminder.sourceKey) { (value: inout PetPlanifySnapshot) -> CareReminder? in
            guard let record = value.reminders.first(where: { $0.id == id }) else { return nil }
            value.reminders.removeAll { $0.id == id }
            return record
        }
    }

    func restoreDeletedRecord(_ id: UUID) async -> Bool {
        await update { value in
            guard let index = value.trash.firstIndex(where: { $0.id == id }) else { return }
            let item = value.trash[index]
            guard var workspace = value.workspace(for: item.petID), (try? item.restore(into: &workspace)) != nil else { return }
            value.replaceWorkspace(workspace)
            value.trash.remove(at: index)
        }
    }

    func permanentlyDeleteRecord(_ id: UUID) async -> Bool {
        await update { $0.trash.removeAll { $0.id == id } }
    }

    private func softDelete<Record: Encodable>(
        kind: DeletedCareRecordKind,
        id: UUID,
        title: String,
        sourceKey: String? = nil,
        remove: (inout PetPlanifySnapshot) -> Record?
    ) async -> Bool {
        var archived = false
        let saved = await update { value in
            var candidate = value
            guard let record = remove(&candidate),
                  let deleted = try? DeletedCareRecord(record: record, originalID: id, petID: value.pet.id, kind: kind, title: title, sourceKey: sourceKey) else { return }
            candidate.trash.append(deleted)
            value = candidate
            archived = true
        }
        return saved && archived
    }

    func setNotificationsEnabled(_ enabled: Bool) async {
        let previous = snapshot.preferences.reminders.notificationsEnabled
        snapshot.preferences.reminders.notificationsEnabled = enabled
        if enabled, let notifications {
            do {
                let granted = try await notifications.requestPermission()
                notificationStatus = await notifications.permissionStatus()
                guard granted else {
                    snapshot.preferences.reminders.notificationsEnabled = previous
                    message = String(localized: "Las notificaciones están desactivadas en el sistema. Puedes activarlas en los ajustes del dispositivo; los recordatorios siguen disponibles aquí.")
                    return
                }
            } catch { snapshot.preferences.reminders.notificationsEnabled = previous; report(error); return }
        }
        _ = await update { $0.preferences.reminders.notificationsEnabled = enabled }
    }

    func scheduleTestNotifications() async -> Bool {
        guard let notifications else { return false }
        do { try await notifications.scheduleTestNotifications(petName: snapshot.pet.name); return true } catch { return false }
    }

    func cancelTestNotifications() async { await notifications?.cancelTestNotifications() }

    func refreshNotificationStatus() async { if let notifications { notificationStatus = await notifications.permissionStatus() } }

    func setAppleCalendarLinked(_ enabled: Bool) async {
        snapshot.preferences.appleCalendarLinked = enabled
        _ = await update { $0.preferences.appleCalendarLinked = enabled }
    }

    func reset() async -> Bool {
        await lock(); defer { unlock() }
        do {
            try await storage.reset()
            snapshot = PetPlanifySnapshot()
            message = nil
            await synchronizeNotifications()
            return true
        } catch { report(error); return false }
    }

    func signOut() async -> Bool {
        await lock(); defer { unlock() }
        do {
            try await storage.clearSession()
            // Sign out only clears the in-memory session. CloudKit records remain
            // attached to the Apple Account and are loaded again after sign-in.
            snapshot = PetPlanifySnapshot()
            isLoaded = false
            message = nil
            return true
        } catch { report(error); return false }
    }

    func report(_ error: Error) {
        message = (error as? LocalizedError)?.errorDescription ?? String(localized: "No se ha podido completar la operación. Tus datos anteriores siguen disponibles.")
    }

    var availablePets: [PetProfile] { snapshot.pets.map(\.pet).sorted { $0.createdAt < $1.createdAt } }

    func selectPet(_ id: UUID) async -> Bool {
        await lock()
        defer { unlock() }
        var value = snapshot
        value.syncActiveWorkspace()
        guard let target = value.pets.first(where: { $0.pet.id == id }), target.pet.id != value.pet.id else { return true }
        value.loadWorkspace(target)
        ReminderEngine.reconcile(&value)
        value.modifiedAt = .now
        do {
            try await storage.save(value)
            snapshot = value
            await synchronizeNotifications()
            return true
        } catch { report(error); return false }
    }

    func addPet(_ profile: PetProfile) async -> Bool {
        await lock()
        defer { unlock() }
        var value = snapshot
        var profile = profile
        profile.species = "Perro"
        value.syncActiveWorkspace()
        let workspace = PetWorkspace(pet: profile, nutrition: NutritionData(), health: HealthData(), training: TrainingData(), reminders: [], onboarding: OnboardingState(isComplete: true), modifiedAt: .now)
        value.pets.append(workspace)
        value.loadWorkspace(workspace)
        value.modifiedAt = .now
        do { try await storage.save(value); snapshot = value; await synchronizeNotifications(); return true }
        catch { report(error); return false }
    }

    func removePet(_ id: UUID) async -> Bool {
        await lock()
        defer { unlock() }
        var value = snapshot
        value.syncActiveWorkspace()
        guard value.pets.count > 1, value.pets.contains(where: { $0.pet.id == id }) else { return false }
        let removingActive = value.pet.id == id
        value.pets.removeAll { $0.pet.id == id }
        if removingActive, let replacement = value.pets.first { value.loadWorkspace(replacement) }
        value.modifiedAt = .now
        do { try await storage.save(value); snapshot = value; await synchronizeNotifications(); return true }
        catch { report(error); return false }
    }

    func addFamilyMember(name: String, role: FamilyMemberRole) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return await update { snapshot in
            snapshot.familyMembers.append(FamilyMember(name: trimmed, role: role))
            if snapshot.currentFamilyMemberID == nil { snapshot.currentFamilyMemberID = snapshot.familyMembers.last?.id }
        }
    }

    func removeFamilyMember(_ id: UUID) async -> Bool {
        await update {
            $0.familyMembers.removeAll { $0.id == id }
            if $0.currentFamilyMemberID == id { $0.currentFamilyMemberID = $0.familyMembers.first?.id }
        }
    }

    func createFamilyInvitation() async -> Bool {
        do {
            let invitation = try await familySharing.makeInvitation(snapshot: snapshot, validFor: 7 * 86_400)
            return await update { snapshot in
                for index in snapshot.familyInvitations.indices where snapshot.familyInvitations[index].effectiveStatus == .active {
                    snapshot.familyInvitations[index].status = .revoked
                }
                snapshot.familyInvitations.append(invitation)
            }
        } catch { report(error); return false }
    }

    func revokeFamilyInvitation(_ id: UUID) async -> Bool {
        await update { snapshot in
            guard let index = snapshot.familyInvitations.firstIndex(where: { $0.id == id }) else { return }
            snapshot.familyInvitations[index].status = .revoked
        }
    }

    func joinFamily(with code: String) async -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        do {
            _ = try await familySharing.validateInvitation(code: trimmed.uppercased())
            return true
        } catch { report(error); return false }
    }

    func refreshSyncStatus() async {
        syncStatus = await syncStatusProvider.currentStatus()
    }

    private func synchronizeNotifications() async {
        guard let notifications else { return }
        do {
            try await notifications.synchronize(reminders: snapshot.reminders, preferences: snapshot.preferences.reminders, petName: snapshot.pet.name)
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

private extension PetPlanifySnapshot {
    func workspace(for petID: UUID) -> PetWorkspace? {
        if pet.id == petID {
            return PetWorkspace(
                pet: pet,
                nutrition: nutrition,
                health: health,
                training: training,
                reminders: reminders,
                onboarding: onboarding,
                modifiedAt: modifiedAt
            )
        }
        return pets.first { $0.pet.id == petID }
    }

    mutating func replaceWorkspace(_ workspace: PetWorkspace) {
        if let index = pets.firstIndex(where: { $0.pet.id == workspace.pet.id }) { pets[index] = workspace }
        else { pets.append(workspace) }
        if pet.id == workspace.pet.id { loadWorkspace(workspace) }
    }
}

private extension DeletedCareRecord {
    func restore(into workspace: inout PetWorkspace) throws {
        switch kind {
        case .weight:
            workspace.health.weights.upsert(try decode(WeightRecord.self))
        case .vaccine:
            workspace.health.vaccines.upsert(try decode(VaccinationRecord.self))
        case .deworming:
            workspace.health.dewormings.upsert(try decode(DewormingRecord.self))
        case .medication:
            workspace.health.medications.upsert(try decode(MedicationRecord.self))
        case .visit:
            workspace.health.visits.upsert(try decode(VeterinaryVisit.self))
        case .nutritionObservation:
            workspace.nutrition.observations.upsert(try decode(PetObservation.self))
        case .healthObservation:
            workspace.health.observations.upsert(try decode(PetObservation.self))
        case .trainingObservation:
            workspace.training.observations.upsert(try decode(BehaviorObservation.self))
        case .reminder:
            workspace.reminders.upsert(try decode(CareReminder.self))
        }
        workspace.modifiedAt = .now
    }
}
