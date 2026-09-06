import Foundation

extension PetPlanifySnapshot {
    /// Enforce the same invariants for local mutations and imported snapshots.
    var validationError: String? {
        if schemaVersion != SnapshotCodec.currentSchemaVersion { return StorageError.unsupportedSchema(schemaVersion).errorDescription }
        if onboarding.isComplete && (pet.name.isBlank || pet.species.isBlank) {
            return String(localized: "Indica el nombre y la especie de tu mascota.")
        }
        if let date = pet.birthDate, date > Date.now {
            return String(localized: "La fecha de nacimiento no puede estar en el futuro.")
        }
        if let age = pet.approximateAgeMonths, !(0...2_400).contains(age) {
            return String(localized: "Revisa la edad aproximada.")
        }
        if let weight = pet.currentWeight, !Self.validWeight(weight) {
            return String(localized: "Indica un peso positivo.")
        }
        if let range = pet.healthyWeightRange,
           !Self.validWeight(range.lower) || !Self.validWeight(range.upper) || range.lower >= range.upper {
            return String(localized: "Revisa el intervalo de peso de referencia.")
        }
        if let error = nutrition.plan?.validationError { return error }
        if nutrition.history.contains(where: { $0.plan.validationError != nil || $0.endDate < $0.plan.startDate }) {
            return String(localized: "Revisa el historial de alimentación y sus fechas.")
        }
        if nutrition.transitions.contains(where: { $0.previousFood.isBlank || $0.newFood.isBlank || $0.endDate < $0.startDate || !$0.progress.isFinite || !(0...1).contains($0.progress) }) {
            return String(localized: "Revisa los alimentos, las fechas y el progreso de la transición.")
        }
        if !Self.unique(health.weights) || !Self.unique(health.vaccines) || !Self.unique(health.dewormings)
            || !Self.unique(health.medications) || !Self.unique(health.visits) || !Self.unique(health.documents)
            || !Self.unique(health.observations) || !Self.unique(nutrition.observations)
            || !Self.unique(nutrition.transitions) || !Self.unique(nutrition.history) || !Self.unique(reminders)
            || (nutrition.plan.map { !Self.unique($0.meals) } ?? false) {
            return String(localized: "Hay registros duplicados en los datos.")
        }
        if health.weights.contains(where: { !Self.validWeight($0.weight) }) {
            return String(localized: "Revisa los pesos registrados: deben ser positivos.")
        }
        if health.vaccines.contains(where: { $0.name.isBlank }) {
            return String(localized: "Indica el nombre de cada vacuna.")
        }
        for vaccine in health.vaccines {
            if let next = vaccine.nextDueDate, next < vaccine.dateAdministered {
                return String(localized: "La próxima vacuna no puede ser anterior a la administración registrada.")
            }
        }
        for deworming in health.dewormings {
            if let next = deworming.nextDueDate, next < deworming.applicationDate {
                return String(localized: "La próxima desparasitación no puede ser anterior a la aplicación registrada.")
            }
        }
        let visitIDs = Set(health.visits.map(\.id))
        for medication in health.medications {
            if medication.name.isBlank || (medication.endDate.map { $0 < medication.startDate } ?? false) {
                return String(localized: "Revisa el nombre y las fechas de la medicación.")
            }
            if let related = medication.relatedVisitID, !visitIDs.contains(related) {
                return String(localized: "Una medicación está vinculada a una visita que ya no existe.")
            }
        }
        for visit in health.visits {
            if visit.reason.isBlank || (visit.followUpDate.map { $0 < visit.date } ?? false) {
                return String(localized: "Revisa el motivo y las fechas de la visita veterinaria.")
            }
            if Set(visit.documentIDs).count != visit.documentIDs.count {
                return String(localized: "Hay documentos duplicados en una visita.")
            }
            for documentID in visit.documentIDs {
                guard let document = health.documents.first(where: { $0.id == documentID }), document.linkedVisitID == visit.id else {
                    return String(localized: "Revisa los documentos vinculados a las visitas.")
                }
            }
        }
        if Set(health.documents.map(\.relativeStoragePath)).count != health.documents.count {
            return String(localized: "Hay documentos con la misma referencia de archivo.")
        }
        for document in health.documents {
            if document.displayName.isBlank || document.type.isBlank { return String(localized: "Revisa el nombre y el tipo del documento.") }
            if let linkedID = document.linkedVisitID {
                guard let visit = health.visits.first(where: { $0.id == linkedID }), visit.documentIDs.contains(document.id) else {
                    return String(localized: "Revisa los documentos vinculados a las visitas.")
                }
            }
        }
        for path in BackupArchive.referencedPaths(in: self) {
            if (try? StorageLocations.attachmentURL(for: path, directory: URL(fileURLWithPath: "/PetPlanifyValidation"))) == nil {
                return StorageError.unsafeAttachmentPath.errorDescription
            }
        }
        if health.observations.contains(where: { $0.title.isBlank || $0.body.isBlank }) || nutrition.observations.contains(where: { $0.title.isBlank || $0.body.isBlank }) {
            return String(localized: "Las observaciones necesitan título y contenido.")
        }
        if reminders.contains(where: { $0.title.isBlank }) {
            return String(localized: "Indica un título para cada recordatorio.")
        }
        let sourceKeys = reminders.compactMap(\.sourceKey)
        if Set(sourceKeys).count != sourceKeys.count { return String(localized: "Hay recordatorios vinculados duplicados.") }
        return training.validationError
    }

    private static func validWeight(_ value: Double) -> Bool { AppFormat.validWeight(value) }
    private static func unique<T: Identifiable>(_ values: [T]) -> Bool { Set(values.map(\.id)).count == values.count }
}

private extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
