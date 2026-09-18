import Foundation

enum SnapshotCodec {
    static let currentSchemaVersion = 1
    static func encode(_ snapshot: PetPlanifySnapshot) throws -> Data { try JSONEncoder().encode(snapshot) }
    static func decode(_ data: Data) throws -> PetPlanifySnapshot { try JSONDecoder().decode(PetPlanifySnapshot.self, from: data) }
}

struct SnapshotLoadResult: Sendable {
    var snapshot: PetPlanifySnapshot?
    var recoveryNotice: String?

    init(snapshot: PetPlanifySnapshot?, recoveryNotice: String? = nil) {
        self.snapshot = snapshot
        self.recoveryNotice = recoveryNotice
    }
}

enum StorageError: LocalizedError, Sendable, Equatable {
    case unsupportedSchema(Int), invalidSnapshot, readFailed, saveFailed, resetFailed
    case unsafeAttachmentPath, unsupportedDocument, attachmentTooLarge, attachmentUnavailable

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema: String(localized: "Estos datos pertenecen a una versión más reciente de PetPlanify.")
        case .invalidSnapshot: String(localized: "No se han podido leer los datos de tu cuenta de Apple.")
        case .readFailed: String(localized: "No se han podido cargar tus datos de iCloud.")
        case .saveFailed: String(localized: "No se han podido guardar los cambios en iCloud.")
        case .resetFailed: String(localized: "No se han podido eliminar los datos de iCloud.")
        case .unsafeAttachmentPath: String(localized: "No se ha podido acceder al archivo.")
        case .unsupportedDocument: String(localized: "Este documento no es compatible.")
        case .attachmentTooLarge: String(localized: "El archivo es demasiado grande.")
        case .attachmentUnavailable: String(localized: "No se ha podido guardar el archivo.")
        }
    }
}
