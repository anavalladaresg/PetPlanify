import Foundation

enum PreviewData {
    static let referenceDate = Date.now
    static let spanishTimeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt

    static func date(
        daysFromReference days: Int,
        hour: Int = 12,
        minute: Int = 0
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = spanishTimeZone
        let start = calendar.startOfDay(for: referenceDate)
        let day = calendar.date(byAdding: .day, value: days, to: start) ?? start
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: day
        ) ?? day
    }

    static func monthStart(monthsFromReference months: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = spanishTimeZone
        let components = calendar.dateComponents([.year, .month], from: referenceDate)
        let currentMonth = calendar.date(from: components) ?? referenceDate
        return calendar.date(byAdding: .month, value: months, to: currentMonth) ?? currentMonth
    }

    static let neo = PetProfile(
        name: "Neo",
        breed: "Teckel",
        age: "2 años",
        currentWeight: "6,8 kg"
    )
}
