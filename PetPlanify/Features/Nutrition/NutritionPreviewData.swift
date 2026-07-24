import Foundation

enum NutritionPreviewData {
    static let neoPlan: FoodPlan = {
        let currentFood = FoodProduct(
            name: "Brit Care Mini Adult Lamb",
            brand: "Brit Care",
            type: .dryFood
        )
        let previousFood = FoodProduct(
            name: "Brit Care Mini Adult Turkey",
            brand: "Brit Care",
            type: .dryFood
        )
        let planStartDate = date(year: 2026, month: 5, day: 10)

        return FoodPlan(
            currentFood: currentFood,
            startDate: planStartDate,
            dailyAmountGrams: 240,
            mealsPerDay: 2,
            approximateCaloriesPerDay: 420,
            meals: [
                ScheduledMeal(id: 0, kind: .breakfast, time: "07:30", amountGrams: 120),
                ScheduledMeal(id: 1, kind: .dinner, time: "19:00", amountGrams: 120)
            ],
            transition: FoodTransition(
                previousFood: previousFood,
                currentFood: currentFood,
                progress: 1,
                completionDate: planStartDate
            ),
            currentWeightKilograms: 6.8,
            healthyWeightRange: 6.5 ... 7.5,
            foodHistory: [
                FoodHistoryEntry(
                    id: 0,
                    food: currentFood,
                    startDate: planStartDate,
                    endDate: nil
                ),
                FoodHistoryEntry(
                    id: 1,
                    food: previousFood,
                    startDate: date(year: 2026, month: 1, day: 15),
                    endDate: date(year: 2026, month: 5, day: 9)
                )
            ]
        )
    }()

    private static func date(year: Int, month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
            ?? Date(timeIntervalSince1970: 0)
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = NutritionFormatting.spanishLocale
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        return calendar
    }
}
