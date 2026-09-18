import Foundation
import CloudKit
import UserNotifications

protocol PetPlanifyPersistence: Sendable {
    func load() async throws -> SnapshotLoadResult
    func save(_ snapshot: PetPlanifySnapshot) async throws
    func reset() async throws
    func clearSession() async throws
}

enum ServiceAvailabilityError: LocalizedError, Sendable {
    case cloudKitNotConfigured
    case sharingRequiresCloudKit

    var errorDescription: String? {
        switch self {
        case .cloudKitNotConfigured:
            String(localized: "La compartición familiar con iCloud todavía no está disponible. Tus datos siguen vinculados a tu cuenta de Apple.")
        case .sharingRequiresCloudKit:
            String(localized: "La compartición familiar requiere una invitación de iCloud válida.")
        }
    }
}

actor CloudKitPersistenceService: PetPlanifyPersistence {
    private let database: CKDatabase
    private let recordID = CKRecord.ID(recordName: "petplanify.snapshot.v1")

    init(containerIdentifier: String = "iCloud.com.anavalladares.PetPlanify") {
        database = CKContainer(identifier: containerIdentifier).privateCloudDatabase
    }

    func load() async throws -> SnapshotLoadResult {
        try await withThrowingTaskGroup(of: SnapshotLoadResult.self) { group in
            group.addTask { try await self.loadRemote() }
            group.addTask {
                try await Task.sleep(nanoseconds: 8_000_000_000)
                throw StorageError.readFailed
            }
            guard let result = try await group.next() else { throw StorageError.readFailed }
            group.cancelAll()
            return result
        }
    }

    private func loadRemote() async throws -> SnapshotLoadResult {
        do {
            let record = try await database.record(for: recordID)
            guard let data = record["snapshotJSON"] as? Data else { throw StorageError.invalidSnapshot }
            return SnapshotLoadResult(snapshot: try SnapshotCodec.decode(data))
        } catch let error as CKError where error.code == .unknownItem {
            // A new Apple Account has no record yet. Never import or overwrite
            // it from an old local file: CloudKit is the account's source of truth.
            return SnapshotLoadResult(snapshot: nil)
        }
    }

    func save(_ snapshot: PetPlanifySnapshot) async throws {
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: "PetPlanifySnapshot", recordID: recordID)
        }
        record["snapshotJSON"] = try SnapshotCodec.encode(snapshot) as CKRecordValue
        record["modifiedAt"] = snapshot.modifiedAt as CKRecordValue
        _ = try await database.save(record)
    }

    func reset() async throws {
        do { _ = try await database.deleteRecord(withID: recordID) }
        catch let error as CKError where error.code == .unknownItem { }
    }
    func clearSession() async throws {
        // Sign out clears only the in-memory session; records belong to the Apple Account.
    }

}

/// CloudKit asset boundary for PDFs and profile images. The snapshot keeps only
/// stable attachment metadata; binary files travel separately as CKAsset values.
/// This keeps the record small and makes attachment retries independent from the
/// main snapshot save.
actor CloudKitAttachmentService {
    private let database: CKDatabase

    init(containerIdentifier: String = "iCloud.com.anavalladares.PetPlanify") {
        database = CKContainer(identifier: containerIdentifier).privateCloudDatabase
    }

    func upload(
        files: [(id: UUID, fileURL: URL, contentType: String)],
        ownerID: UUID
    ) async throws {
        let recordID = CKRecord.ID(recordName: "attachments.\(ownerID.uuidString)")
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: "PetPlanifyAttachments", recordID: recordID)
        }
        for file in files {
            guard FileManager.default.fileExists(atPath: file.fileURL.path) else { continue }
            record["asset_\(file.id.uuidString)"] = CKAsset(fileURL: file.fileURL)
            record["type_\(file.id.uuidString)"] = file.contentType as CKRecordValue
        }
        _ = try await database.save(record)
    }

    func download(fileID: UUID, ownerID: UUID, to destination: URL) async throws {
        let recordID = CKRecord.ID(recordName: "attachments.\(ownerID.uuidString)")
        let record = try await database.record(for: recordID)
        guard let asset = record["asset_\(fileID.uuidString)"] as? CKAsset,
              let source = asset.fileURL else { throw StorageError.attachmentUnavailable }
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destination.path) { try FileManager.default.removeItem(at: destination) }
        try FileManager.default.copyItem(at: source, to: destination)
    }

    func delete(fileID: UUID, ownerID: UUID) async throws {
        let recordID = CKRecord.ID(recordName: "attachments.\(ownerID.uuidString)")
        let record = try await database.record(for: recordID)
        record["asset_\(fileID.uuidString)"] = nil
        record["type_\(fileID.uuidString)"] = nil
        _ = try await database.save(record)
    }
}

