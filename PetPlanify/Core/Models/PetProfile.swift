import Foundation

struct PetProfile: Sendable {
    let name: String
    let breed: String
    let age: String
    let currentWeight: String
    let healthyWeightRange: String
    let nextMealTime: String
    let lastMealTime: String
    let activityToday: String
    let nextVeterinaryAppointment: String
    let stepsToday: String
    let restToday: String
    let hydration: String
    let mood: String
    let weightHistory: [WeightEntry]
}

struct WeightEntry: Identifiable, Sendable {
    let id: Int
    let month: String
    let kilograms: Double
}

