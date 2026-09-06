import Foundation
import ImageIO
import Testing
@testable import PetPlanifyCore

struct PersistenceTests {
    private func withDirectory(_ operation: (URL) async throws -> Void) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("PetPlanifyTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try await operation(directory.appendingPathComponent("Data"))
    }

    private func sample(_ name: String = "Mascota de prueba") -> PetPlanifySnapshot {
        var snapshot = PetPlanifySnapshot()
        snapshot.pet.name = name
        snapshot.pet.currentWeight = 12.5
        snapshot.onboarding.isComplete = true
        return snapshot
    }

    @Test func firstLaunchAndRelaunch() async throws {
        try await withDirectory { directory in
            let storage = LocalSnapshotStorage(directory: directory)
            #expect(try await storage.load().snapshot == nil)
            let snapshot = sample()
            try await storage.save(snapshot)
            let reloaded = try await LocalSnapshotStorage(directory: directory).load()
            #expect(reloaded.snapshot?.pet.name == snapshot.pet.name)
            #expect(reloaded.snapshot?.pet.id == snapshot.pet.id)
            #expect(reloaded.snapshot?.pet.currentWeight == 12.5)
            #expect(FileManager.default.fileExists(atPath: storage.backupURL.path))
        }
    }

    @Test func backupPreservesPreviousRevision() async throws {
        try await withDirectory { directory in
            let storage = LocalSnapshotStorage(directory: directory)
            try await storage.save(sample("Antes"))
            try await storage.save(sample("Después"))
            #expect(try SnapshotCodec.decode(Data(contentsOf: storage.backupURL)).pet.name == "Antes")
            #expect(try await storage.load().snapshot?.pet.name == "Después")
        }
    }

    @Test func corruptionRecoversAndPreservesDamagedFile() async throws {
        try await withDirectory { directory in
            let storage = LocalSnapshotStorage(directory: directory)
            try await storage.save(sample("Recuperada"))
            try await storage.save(sample("Actual"))
            let damaged = Data("damaged test fixture".utf8)
            try damaged.write(to: storage.primaryURL)
            let result = try await storage.load()
            #expect(result.snapshot?.pet.name == "Recuperada")
            #expect(result.recoveryNotice != nil)
            let preserved = try FileManager.default.contentsOfDirectory(at: directory.appendingPathComponent("Recovery"), includingPropertiesForKeys: nil)
            #expect(preserved.count == 1)
            #expect(try Data(contentsOf: preserved[0]) == damaged)
            #expect(try SnapshotCodec.decode(Data(contentsOf: storage.primaryURL)).pet.name == "Recuperada")
        }
    }

    @Test func unrecoverableDataIsNeverSilentlyReplaced() async throws {
        try await withDirectory { directory in
            let storage = LocalSnapshotStorage(directory: directory)
            try await storage.save(sample())
            let damaged = Data("broken disposable fixture".utf8)
            try damaged.write(to: storage.primaryURL)
            try damaged.write(to: storage.backupURL)
            await #expect(throws: StorageError.unrecoverable) { try await storage.load() }
            await #expect(throws: StorageError.unrecoverable) { try await storage.save(sample("No sustituir")) }
            #expect(try Data(contentsOf: storage.primaryURL) == damaged)
            #expect(try Data(contentsOf: storage.backupURL) == damaged)
        }
    }

