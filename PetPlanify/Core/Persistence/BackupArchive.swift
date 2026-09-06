import CryptoKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let petPlanifyBackup = UTType(exportedAs: "com.anavalladares.petplanify.backup", conformingTo: .package)
}

struct BackupManifest: Codable, Sendable {
    struct Entry: Codable, Sendable {
        var relativePath: String
        var byteCount: Int
        var sha256: String
    }

    var formatVersion = 1
    var schemaVersion: Int
    var createdAt: Date
    var snapshotSHA256: String
    var attachments: [Entry]
}

struct ValidatedBackup: Sendable {
    let snapshot: PetPlanifySnapshot
    let manifest: BackupManifest
    let snapshotData: Data
    let attachmentData: [String: Data]

    var createdAt: Date { manifest.createdAt }
    var attachmentCount: Int { attachmentData.count }

    func validate() throws {
        guard manifest.formatVersion == 1 else { throw StorageError.invalidBackup }
        guard manifest.schemaVersion <= SnapshotCodec.currentSchemaVersion else {
            throw StorageError.unsupportedSchema(manifest.schemaVersion)
        }
        guard manifest.schemaVersion == snapshot.schemaVersion,
              BackupArchive.digest(snapshotData) == manifest.snapshotSHA256,
              try SnapshotCodec.decode(snapshotData) == snapshot else { throw StorageError.invalidBackup }
        let paths = manifest.attachments.map(\.relativePath)
        guard paths.count <= BackupArchive.maximumAttachmentCount,
              Set(paths).count == paths.count,
              Set(paths) == Set(attachmentData.keys),
              Set(paths) == BackupArchive.referencedPaths(in: snapshot) else { throw StorageError.incompleteBackup }
        var totalBytes = snapshotData.count
        for entry in manifest.attachments {
            _ = try StorageLocations.attachmentURL(for: entry.relativePath, directory: URL(fileURLWithPath: "/PetPlanifyValidation"))
            guard let data = attachmentData[entry.relativePath], data.count == entry.byteCount,
                  !data.isEmpty, data.count <= ManagedAttachmentStorage.maximumFileSize,
                  BackupArchive.digest(data) == entry.sha256 else { throw StorageError.incompleteBackup }
            totalBytes += data.count
            guard totalBytes <= BackupArchive.maximumBackupSize else { throw StorageError.invalidBackup }
        }
    }

    func write(to directory: URL) throws {
        try validate()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try snapshotData.write(to: directory.appendingPathComponent("PetPlanify.json"), options: .atomic)
        try snapshotData.write(to: directory.appendingPathComponent("PetPlanify.backup.json"), options: .atomic)
        for (path, data) in attachmentData {
            let url = try StorageLocations.attachmentURL(for: path, directory: directory)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        }
    }
}

enum BackupArchive {
    static let maximumBackupSize = 250 * 1024 * 1024
    static let maximumSnapshotSize = 10 * 1024 * 1024
    static let maximumAttachmentCount = 500

    static func read(from source: URL) async throws -> ValidatedBackup {
        try await Task.detached(priority: .userInitiated) {
            let accessing = source.startAccessingSecurityScopedResource()
            defer { if accessing { source.stopAccessingSecurityScopedResource() } }
            do {
                let values = try source.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                guard values.isDirectory == true, values.isSymbolicLink != true else { throw StorageError.invalidBackup }
                let children = try FileManager.default.contentsOfDirectory(at: source, includingPropertiesForKeys: [.isSymbolicLinkKey])
                guard Set(children.map(\.lastPathComponent)).isSubset(of: ["manifest.json", "snapshot.json", "Attachments"]) else {
                    throw StorageError.invalidBackup
                }
                let manifestData = try boundedRead(source.appendingPathComponent("manifest.json"), maximumSize: maximumSnapshotSize)
                let manifest = try decodeManifest(manifestData)
                let snapshotData = try boundedRead(source.appendingPathComponent("snapshot.json"), maximumSize: maximumSnapshotSize)
                let snapshot = try SnapshotCodec.decode(snapshotData)
                guard manifest.attachments.count <= maximumAttachmentCount else { throw StorageError.invalidBackup }
                var files: [String: Data] = [:]
                var total = snapshotData.count
                for entry in manifest.attachments {
                    let url = try StorageLocations.attachmentURL(for: entry.relativePath, directory: source)
                    let data = try boundedRead(url, maximumSize: ManagedAttachmentStorage.maximumFileSize)
                    total += data.count
                    guard total <= maximumBackupSize else { throw StorageError.invalidBackup }
                    guard files.updateValue(data, forKey: entry.relativePath) == nil else { throw StorageError.invalidBackup }
                }
                if FileManager.default.fileExists(atPath: source.appendingPathComponent("Attachments").path) {
                    let contents = try FileManager.default.contentsOfDirectory(at: source.appendingPathComponent("Attachments"), includingPropertiesForKeys: nil)
                    guard Set(contents.map { "Attachments/" + $0.lastPathComponent }) == Set(files.keys) else { throw StorageError.invalidBackup }
                }
                let backup = ValidatedBackup(snapshot: snapshot, manifest: manifest, snapshotData: snapshotData, attachmentData: files)
                try backup.validate()
                return backup
            } catch let error as StorageError { throw error }
            catch { throw StorageError.invalidBackup }
        }.value
    }

