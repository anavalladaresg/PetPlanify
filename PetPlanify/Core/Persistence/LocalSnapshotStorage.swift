import Foundation

actor LocalSnapshotStorage: SnapshotStorage {
    nonisolated let directory: URL
    private let fileManager = FileManager.default

    init(directory: URL = StorageLocations.applicationDirectory) {
        self.directory = directory
    }

    nonisolated var primaryURL: URL { directory.appendingPathComponent("PetPlanify.json") }
    nonisolated var backupURL: URL { directory.appendingPathComponent("PetPlanify.backup.json") }
    private var restorePreviousURL: URL {
        directory.deletingLastPathComponent().appendingPathComponent(".\(directory.lastPathComponent)-restore-previous")
    }
    private var restoreStagingURL: URL {
        directory.deletingLastPathComponent().appendingPathComponent(".\(directory.lastPathComponent)-restore-staging")
    }

    func load() async throws -> SnapshotLoadResult {
        do {
            try recoverInterruptedRestore()
            guard fileManager.fileExists(atPath: primaryURL.path) else {
                if fileManager.fileExists(atPath: backupURL.path) { return try recoverBackup() }
                return SnapshotLoadResult(snapshot: nil)
            }
            do {
                return SnapshotLoadResult(snapshot: try SnapshotCodec.decode(Data(contentsOf: primaryURL)))
            } catch let error as StorageError where error.isFutureSchema {
                throw error
            } catch {
                return try recoverBackup()
            }
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.readFailed
        }
    }

    func save(_ snapshot: PetPlanifySnapshot) async throws {
        do {
            try recoverInterruptedRestore()
            let data = try SnapshotCodec.encode(snapshot)
            try protectFutureFiles()
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: primaryURL.path) {
                let previousData = try Data(contentsOf: primaryURL)
                guard (try? SnapshotCodec.decode(previousData)) != nil else {
                    throw StorageError.unrecoverable
                }
                try previousData.write(to: backupURL, options: .atomic)
            } else {
                try data.write(to: backupURL, options: .atomic)
            }
            try data.write(to: primaryURL, options: .atomic)
            removeUnreferencedAttachments(current: snapshot)
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.saveFailed
        }
    }

    func reset() async throws {
        do {
            try recoverInterruptedRestore()
            try protectFutureFiles()
            if fileManager.fileExists(atPath: directory.path) { try fileManager.removeItem(at: directory) }
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.resetFailed
        }
    }

    func exportBackup(snapshot: PetPlanifySnapshot) async throws -> PetPlanifyBackupDocument {
        try protectFutureFiles()
        return try PetPlanifyBackupDocument(archive: BackupArchive.create(snapshot: snapshot, directory: directory))
    }

    /// Stages and validates the complete replacement first. The old directory remains
    /// recoverable until the new one is in place, and a full copy lives in Recovery afterwards.
    func restore(_ backup: ValidatedBackup) async throws -> PetPlanifySnapshot {
        do {
            try recoverInterruptedRestore()
            try protectFutureFiles()
            try backup.validate()
            try fileManager.createDirectory(at: directory.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: restoreStagingURL.path) {
                try fileManager.removeItem(at: restoreStagingURL)
            }
            try backup.write(to: restoreStagingURL)
            let recovery = restoreStagingURL.appendingPathComponent("Recovery/Before-import-\(UUID().uuidString)")
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: recovery, withIntermediateDirectories: true)
                // Preserve recovery history once without recursively nesting it on every import.
                for item in try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
                    if item.lastPathComponent == "Recovery" {
                        for oldRecovery in try fileManager.contentsOfDirectory(at: item, includingPropertiesForKeys: nil) {
                            try fileManager.copyItem(at: oldRecovery, to: restoreStagingURL.appendingPathComponent("Recovery").appendingPathComponent(oldRecovery.lastPathComponent))
                        }
                    } else {
                        try fileManager.copyItem(at: item, to: recovery.appendingPathComponent(item.lastPathComponent))
                    }
                }
                try fileManager.moveItem(at: directory, to: restorePreviousURL)
            }
            do {
                try fileManager.moveItem(at: restoreStagingURL, to: directory)
            } catch {
                if fileManager.fileExists(atPath: restorePreviousURL.path) {
                    try fileManager.moveItem(at: restorePreviousURL, to: directory)
                }
                throw StorageError.restoreFailed
            }
            // Failure to remove the redundant transaction copy must not undo a successful import.
            try? fileManager.removeItem(at: restorePreviousURL)
            return backup.snapshot
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.restoreFailed
        }
    }

    /// Keep files used by either recoverable revision; discard only unreferenced managed files.
    /// The application store serializes imports and snapshot writes under the same mutation gate.
    private func removeUnreferencedAttachments(current: PetPlanifySnapshot) {
        guard let previousData = try? Data(contentsOf: backupURL),
              let previous = try? SnapshotCodec.decode(previousData) else { return }
        let retained = BackupArchive.referencedPaths(in: current).union(BackupArchive.referencedPaths(in: previous))
        let folder = directory.appendingPathComponent("Attachments", isDirectory: true)
        guard let items = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey]) else { return }
        for item in items {
            let path = "Attachments/" + item.lastPathComponent
            guard !retained.contains(path),
                  let values = try? item.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]),
                  values.isRegularFile == true, values.isSymbolicLink != true,
                  (try? StorageLocations.attachmentURL(for: path, directory: directory)) != nil else { continue }
            try? fileManager.removeItem(at: item)
        }
    }

    private func recoverBackup() throws -> SnapshotLoadResult {
        guard fileManager.fileExists(atPath: backupURL.path) else { throw StorageError.unrecoverable }
        let data: Data
        let snapshot: PetPlanifySnapshot
        do {
            data = try Data(contentsOf: backupURL)
            snapshot = try SnapshotCodec.decode(data)
        } catch let error as StorageError where error.isFutureSchema {
            throw error
        } catch {
            throw StorageError.unrecoverable
        }
        if fileManager.fileExists(atPath: primaryURL.path) {
            let recoveryDirectory = directory.appendingPathComponent("Recovery")
            try fileManager.createDirectory(at: recoveryDirectory, withIntermediateDirectories: true)
            try fileManager.copyItem(at: primaryURL, to: recoveryDirectory.appendingPathComponent("Damaged-\(UUID().uuidString).json"))
        }
        try data.write(to: primaryURL, options: .atomic)
        return SnapshotLoadResult(snapshot: snapshot, recoveryNotice: String(localized: "Hemos recuperado tus datos desde la última copia local disponible."))
    }

    private func protectFutureFiles() throws {
        for url in [primaryURL, backupURL] where fileManager.fileExists(atPath: url.path) {
            do {
                _ = try SnapshotCodec.schemaVersion(in: Data(contentsOf: url))
            } catch let error as StorageError where error.isFutureSchema {
                throw error
            } catch {
                // Damaged originals can be preserved by explicit import or reset.
            }
        }
    }

    private func recoverInterruptedRestore() throws {
        if fileManager.fileExists(atPath: restorePreviousURL.path) {
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.moveItem(at: restorePreviousURL, to: directory)
            } else {
                // A completed replacement already contains the preserved previous state.
                try? fileManager.removeItem(at: restorePreviousURL)
            }
        }
        if fileManager.fileExists(atPath: restoreStagingURL.path) {
            try? fileManager.removeItem(at: restoreStagingURL)
        }
    }
}

extension StorageError {
    var isFutureSchema: Bool {
        if case .unsupportedSchema = self { return true }
        return false
    }
}
