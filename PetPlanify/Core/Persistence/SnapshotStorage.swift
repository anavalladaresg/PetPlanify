import Foundation

protocol SnapshotStorage: Sendable {
    func load() async throws -> SnapshotLoadResult
    func save(_ snapshot: PetPlanifySnapshot) async throws
    func reset() async throws
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
    case unsupportedSchema(Int)
    case invalidSnapshot
    case unrecoverable
    case readFailed
    case saveFailed
    case resetFailed
    case invalidBackup
    case incompleteBackup
    case unsafeAttachmentPath
    case unsupportedDocument
    case attachmentTooLarge
    case attachmentUnavailable
    case restoreFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema:
            String(localized: "Estos datos pertenecen a una versión más reciente de PetPlanify. Actualiza la aplicación para abrirlos; tus archivos se han conservado.")
        case .invalidSnapshot:
            String(localized: "No se han podido leer los datos de PetPlanify.")
        case .unrecoverable:
            String(localized: "No se han podido recuperar los datos. Los archivos originales se han conservado. Puedes importar una copia o restablecer PetPlanify.")
        case .readFailed:
            String(localized: "No se han podido abrir los datos locales. Vuelve a intentarlo.")
        case .saveFailed:
            String(localized: "No se han podido guardar los cambios. Comprueba el espacio disponible y vuelve a intentarlo.")
        case .resetFailed:
            String(localized: "No se han podido restablecer los datos. Vuelve a intentarlo.")
        case .invalidBackup:
            String(localized: "Este archivo no es una copia válida de PetPlanify.")
        case .incompleteBackup:
            String(localized: "La copia está incompleta o alguno de sus archivos ha cambiado. Tus datos actuales se han conservado.")
        case .unsafeAttachmentPath:
            String(localized: "La copia contiene una ruta de archivo no permitida.")
        case .unsupportedDocument:
            String(localized: "Elige un PDF o una imagen compatible.")
        case .attachmentTooLarge:
            String(localized: "El archivo es demasiado grande. Elige uno de menos de 50 MB.")
        case .attachmentUnavailable:
            String(localized: "No se ha podido abrir el archivo. Comprueba que sigue disponible e inténtalo de nuevo.")
        case .restoreFailed:
            String(localized: "No se ha podido importar la copia. Se han conservado los datos anteriores.")
        }
    }
}

/// Version inspection is deliberately separate from decoding so a newer file is never
/// mistaken for corruption and overwritten with an older backup.
enum SnapshotCodec {
    static let currentSchemaVersion = 1

    static func encode(_ snapshot: PetPlanifySnapshot) throws -> Data {
        guard snapshot.schemaVersion == currentSchemaVersion else {
            throw StorageError.unsupportedSchema(snapshot.schemaVersion)
        }
        guard snapshot.validationError == nil else { throw StorageError.invalidSnapshot }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(snapshot)
    }

    static func schemaVersion(in data: Data) throws -> Int {
        struct Header: Decodable { let schemaVersion: Int }
        guard let header = try? JSONDecoder().decode(Header.self, from: data) else {
            throw StorageError.invalidSnapshot
        }
        guard header.schemaVersion <= currentSchemaVersion else {
            throw StorageError.unsupportedSchema(header.schemaVersion)
        }
        return header.schemaVersion
    }

    static func decode(_ data: Data) throws -> PetPlanifySnapshot {
        switch try schemaVersion(in: data) {
        case 1:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            guard let snapshot = try? decoder.decode(PetPlanifySnapshot.self, from: data) else {
                throw StorageError.invalidSnapshot
            }
            guard snapshot.validationError == nil else { throw StorageError.invalidSnapshot }
            return snapshot
        default:
            // Add a migration here only when an older published schema exists.
            throw StorageError.invalidSnapshot
        }
    }
}

actor InMemorySnapshotStorage: SnapshotStorage {
    private var snapshot: PetPlanifySnapshot?

    init(snapshot: PetPlanifySnapshot? = nil) {
        self.snapshot = snapshot
    }

    func load() async throws -> SnapshotLoadResult {
        SnapshotLoadResult(snapshot: snapshot)
    }

    func save(_ snapshot: PetPlanifySnapshot) async throws {
        _ = try SnapshotCodec.encode(snapshot)
        self.snapshot = snapshot
    }

    func reset() async throws {
        snapshot = nil
    }
}
