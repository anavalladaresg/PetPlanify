import Foundation

struct WeightRange: Codable, Sendable, Equatable {
    var lower: Double
    var upper: Double
}

enum PetSex: String, Codable, CaseIterable, Identifiable, Sendable {
    case female, male, unknown
    var id: Self { self }
    var title: String {
        switch self {
        case .female: String(localized: "Hembra")
        case .male: String(localized: "Macho")
        case .unknown: String(localized: "Sin especificar")
        }
    }
}

struct PetProfile: Codable, Sendable, Equatable, Identifiable {
    var id = UUID()
    var name = ""
    var species = "Perro"
    var breed = ""
    var birthDate: Date?
    var approximateAgeMonths: Int?
    var ageReferenceDate = Date.now
    var sex: PetSex = .unknown
    var currentWeight: Double?
    var healthyWeightRange: WeightRange?
    var microchip: String?
    var primaryVeterinaryClinic: String?
    var photoPath: String?
    var createdAt = Date.now
    var updatedAt = Date.now

    func ageMonths(at date: Date = .now, calendar: Calendar = .current) -> Int? {
        if let birthDate {
            return max(0, calendar.dateComponents([.month], from: birthDate, to: date).month ?? 0)
        }
        guard let approximateAgeMonths else { return nil }
        return max(0, approximateAgeMonths + (calendar.dateComponents([.month], from: ageReferenceDate, to: date).month ?? 0))
    }

    func ageDescription(at date: Date = .now) -> String {
        guard let months = ageMonths(at: date) else { return String(localized: "Edad sin indicar") }
        let years = months / 12
        let remainingMonths = months % 12
        var parts: [String] = []
        if years > 0 {
            parts.append(years == 1 ? String(localized: "1 año") : String(localized: "\(years) años"))
        }
        if remainingMonths > 0 || parts.isEmpty {
            parts.append(remainingMonths == 1 ? String(localized: "1 mes") : String(localized: "\(remainingMonths) meses"))
        }
        let value = parts.joined(separator: String(localized: " y "))
        return birthDate == nil ? String(localized: "Aprox. \(value)") : value
    }
}