    @Test func futureSchemaNeverFallsBackOrOverwrites() async throws {
        try await withDirectory { directory in
            let storage = LocalSnapshotStorage(directory: directory)
            let snapshot = sample()
            try await storage.save(snapshot)
            let archive = try BackupArchive.create(snapshot: snapshot, directory: directory)
            let future = Data(#"{"schemaVersion":99,"unknownFutureData":"preserve"}"#.utf8)
            try future.write(to: storage.primaryURL)
            await #expect(throws: StorageError.unsupportedSchema(99)) { try await storage.load() }
            await #expect(throws: StorageError.unsupportedSchema(99)) { try await storage.save(snapshot) }
            await #expect(throws: StorageError.unsupportedSchema(99)) { try await storage.restore(archive) }
            #expect(try Data(contentsOf: storage.primaryURL) == future)
        }
    }

    @Test func futureBackupAlsoRemainsUntouched() async throws {
        try await withDirectory { directory in
            let storage = LocalSnapshotStorage(directory: directory)
            try await storage.save(sample())
            let future = Data(#"{"schemaVersion":2}"#.utf8)
            try future.write(to: storage.backupURL)
            await #expect(throws: StorageError.unsupportedSchema(2)) { try await storage.save(sample()) }
            #expect(try Data(contentsOf: storage.backupURL) == future)
        }
    }

    @Test func packageRoundTripAndFullRestorePreservePreviousDocuments() async throws {
        try await withDirectory { directory in
            let storage = LocalSnapshotStorage(directory: directory)
            var previous = sample("Anterior")
            let oldPath = "Attachments/old.pdf"
            try FileManager.default.createDirectory(at: directory.appendingPathComponent("Attachments"), withIntermediateDirectories: true)
            let oldContents = Data("%PDF-1.4 disposable previous document".utf8)
            try oldContents.write(to: directory.appendingPathComponent(oldPath))
            previous.health.documents = [DocumentAttachment(displayName: "Anterior.pdf", type: "com.adobe.pdf", relativeStoragePath: oldPath)]
            try await storage.save(previous)
            var imported = sample("Importada")
            let newPath = "Attachments/new.jpg"
            imported.pet.photoPath = newPath
            let newContents = Data("disposable photo bytes for archive transport".utf8)
            try newContents.write(to: directory.appendingPathComponent(newPath))
            let archive = try BackupArchive.create(snapshot: imported, directory: directory)
            let document = try PetPlanifyBackupDocument(archive: archive)
            let packageURL = directory.deletingLastPathComponent().appendingPathComponent("Test.petplanify")
            try document.packageFileWrapper().write(to: packageURL, options: .atomic, originalContentsURL: nil)
            let validated = try await BackupArchive.read(from: packageURL)
            #expect(validated.attachmentCount == 1)
            _ = try await storage.restore(validated)
            #expect(try await storage.load().snapshot?.pet.name == "Importada")
            #expect(try Data(contentsOf: directory.appendingPathComponent(newPath)) == newContents)
            let recovery = try FileManager.default.contentsOfDirectory(at: directory.appendingPathComponent("Recovery"), includingPropertiesForKeys: nil).first!
            #expect(try SnapshotCodec.decode(Data(contentsOf: recovery.appendingPathComponent("PetPlanify.json"))).pet.name == "Anterior")
            #expect(try Data(contentsOf: recovery.appendingPathComponent(oldPath)) == oldContents)
        }
    }

    @Test func incompletePackageDoesNotReplaceLocalData() async throws {
        try await withDirectory { directory in
            let storage = LocalSnapshotStorage(directory: directory)
            let snapshot = sample("Conservar")
            try await storage.save(snapshot)
            let valid = try BackupArchive.create(snapshot: snapshot, directory: directory)
            var manifest = valid.manifest
            manifest.attachments.append(.init(relativePath: "Attachments/missing.pdf", byteCount: 4, sha256: "invalid"))
            let invalid = ValidatedBackup(snapshot: valid.snapshot, manifest: manifest, snapshotData: valid.snapshotData, attachmentData: [:])
            await #expect(throws: StorageError.incompleteBackup) { try await storage.restore(invalid) }
            #expect(try await storage.load().snapshot?.pet.name == "Conservar")
        }
    }

    @Test func attachmentPathsRejectTraversalAndSymlinks() async throws {
        try await withDirectory { directory in
            for path in ["../secret", "/tmp/secret", "Attachments/../secret", "Attachments/../../secret", "Attachments/", "Attachments/a/b.pdf", "Attachments/..", "Attachments/a\\b.pdf"] {
                #expect(throws: StorageError.unsafeAttachmentPath) { try StorageLocations.attachmentURL(for: path, directory: directory) }
            }
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try FileManager.default.createSymbolicLink(at: directory.appendingPathComponent("Attachments"), withDestinationURL: directory.deletingLastPathComponent())
            #expect(throws: StorageError.unsafeAttachmentPath) { try StorageLocations.attachmentURL(for: "Attachments/secret.pdf", directory: directory) }
        }
    }

    @Test func tamperedPackageIsRejected() async throws {
        try await withDirectory { directory in
            let storage = LocalSnapshotStorage(directory: directory)
            try await storage.save(sample())
            let document = try await storage.exportBackup(snapshot: sample())
            let packageURL = directory.deletingLastPathComponent().appendingPathComponent("Tampered.petplanify")
            try document.packageFileWrapper().write(to: packageURL, options: .atomic, originalContentsURL: nil)
            try SnapshotCodec.encode(sample("Manipulada")).write(to: packageURL.appendingPathComponent("snapshot.json"))
            await #expect(throws: StorageError.invalidBackup) { try await BackupArchive.read(from: packageURL) }
        }
    }

    @Test func interruptedImportRollsBackOnNextLaunch() async throws {
        try await withDirectory { directory in
            let storage = LocalSnapshotStorage(directory: directory)
            try await storage.save(sample("Original"))
            let previous = directory.deletingLastPathComponent().appendingPathComponent(".Data-restore-previous")
            let staging = directory.deletingLastPathComponent().appendingPathComponent(".Data-restore-staging")
            try FileManager.default.moveItem(at: directory, to: previous)
            try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
            #expect(try await LocalSnapshotStorage(directory: directory).load().snapshot?.pet.name == "Original")
            #expect(!FileManager.default.fileExists(atPath: previous.path))
            #expect(!FileManager.default.fileExists(atPath: staging.path))
        }
    }

    @Test func resetDeletesRecordsAttachmentsAndRecovery() async throws {
        try await withDirectory { directory in
            let storage = LocalSnapshotStorage(directory: directory)
            try await storage.save(sample())
            try FileManager.default.createDirectory(at: directory.appendingPathComponent("Attachments"), withIntermediateDirectories: true)
            try Data("disposable".utf8).write(to: directory.appendingPathComponent("Attachments/test.pdf"))
            try await storage.reset()
            #expect(!FileManager.default.fileExists(atPath: directory.path))
            #expect(try await storage.load().snapshot == nil)
        }
    }
}
