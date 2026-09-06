import Foundation

/// Optional coordinated file exchange. LocalSnapshotStorage remains authoritative.
/// A differing remote copy is always presented for an explicit conflict decision.
actor ICloudSnapshotProvider {
    static let containerIdentifier = "iCloud.com.anavalladares.PetPlanify"
    private var container: URL?

    func isAvailable() -> Bool {
        guard FileManager.default.ubiquityIdentityToken != nil else { return false }
        container = FileManager.default.url(forUbiquityContainerIdentifier: Self.containerIdentifier)
        return container != nil
    }

    func fetch() async throws -> ValidatedBackup? {
        guard isAvailable(), let container else { throw ICloudError.unavailable }
        let url = container.appendingPathComponent("Documents/PetPlanify.petplanify")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        try FileManager.default.startDownloadingUbiquitousItem(at: url)
        let status = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]).ubiquitousItemDownloadingStatus
        if status == .notDownloaded { throw ICloudError.downloading }
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("PetPlanify-iCloud-\(UUID()).petplanify")
        defer { try? FileManager.default.removeItem(at: temporary) }
        var coordinationError: NSError?
        var copyError: Error?
        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinationError) { coordinated in
            do { try FileManager.default.copyItem(at: coordinated, to: temporary) } catch { copyError = error }
        }
        if coordinationError != nil || copyError != nil { throw ICloudError.transferFailed }
        return try await BackupArchive.read(from: temporary)
    }

    func upload(_ archive: ValidatedBackup) throws -> Bool {
        guard isAvailable(), let container else { throw ICloudError.unavailable }
        try archive.validate()
        let documents = container.appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        let target = documents.appendingPathComponent("PetPlanify.petplanify")
        var coordinationError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(writingItemAt: target, options: .forReplacing, error: &coordinationError) { coordinated in
            do {
                // Retain the cloud predecessor before any confirmed replacement.
                if FileManager.default.fileExists(atPath: coordinated.path) {
                    let history = documents.appendingPathComponent("Previous", isDirectory: true)
                    try FileManager.default.createDirectory(at: history, withIntermediateDirectories: true)
                    try FileManager.default.copyItem(at: coordinated, to: history.appendingPathComponent("PetPlanify-\(UUID()).petplanify"))
                }
                let wrapper = try PetPlanifyBackupDocument(archive: archive).packageFileWrapper()
                try wrapper.write(to: coordinated, options: .atomic, originalContentsURL: nil)
            } catch { writeError = error }
        }
        if coordinationError != nil || writeError != nil { throw ICloudError.transferFailed }
        return (try? target.resourceValues(forKeys: [.ubiquitousItemIsUploadedKey]).ubiquitousItemIsUploaded) == true
    }
}

enum ICloudError: LocalizedError {
    case unavailable, downloading, transferFailed
    var errorDescription: String? {
        switch self {
        case .unavailable: String(localized: "iCloud no está configurado o no está disponible. Tus datos siguen guardados en este dispositivo.")
        case .downloading: String(localized: "iCloud está descargando la copia. Vuelve a sincronizar cuando termine.")
        case .transferFailed: String(localized: "No se ha podido completar la transferencia con iCloud. Tus datos locales se conservan.")
        }
    }
}
