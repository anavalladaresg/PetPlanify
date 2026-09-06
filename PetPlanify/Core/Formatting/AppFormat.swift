import Foundation

enum AppFormat {
    static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }
    static func weight(_ kg: Double, unit: WeightUnit) -> String {
        "\(number(unit.fromKilograms(kg))) \(unit.symbol)"
    }
    static func grams(_ value: Double) -> String { "\(number(value)) g" }
    static func date(_ date: Date) -> String { date.formatted(date: .abbreviated, time: .omitted) }
    static func dateTime(_ date: Date) -> String { date.formatted(date: .abbreviated, time: .shortened) }
    static func parseNumber(_ input: String) -> Double? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.range(of: #"^[0-9]+([.,][0-9]+)?$"#, options: .regularExpression) != nil,
              let value = Double(text.replacingOccurrences(of: ",", with: ".")), value.isFinite else { return nil }
        return value
    }
    static func validWeight(_ kg: Double) -> Bool { kg.isFinite && (0.01...1_000).contains(kg) }
}