enum SyncMode: String, Sendable { case cloudKit }

struct PetPlanifySyncStatus: Sendable, Equatable {
    var mode: SyncMode
    var title: String
    var detail: String
    var lastSuccessfulSync: Date?
}

protocol SyncStatusProvider: Sendable {
    func currentStatus() async -> PetPlanifySyncStatus
}

struct CloudKitSyncStatusProvider: SyncStatusProvider {
    func currentStatus() async -> PetPlanifySyncStatus {
        do {
            let account = try await CKContainer(identifier: "iCloud.com.anavalladares.PetPlanify").accountStatus()
            guard account == .available else {
                return PetPlanifySyncStatus(mode: .cloudKit, title: String(localized: "iCloud no disponible"), detail: String(localized: "Comprueba la cuenta de Apple del dispositivo."), lastSuccessfulSync: nil)
            }
            return PetPlanifySyncStatus(mode: .cloudKit, title: String(localized: "Sincronización con iCloud: activa"), detail: String(localized: "Tus datos se guardan en tu cuenta de Apple."), lastSuccessfulSync: .now)
        } catch {
            return PetPlanifySyncStatus(mode: .cloudKit, title: String(localized: "iCloud no disponible"), detail: String(localized: "Comprueba la cuenta de Apple del dispositivo."), lastSuccessfulSync: nil)
        }
    }
}

enum FamilySharingMode: String, Codable, Sendable { case cloudKit }
enum FamilyInvitationStatus: String, Codable, CaseIterable, Sendable {
    case active, used, expired, revoked

    var title: String {
        switch self {
        case .active: String(localized: "Activa")
        case .used: String(localized: "Usada")
        case .expired: String(localized: "Caducada")
        case .revoked: String(localized: "Revocada")
        }
    }
}

struct FamilyInvitation: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var code: String
    var createdAt = Date.now
    var expiresAt: Date
    var status: FamilyInvitationStatus = .active
    var mode: FamilySharingMode = .cloudKit

    var effectiveStatus: FamilyInvitationStatus {
        status == .active && expiresAt < .now ? .expired : status
    }
}

struct FamilyJoinPreview: Sendable, Equatable {
    var familyName: String
    var petNames: [String]
}

protocol FamilySharingService: Sendable {
    var mode: FamilySharingMode { get async }
    func makeInvitation(snapshot: PetPlanifySnapshot, validFor interval: TimeInterval) async throws -> FamilyInvitation
    func validateInvitation(code: String) async throws -> FamilyJoinPreview
}

actor CloudKitFamilySharingService: FamilySharingService {
    var mode: FamilySharingMode { .cloudKit }
    func makeInvitation(snapshot: PetPlanifySnapshot, validFor interval: TimeInterval) async throws -> FamilyInvitation {
        _ = (snapshot, interval)
        throw ServiceAvailabilityError.cloudKitNotConfigured
    }
    func validateInvitation(code: String) async throws -> FamilyJoinPreview {
        _ = code
        throw ServiceAvailabilityError.cloudKitNotConfigured
    }
}

protocol ReminderSchedulingService: Sendable {
    func permissionStatus() async -> UNAuthorizationStatus
    func requestPermission() async throws -> Bool
    func synchronize(reminders: [CareReminder], preferences: ReminderPreferences, petName: String, now: Date) async throws
}

extension ReminderSchedulingService {
    func synchronize(reminders: [CareReminder], preferences: ReminderPreferences, petName: String) async throws {
        try await synchronize(reminders: reminders, preferences: preferences, petName: petName, now: .now)
    }
}
