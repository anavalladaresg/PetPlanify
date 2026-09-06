import Foundation
import ImageIO
import UniformTypeIdentifiers

nonisolated enum StorageLocations {
    static var applicationDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PetPlanify", isDirectory: true)
    }

    static func attachmentURL(for relativePath: String, directory: URL) throws -> URL {
        let components = relativePath.split(separator: "/", omittingEmptySubsequences: false)
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
        guard components.count == 2, components[0] == "Attachments",
              !components[1].isEmpty, components[1] != ".", components[1] != "..",
              components[1].unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            throw StorageError.unsafeAttachmentPath
        }
        let attachments = directory.appendingPathComponent("Attachments", isDirectory: true)
        let result = directory.appendingPathComponent(relativePath)
        let resolvedRoot = directory.resolvingSymlinksInPath().standardizedFileURL.path + "/Attachments/"
        guard attachments.resolvingSymlinksInPath().standardizedFileURL.path + "/" == resolvedRoot,
              result.resolvingSymlinksInPath().standardizedFileURL.path.hasPrefix(resolvedRoot) else {
            throw StorageError.unsafeAttachmentPath
        }
        return result
    }
}

struct StoredAttachmentFile: Sendable {
    var displayName: String
    var type: String
    var relativeStoragePath: String
}

actor ManagedAttachmentStorage {
    nonisolated let directory: URL
    static let maximumFileSize = 50 * 1024 * 1024

    init(directory: URL = StorageLocations.applicationDirectory) {
        self.directory = directory
    }

    nonisolated func url(for relativePath: String) throws -> URL {
        try StorageLocations.attachmentURL(for: relativePath, directory: directory)
    }

    func importDocument(from source: URL) async throws -> StoredAttachmentFile {
        let accessing = source.startAccessingSecurityScopedResource()
        defer { if accessing { source.stopAccessingSecurityScopedResource() } }
        do {
            let values = try source.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey, .contentTypeKey])
            guard values.isRegularFile == true, values.isSymbolicLink != true,
                  let type = values.contentType ?? UTType(filenameExtension: source.pathExtension),
                  type.conforms(to: .pdf) || type.conforms(to: .image) else {
                throw StorageError.unsupportedDocument
            }
            guard let size = values.fileSize, size > 0 else { throw StorageError.attachmentUnavailable }
            guard size <= Self.maximumFileSize else { throw StorageError.attachmentTooLarge }
            let suffix = type.preferredFilenameExtension ?? "data"
            let relativePath = "Attachments/\(UUID().uuidString).\(suffix)"
            let destination = try url(for: relativePath)
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: source, to: destination)
            return StoredAttachmentFile(displayName: source.lastPathComponent, type: type.identifier, relativeStoragePath: relativePath)
        } catch let error as StorageError { throw error }
        catch { throw StorageError.attachmentUnavailable }
    }

    func storeProfileImage(_ data: Data) async throws -> String {
        guard data.count <= Self.maximumFileSize else { throw StorageError.attachmentTooLarge }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1200,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { throw StorageError.unsupportedDocument }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw StorageError.attachmentUnavailable
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw StorageError.attachmentUnavailable }
        let path = "Attachments/\(UUID().uuidString).jpg"
        do {
            let destinationURL = try url(for: path)
            try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try (output as Data).write(to: destinationURL, options: .atomic)
            return path
        } catch { throw StorageError.saveFailed }
    }

    func remove(relativePath: String) async throws {
        let destination = try url(for: relativePath)
        guard FileManager.default.fileExists(atPath: destination.path) else { return }
        do { try FileManager.default.removeItem(at: destination) }
        catch { throw StorageError.attachmentUnavailable }
    }
}
