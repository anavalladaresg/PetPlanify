import Charts
import SwiftUI

struct HealthWeightCard: View {
    @Environment(PetPlanifyStore.self) private var store
    let onRegister: () -> Void
    let onHistory: () -> Void
    @State private var selectedDate: Date?

    private var records: [WeightRecord] { store.snapshot.health.weights.sorted { $0.date < $1.date } }
    private var unit: WeightUnit { store.snapshot.preferences.weightUnit }
    private var selectedRecord: WeightRecord? {
        guard let selectedDate else { return nil }
        return records.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }
    private var yDomain: ClosedRange<Double> {
        var values = records.map { unit.fromKilograms($0.weight) }
        if let range = store.snapshot.pet.healthyWeightRange {
            values += [unit.fromKilograms(range.lower), unit.fromKilograms(range.upper)]
        }
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 1
        let padding = max((maximum - minimum) * 0.2, maximum * 0.04, 0.1)
        return max(0, minimum - padding)...(maximum + padding)
    }

    var body: some View {
        CareSection(title: "Evolución del peso") {
            if let weight = store.currentWeight {
                Text(AppFormat.weight(weight, unit: unit))
                    .font(.title2.weight(.semibold))
                    .accessibilityLabel("Peso actual, \(AppFormat.weight(weight, unit: unit))")
            }
            if records.isEmpty {
                Text("Registra un peso para empezar a ver su evolución.")
                    .foregroundStyle(AppTheme.secondaryInk)
            } else {
                chart
                if let selectedRecord {
                    Text("\(AppFormat.date(selectedRecord.date)): \(AppFormat.weight(selectedRecord.weight, unit: unit))")
                        .font(.subheadline.weight(.medium))
                        .accessibilityAddTraits(.updatesFrequently)
                }
                if let first = records.first, let last = records.last {
                    Text("\(records.count) registros · \(AppFormat.date(first.date)) – \(AppFormat.date(last.date))")
                        .font(.caption).foregroundStyle(AppTheme.secondaryInk)
                }
            }
            if let range = store.snapshot.pet.healthyWeightRange {
                Text("Referencia introducida manualmente: \(AppFormat.weight(range.lower, unit: unit)) – \(AppFormat.weight(range.upper, unit: unit)).")
                    .font(.caption).foregroundStyle(AppTheme.secondaryInk)
            }
            HealthSectionActions(addTitle: "Registrar peso", onAdd: onRegister, onHistory: onHistory)
        }
        .accessibilityIdentifier("health.weightChart")
    }

    private var chart: some View {
        Chart {
            if let range = store.snapshot.pet.healthyWeightRange,
               let first = records.first, let last = records.last {
                RectangleMark(
                    xStart: .value("Inicio", first.date.addingTimeInterval(-43_200)),
                    xEnd: .value("Fin", last.date.addingTimeInterval(43_200)),
                    yStart: .value("Referencia inferior", unit.fromKilograms(range.lower)),
                    yEnd: .value("Referencia superior", unit.fromKilograms(range.upper))
                )
                .foregroundStyle(AppTheme.greenSoft.opacity(0.45))
                .accessibilityHidden(true)
            }
            ForEach(records) { record in
                LineMark(x: .value("Fecha", record.date), y: .value("Peso", unit.fromKilograms(record.weight)))
                    .foregroundStyle(AppTheme.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                PointMark(x: .value("Fecha", record.date), y: .value("Peso", unit.fromKilograms(record.weight)))
                    .foregroundStyle(AppTheme.green)
                    .accessibilityLabel(AppFormat.date(record.date))
                    .accessibilityValue(AppFormat.weight(record.weight, unit: unit))
            }
            if let selectedRecord {
                RuleMark(x: .value("Fecha seleccionada", selectedRecord.date))
                    .foregroundStyle(AppTheme.secondaryInk.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .accessibilityHidden(true)
                PointMark(x: .value("Fecha", selectedRecord.date), y: .value("Peso", unit.fromKilograms(selectedRecord.weight)))
                    .symbolSize(90)
                    .foregroundStyle(AppTheme.green)
                    .accessibilityHidden(true)
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine().foregroundStyle(AppTheme.border)
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(AppTheme.border)
                AxisValueLabel()
            }
        }
        .frame(height: 180)
        .accessibilityLabel("Evolución del peso")
        .accessibilityHint("Consulta cada registro o abre el historial para ver todas las fechas y pesos")
    }
}
