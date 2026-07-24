import Foundation

enum PreviewData {
    static let referenceDate = DateComponents(
        calendar: Calendar(identifier: .gregorian),
        timeZone: TimeZone(identifier: "Europe/Madrid"),
        year: 2026,
        month: 6,
        day: 12,
        hour: 9
    ).date!

    static let neo = PetProfile(
        name: "Neo",
        breed: "Teckel",
        age: "2 años",
        currentWeight: "6,8 kg",
        healthyWeightRange: "6,5–7,5 kg",
        nextMealTime: "19:00",
        lastMealTime: "07:30",
        activityToday: "35 min",
        nextVeterinaryAppointment: "12 de junio",
        stepsToday: "7.842",
        restToday: "12,4 h",
        hydration: "Adecuada",
        mood: "Alegre",
        weightHistory: [
            WeightEntry(id: 0, month: "Ene", kilograms: 6.6),
            WeightEntry(id: 1, month: "Feb", kilograms: 6.7),
            WeightEntry(id: 2, month: "Mar", kilograms: 6.6),
            WeightEntry(id: 3, month: "Abr", kilograms: 6.9),
            WeightEntry(id: 4, month: "May", kilograms: 6.7),
            WeightEntry(id: 5, month: "Jun", kilograms: 6.8)
        ]
    )
}
