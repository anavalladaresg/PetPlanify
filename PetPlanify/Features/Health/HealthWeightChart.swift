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
        CareSection(title: "Peso", style: .compact, symbol: "scalemass") {
            weightSummary
            if records.isEmpty {
                EmptyCareState(title: "Registra un peso para empezar a ver su evolución.", symbol: "scalemass")
            } else {
                chart
                if let first = records.first, let last = records.last {
                    Text("\(records.count) registros · \(AppFormat.date(first.date)) – \(AppFormat.date(last.date))")
                        .font(.caption).foregroundStyle(AppTheme.secondaryInk)
                }
            }
            if let range = store.snapshot.pet.healthyWeightRange {
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(AppTheme.green)
                        .accessibilityHidden(true)
                    Text("Referencia introducida manualmente: \(AppFormat.weight(range.lower, unit: unit)) – \(AppFormat.weight(range.upper, unit: unit)).")
                }
                .font(.caption).foregroundStyle(AppTheme.secondaryInk)
            }
            HealthSectionActions(addTitle: "Registrar peso", onAdd: onRegister, onHistory: onHistory)
        }
        .accessibilityIdentifier("health.weightChart")
    }

    @ViewBuilder private var weightSummary: some View {
        if let weight = selectedRecord?.weight ?? store.currentWeight {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.md) {
                    weightValue(weight)
                    Spacer(minLength: 0)
                    weightDate
                }
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    weightValue(weight)
                    weightDate
                }
            }
        }
    }

    private func weightValue(_ weight: Double) -> some View {
        Text(AppFormat.weight(weight, unit: unit))
            .font(.system(.largeTitle, design: .rounded, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(AppTheme.ink)
            .contentTransition(.numericText())
            .accessibilityLabel(selectedRecord == nil
                ? String(localized: "Peso actual, \(AppFormat.weight(weight, unit: unit))")
                : AppFormat.weight(weight, unit: unit))
    }

    @ViewBuilder private var weightDate: some View {
        if let date = selectedRecord?.date ?? records.last?.date {
            Text(AppFormat.date(date))
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .accessibilityAddTraits(.updatesFrequently)
        }
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
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                PointMark(x: .value("Fecha", record.date), y: .value("Peso", unit.fromKilograms(record.weight)))
                    .foregroundStyle(AppTheme.green)
                    .symbolSize(records.count <= 12 || record.id == records.last?.id ? 24 : 8)
                    .accessibilityLabel(AppFormat.date(record.date))
                    .accessibilityValue(AppFormat.weight(record.weight, unit: unit))
            }
            if let selectedRecord {
                RuleMark(x: .value("Fecha seleccionada", selectedRecord.date))
                    .foregroundStyle(AppTheme.green.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    .accessibilityHidden(true)
                PointMark(x: .value("Fecha", selectedRecord.date), y: .value("Peso", unit.fromKilograms(selectedRecord.weight)))
                    .symbolSize(120)
                    .foregroundStyle(AppTheme.surface)
                    .accessibilityHidden(true)
                PointMark(x: .value("Fecha", selectedRecord.date), y: .value("Peso", unit.fromKilograms(selectedRecord.weight)))
                    .symbolSize(56)
                    .foregroundStyle(AppTheme.green)
                    .accessibilityHidden(true)
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartXScale(range: .plotDimension(padding: 8))
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                    .foregroundStyle(AppTheme.border.opacity(0.55))
                AxisValueLabel().font(.caption2).foregroundStyle(AppTheme.secondaryInk)
            }
        }
        #if os(macOS)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Color.clear
                    .onContinuousHover { phase in
                        switch phase {
                        case let .active(location):
                            guard let plotFrame = proxy.plotFrame else { return }
                            let frame = geometry[plotFrame]
                            selectedDate = frame.contains(location)
                                ? proxy.value(atX: location.x - frame.minX, as: Date.self)
                                : nil
                        case .ended:
                            selectedDate = nil
                        }
                    }
            }
        }
        #endif
        .frame(height: 180)
        .padding(.top, AppTheme.Space.xs)
        .accessibilityLabel("Evolución del peso")
        .accessibilityHint("Consulta cada registro o abre el historial para ver todas las fechas y pesos")
    }
}
