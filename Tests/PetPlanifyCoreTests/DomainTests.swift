import Foundation
import Testing
@testable import PetPlanifyCore

struct DomainTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func jsonRoundTripPreservesStableIDsAndDates() throws {
        var value = PetPlanifySnapshot()
        value.pet.birthDate = now.addingTimeInterval(-100_000_000)
        value.health.weights = [WeightRecord(date: now, weight: 6.8, note: "Control")]
        value.modifiedAt = now
        let decoded = try SnapshotCodec.decode(SnapshotCodec.encode(value))
        #expect(decoded.pet.id == value.pet.id)
        #expect(decoded.health.weights.first?.id == value.health.weights.first?.id)
        #expect(decoded.health.weights.first?.date == now)
        #expect(decoded.modifiedAt == now)
    }

    @Test func derivesExactAndApproximateAgeUsingCalendar() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let birthday = calendar.date(from: DateComponents(year: 2022, month: 9, day: 6))!
        let reference = calendar.date(from: DateComponents(year: 2026, month: 9, day: 5))!
        var profile = PetProfile(birthDate: birthday)
        #expect(profile.ageMonths(at: reference, calendar: calendar) == 47)
        profile.birthDate = nil; profile.approximateAgeMonths = 12; profile.ageReferenceDate = birthday
        #expect(profile.ageMonths(at: reference, calendar: calendar) == 59)
    }

    @Test func currentWeightUsesMostRecentActualRecord() {
        var snapshot = PetPlanifySnapshot()
        snapshot.pet.currentWeight = 5
        snapshot.health.weights = [WeightRecord(date: Date.now.addingTimeInterval(-100), weight: 6), WeightRecord(date: Date.now.addingTimeInterval(-200), weight: 7), WeightRecord(date: Date.now.addingTimeInterval(100), weight: 9)]
        #expect(snapshot.currentWeight == 6)
    }

    @Test func weightConversionsDoNotChangeCanonicalHistory() {
        let kg = 6.8
        #expect(abs(WeightUnit.pounds.kilograms(from: WeightUnit.pounds.fromKilograms(kg)) - kg) < 0.000001)
        #expect(WeightUnit.kilograms.fromKilograms(kg) == kg)
        #expect(AppFormat.parseNumber("6,8") == kg)
        #expect(AppFormat.parseNumber("6.8") == kg)
        for invalid in ["1,2,3", "1.000,2", "-2", "nan", "5kg", "1e3", ""] { #expect(AppFormat.parseNumber(invalid) == nil) }
        #expect(!AppFormat.validWeight(0))
        #expect(!AppFormat.validWeight(.infinity))
        #expect(!AppFormat.validWeight(-1))
    }

    @Test func foodPlanRequiresPositiveBalancedMeals() {
        var plan = FoodPlan(product: FoodProduct(name: "Alimento"), dailyAmountGrams: 140, meals: [MealScheduleEntry(amountGrams: 70), MealScheduleEntry(hour: 20, amountGrams: 70)])
        #expect(plan.validationError == nil)
        plan.meals[0].amountGrams = 60
        #expect(plan.validationError != nil)
        plan.meals[0].amountGrams = -70
        #expect(plan.validationError != nil)
        plan.meals = []
        #expect(plan.validationError != nil)
    }

    @Test func upcomingExcludesPastAndCompleted() {
        let values = [CareReminder(title: "Ayer", date: now.addingTimeInterval(-1)), CareReminder(title: "Luego", date: now.addingTimeInterval(100)), CareReminder(title: "Hecho", date: now.addingTimeInterval(10), isCompleted: true)]
        #expect(ReminderEngine.upcoming(values, now: now).map(\.title) == ["Luego"])
        #expect(values[0].isOverdue(at: now))
        #expect(!values[2].isOverdue(at: now.addingTimeInterval(20)))
    }

    @Test func medicationStateDerivedFromBothDates() {
        let medication = MedicationRecord(name: "Tratamiento anotado", startDate: now, endDate: now.addingTimeInterval(100))
        #expect(!medication.isActive(relativeTo: now.addingTimeInterval(-1)))
        #expect(medication.isActive(relativeTo: now.addingTimeInterval(1)))
        #expect(!medication.isActive(relativeTo: now.addingTimeInterval(100)))
    }

    @Test func linkedReminderIdentityCompletionAndRescheduling() {
        var snapshot = PetPlanifySnapshot()
        let vaccine = VaccinationRecord(name: "Vacuna", dateAdministered: now, nextDueDate: now.addingTimeInterval(100))
        snapshot.health.vaccines = [vaccine]
        ReminderEngine.reconcile(&snapshot, now: now)
        let id = snapshot.reminders[0].id
        let notificationID = snapshot.reminders[0].notificationIdentifier
        snapshot.reminders[0].isCompleted = true
        ReminderEngine.reconcile(&snapshot, now: now)
        #expect(snapshot.reminders[0].isCompleted)
        snapshot.health.vaccines[0].nextDueDate = now.addingTimeInterval(200)
        ReminderEngine.reconcile(&snapshot, now: now)
        #expect(snapshot.reminders[0].id == id)
        #expect(snapshot.reminders[0].notificationIdentifier == notificationID)
        #expect(!snapshot.reminders[0].isCompleted)
        snapshot.health.vaccines = []
        ReminderEngine.reconcile(&snapshot, now: now)
        #expect(snapshot.reminders.isEmpty)
    }

    @Test func dewormingKeepsOnlyNewestRelevantApplication() {
        var snapshot = PetPlanifySnapshot()
        snapshot.health.dewormings = [DewormingRecord(kind: .internalDeworming, applicationDate: now, nextDueDate: now.addingTimeInterval(10)), DewormingRecord(kind: .internalDeworming, applicationDate: now.addingTimeInterval(5), nextDueDate: now.addingTimeInterval(20)), DewormingRecord(kind: .externalDeworming, applicationDate: now, nextDueDate: now.addingTimeInterval(30))]
        ReminderEngine.reconcile(&snapshot, now: now)
        #expect(snapshot.reminders.count == 2)
        #expect(snapshot.reminders.map(\.date) == [now.addingTimeInterval(20), now.addingTimeInterval(30)])
    }

    @Test func notificationPreferencesRespectCategoryCompletionAndAdvance() {
        var preferences = ReminderPreferences(notificationsEnabled: true, advanceTime: .oneDay)
        var reminder = CareReminder(title: "Cuidado", date: now, relatedFeature: .health)
        #expect(ReminderEngine.notificationDate(for: reminder, preferences: preferences) == Calendar.current.date(byAdding: .day, value: -1, to: now))
        preferences.healthEnabled = false
        #expect(ReminderEngine.notificationDate(for: reminder, preferences: preferences) == nil)
        preferences.healthEnabled = true; reminder.isCompleted = true
        #expect(ReminderEngine.notificationDate(for: reminder, preferences: preferences) == nil)
    }

    @Test func libraryAndCustomProgressSurvivePersistence() throws {
        var snapshot = PetPlanifySnapshot()
        #expect(BuiltInTrickLibrary.tricks.count == 19)
        #expect(Set(BuiltInTrickLibrary.tricks.map(\.id)).count == 19)
        #expect(BuiltInTrickLibrary.tricks.allSatisfy { !$0.guide.steps.isEmpty && !$0.guide.precautions.isEmpty })
        let custom = CustomTrick(name: "Mi truco", objective: "Un objetivo", steps: ["Un paso"])
        snapshot.training.customTricks.append(custom)
        snapshot.training.addTrick(custom.trickID)
        snapshot.training.selectedTricks[0].progress = 40
        snapshot.training.selectedTricks[0].status = .learning
        let reloaded = try SnapshotCodec.decode(SnapshotCodec.encode(snapshot))
        #expect(reloaded.training.selectedTricks[0].progress == 40)
        #expect(reloaded.training.selectedTricks[0].id == snapshot.training.selectedTricks[0].id)
        snapshot.training.removeCustomTrick(custom.id)
        #expect(snapshot.training.selectedTricks.isEmpty)
    }
}
