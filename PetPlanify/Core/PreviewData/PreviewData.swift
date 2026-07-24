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
        currentWeight: "6,8 kg"
    )
}