    static func create(snapshot: PetPlanifySnapshot, directory: URL) throws -> ValidatedBackup {
        let data = try SnapshotCodec.encode(snapshot)
        guard data.count <= maximumSnapshotSize else { throw StorageError.invalidBackup }
        var files: [String: Data] = [:]
        let paths = referencedPaths(in: snapshot).sorted()
        guard paths.count <= maximumAttachmentCount else { throw StorageError.invalidBackup }
        var total = data.count
        for path in paths {
            let fileURL = try StorageLocations.attachmentURL(for: path, directory: directory)
            let file = try boundedRead(fileURL, maximumSize: ManagedAttachmentStorage.maximumFileSize)
            total += file.count
            guard total <= maximumBackupSize else { throw StorageError.invalidBackup }
            files[path] = file
        }
        let manifest = BackupManifest(schemaVersion: snapshot.schemaVersion, createdAt: Date(), snapshotSHA256: digest(data), attachments: paths.map {
            BackupManifest.Entry(relativePath: $0, byteCount: files[$0]!.count, sha256: digest(files[$0]!))
        })
        let backup = ValidatedBackup(snapshot: try SnapshotCodec.decode(data), manifest: manifest, snapshotData: data, attachmentData: files)
        try backup.validate()
        return backup
    }

    static func referencedPaths(in snapshot: PetPlanifySnapshot) -> Set<String> {
        var paths = Set(snapshot.health.documents.map(\.relativeStoragePath))
        if let photo = snapshot.pet.photoPath { paths.insert(photo) }
        return paths
    }

    static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func encodeManifest(_ manifest: BackupManifest) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(manifest)
    }

    static func decodeManifest(_ data: Data) throws -> BackupManifest {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        guard let manifest = try? decoder.decode(BackupManifest.self, from: data), manifest.formatVersion == 1 else {
            throw StorageError.invalidBackup
        }
        guard manifest.schemaVersion <= SnapshotCodec.currentSchemaVersion else {
            throw StorageError.unsupportedSchema(manifest.schemaVersion)
        }
        return manifest
    }

    private static func boundedRead(_ url: URL, maximumSize: Int) throws -> Data {
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey]),
              values.isRegularFile == true, values.isSymbolicLink != true, let count = values.fileSize,
              count > 0, count <= maximumSize else { throw StorageError.incompleteBackup }
        let data = try Data(contentsOf: url)
        guard data.count == count else { throw StorageError.incompleteBackup }
        return data
    }
}

struct PetPlanifyBackupDocument: FileDocument, Sendable {
    static var readableContentTypes: [UTType] { [.petPlanifyBackup] }
    let validatedBackup: ValidatedBackup

    init(archive: ValidatedBackup) throws {
        try archive.validate()
        validatedBackup = archive
    }

    init(configuration: ReadConfiguration) throws {
        guard configuration.file.isDirectory, let children = configuration.file.fileWrappers,
              Set(children.keys).isSubset(of: ["manifest.json", "snapshot.json", "Attachments"]),
              let manifestData = children["manifest.json"]?.regularFileContents,
              let snapshotData = children["snapshot.json"]?.regularFileContents,
              manifestData.count <= BackupArchive.maximumSnapshotSize,
              snapshotData.count <= BackupArchive.maximumSnapshotSize else { throw StorageError.invalidBackup }
        let manifest = try BackupArchive.decodeManifest(manifestData)
        let snapshot = try SnapshotCodec.decode(snapshotData)
        var files: [String: Data] = [:]
        if let folder = children["Attachments"] {
            guard folder.isDirectory, let wrappers = folder.fileWrappers,
                  wrappers.count <= BackupArchive.maximumAttachmentCount else { throw StorageError.invalidBackup }
            for (name, file) in wrappers {
                guard file.isRegularFile, let data = file.regularFileContents else { throw StorageError.invalidBackup }
                files["Attachments/" + name] = data
            }
        }
        let backup = ValidatedBackup(snapshot: snapshot, manifest: manifest, snapshotData: snapshotData, attachmentData: files)
        try backup.validate()
        validatedBackup = backup
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try packageFileWrapper()
    }

    func packageFileWrapper() throws -> FileWrapper {
        try validatedBackup.validate()
        var attachments: [String: FileWrapper] = [:]
        for (path, data) in validatedBackup.attachmentData {
            attachments[URL(fileURLWithPath: path).lastPathComponent] = FileWrapper(regularFileWithContents: data)
        }
        return FileWrapper(directoryWithFileWrappers: [
            "manifest.json": FileWrapper(regularFileWithContents: try BackupArchive.encodeManifest(validatedBackup.manifest)),
            "snapshot.json": FileWrapper(regularFileWithContents: validatedBackup.snapshotData),
            "Attachments": FileWrapper(directoryWithFileWrappers: attachments)
        ])
    }
}
