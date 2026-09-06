import Foundation

extension PetPlanifyStore {
    /// In-memory previews never touch Application Support, notifications, Photos or iCloud.
    static func preview(empty: Bool = false) -> PetPlanifyStore {
        var snapshot = PetPlanifySnapshot()
        if !empty {
            snapshot.pet = PetProfile(name: "Neo", species: "Perro", breed: "Teckel", birthDate: Calendar.current.date(byAdding: .year, value: -2, to: .now), sex: .male, currentWeight: 6.8, healthyWeightRange: WeightRange(lower: 6.5, upper: 7.5), primaryVeterinaryClinic: "Clínica veterinaria")
            snapshot.health.weights = [WeightRecord(date: Date.now.addingTimeInterval(-30 * 86_400), weight: 6.6), WeightRecord(weight: 6.8)]
            snapshot.health.vaccines = [VaccinationRecord(name: "Revisión de vacunas", dateAdministered: .now, nextDueDate: Date.now.addingTimeInterval(30 * 86_400))]
            snapshot.health.dewormings = [DewormingRecord(kind: .internalDeworming, nextDueDate: Date.now.addingTimeInterval(20 * 86_400))]
            snapshot.nutrition.plan = FoodPlan(product: FoodProduct(name: "Alimento habitual", brand: "", type: .dryFood), dailyAmountGrams: 140, meals: [MealScheduleEntry(hour: 9, amountGrams: 70), MealScheduleEntry(hour: 20, amountGrams: 70)])
            if let trick = BuiltInTrickLibrary.tricks.first { snapshot.training.addTrick(trick.id) }
            snapshot.onboarding.isComplete = true
            ReminderEngine.reconcile(&snapshot)
        }
        return PetPlanifyStore(storage: InMemorySnapshotStorage(snapshot: snapshot), initialSnapshot: snapshot, loaded: true)
    }
}
