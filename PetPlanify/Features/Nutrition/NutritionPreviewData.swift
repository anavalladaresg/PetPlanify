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
            chartHistory: [
                .oneMonth: history(
                    start: date(year: 2026, month: 5, day: 10),
                    step: .weekOfYear,
                    weights: [6.7, 6.8, 6.8, 6.9, 6.8],
                    amounts: [220, 230, 240, 240, 240]
                ),
                .threeMonths: history(
                    start: date(year: 2026, month: 3, day: 22),
                    step: .weekOfYear,
                    weights: [6.6, 6.6, 6.7, 6.7, 6.8, 6.7, 6.8, 6.8, 6.9, 6.8, 6.8, 6.8],
                    amounts: [220, 220, 220, 220, 220, 220, 230, 230, 240, 240, 240, 240]
                ),
                .sixMonths: history(
                    start: date(year: 2026, month: 1, day: 1),
                    step: .month,
                    weights: [6.6, 6.7, 6.6, 6.7, 6.8, 6.8],
                    amounts: [220, 220, 220, 220, 240, 240]
                ),
                .oneYear: history(
                    start: date(year: 2025, month: 7, day: 1),
                    step: .month,
                    weights: [6.5, 6.5, 6.6, 6.5, 6.6, 6.6, 6.6, 6.7, 6.6, 6.7, 6.8, 6.8],
                    amounts: [210, 210, 210, 210, 220, 220, 220, 220, 220, 220, 240, 240]
                )
            ],
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

    private static func history(
        start: Date,
        step: Calendar.Component,
        weights: [Double],
        amounts: [Int]
    ) -> [NutritionHistoryPoint] {
        zip(weights, amounts).enumerated().map { index, values in
            NutritionHistoryPoint(
                id: index,
                date: calendar.date(byAdding: step, value: index, to: start) ?? start,
                weightKilograms: values.0,
                dailyFoodGrams: values.1
            )
        }
    }

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
