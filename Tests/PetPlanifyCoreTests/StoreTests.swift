import Foundation
import Testing
@testable import PetPlanifyCore

@MainActor struct StoreTests {
    @Test func completeLocalCareFlowSurvivesRelaunchExportRestoreAndReset() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PetPlanifyStoreTests-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appendingPathComponent("Data")
        let storage = LocalSnapshotStorage(directory: directory)
        let attachments = ManagedAttachmentStorage(directory: directory)
        let store = PetPlanifyStore(storage: storage, attachments: attachments)
        await store.load()
        #expect(!store.snapshot.onboarding.isComplete)
        let profile = PetProfile(name: "Mascota de prueba", breed: "Teckel", birthDate: Date(timeIntervalSince1970: 1_600_000_000), currentWeight: 6.8)
        #expect(await store.saveProfile(profile, photoData: nil, removePhoto: false, onboarding: true))
        let visit = VeterinaryVisit(date: Date.now.addingTimeInterval(86_400), reason: "Revisión de prueba", followUpDate: Date.now.addingTimeInterval(2 * 86_400))
        #expect(await store.update {
            $0.pet.name = "Mascota editada"
            $0.health.weights.append(WeightRecord(weight: 7))
            $0.health.vaccines.append(VaccinationRecord(name: "Vacuna de prueba", nextDueDate: Date.now.addingTimeInterval(30 * 86_400)))
            $0.health.dewormings = [.init(kind: .internalDeworming, nextDueDate: Date.now.addingTimeInterval(20 * 86_400)), .init(kind: .externalDeworming, nextDueDate: Date.now.addingTimeInterval(10 * 86_400))]
            $0.health.visits.append(visit)
            $0.health.medications.append(MedicationRecord(name: "Registro manual"))
            $0.nutrition.plan = FoodPlan(product: FoodProduct(name: "Alimento"), dailyAmountGrams: 140, meals: [MealScheduleEntry(amountGrams: 140)])
            $0.training.addTrick("sentado")
            $0.training.selectedTricks[0].progress = 50
            $0.training.selectedTricks[0].status = .learning
            $0.training.customTricks.append(CustomTrick(name: "Truco de prueba"))
            $0.training.observations.append(BehaviorObservation(title: "Observación", observation: "Está más tranquilo"))
            $0.reminders.append(CareReminder(title: "Recordatorio manual", date: Date.now.addingTimeInterval(500)))
            $0.preferences.weightUnit = .pounds
            $0.preferences.appearance = .dark
        })
        let pdf = root.appendingPathComponent("Documento-prueba.pdf")
        try Data("%PDF-1.4\n1 0 obj << /Type /Catalog >> endobj\n%%EOF".utf8).write(to: pdf)
        #expect(await store.importDocument(from: pdf, visitID: visit.id))
        #expect(store.snapshot.health.documents.count == 1)
        #expect(await store.update { $0.reminders[0].isCompleted = true; $0.reminders[0].completedAt = .now })
        let relaunched = PetPlanifyStore(storage: LocalSnapshotStorage(directory: directory), attachments: attachments)
        await relaunched.load()
        #expect(relaunched.snapshot.pet.name == "Mascota editada")
        #expect(relaunched.currentWeight == 7)
        #expect(relaunched.snapshot.training.selectedTricks.first?.progress == 50)
        #expect(relaunched.snapshot.health.documents.count == 1)
        #expect(relaunched.snapshot.preferences.weightUnit == .pounds)
        #expect(relaunched.snapshot.preferences.appearance == .dark)
        let exported = try await relaunched.exportBackup()
        #expect(exported.validatedBackup.attachmentCount == 1)
        #expect(await relaunched.reset())
        #expect(!relaunched.snapshot.onboarding.isComplete)
        #expect(await relaunched.restoreBackup(exported.validatedBackup))
        #expect(relaunched.snapshot.health.visits.count == 1)
        #expect(relaunched.snapshot.reminders.contains { $0.isCompleted })
        #expect(await relaunched.reset())
        #expect(!FileManager.default.fileExists(atPath: directory.path))
    }

    @Test func failedSaveKeepsPublishedStateAndConcurrentMutationsDoNotLoseRecords() async {
        let storage = FailingStorage()
        let store = PetPlanifyStore(storage: storage, loaded: true)
        #expect(!(await store.update { $0.pet.name = "No guardado" }))
        #expect(store.snapshot.pet.name.isEmpty)
        let concurrent = PetPlanifyStore(storage: InMemorySnapshotStorage(), loaded: true)
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<10 {
                group.addTask { await concurrent.update { $0.reminders.append(CareReminder(title: "Registro \(index)")) } }
            }
        }
        #expect(concurrent.snapshot.reminders.count == 10)
    }
}

private actor FailingStorage: SnapshotStorage {
    func load() async throws -> SnapshotLoadResult { SnapshotLoadResult(snapshot: nil) }
    func save(_ snapshot: PetPlanifySnapshot) async throws { throw StorageError.saveFailed }
    func reset() async throws { }
}
