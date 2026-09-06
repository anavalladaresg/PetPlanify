import Foundation

struct PetPlanifySnapshot: Codable, Sendable, Equatable {
    var schemaVersion = 1
    var pet = PetProfile()
    var nutrition = NutritionData()
    var health = HealthData()
    var training = TrainingData()
    var reminders: [CareReminder] = []
    var preferences = AppPreferences()
    var onboarding = OnboardingState()
    var modifiedAt = Date.now

    var currentWeight: Double? {
        health.weights.filter { $0.date <= Date.now }.max { $0.date < $1.date }?.weight ?? pet.currentWeight
    }
}
