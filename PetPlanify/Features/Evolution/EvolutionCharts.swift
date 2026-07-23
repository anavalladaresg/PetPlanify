import Charts
import SwiftUI

struct EvolutionWeightChart: View {
    let overview: EvolutionOverview
    let range: EvolutionRange
    let compact: Bool
    @State private var selectedDate: Date?

    private var points: [WeightHistoryPoint] {
        overview.weights(for: range)
    }

    private var selectedPoint: WeightHistoryPoint? {
        nearestPoint(to: selectedDate, in: points)
    }

    var body: some View {
        EvolutionChartCard(
            title: "Evolución del peso",
            subtitle: "Peso registrado y rango saludable de referencia",
            identifier: "evolution.weightChart"
        ) {
            legend

            Chart {
                if let first = points.first, let last = points.last {
                    RectangleMark(
                        xStart: .value("Inicio", first.date),
                        xEnd: .value("Fin", last.date),
                        yStart: .value("Rango inferior", overview.healthyWeightRange.lowerBound),
                        yEnd: .value("Rango superior", overview.healthyWeightRange.upperBound)
                    )
                    .foregroundStyle(AppTheme.greenSoft.opacity(0.45))
                }

                ForEach(points) { point in
                    LineMark(
                        x: .value("Mes", point.date),
                        y: .value("Peso", point.kilograms)
                    )
                    .foregroundStyle(AppTheme.green)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    PointMark(
                        x: .value("Mes", point.date),
                        y: .value("Peso", point.kilograms)
                    )
                    .foregroundStyle(AppTheme.green)
                    .symbolSize(compact ? 30 : 42)
                }

                if let selectedPoint {
                    RuleMark(x: .value("Selección", selectedPoint.date))
                        .foregroundStyle(AppTheme.secondaryInk.opacity(0.45))
                        .annotation(position: .top, spacing: 6) {
                            chartAnnotation(
                                title: EvolutionFormatting.shortMonth(selectedPoint.date),
                                value: EvolutionFormatting.weight(selectedPoint.kilograms)
                            )
                        }
                }
            }
            .chartYScale(domain: 6.4 ... 7.6)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: compact ? 3 : 6)) {
                    AxisGridLine().foregroundStyle(AppTheme.border.opacity(0.55))
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(AppTheme.border.opacity(0.55))
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text(weight.formatted(.number.precision(.fractionLength(1))))
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedDate)
            .frame(height: compact ? 220 : 270)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Evolución del peso de Neo")
            .accessibilityValue(
                "De 7,3 kg en enero a 6,8 kg en junio. Rango saludable registrado: 6,5 a 7,5 kg."
            )
        }
    }

    private var legend: some View {
        HStack(spacing: 18) {
            EvolutionLegendItem(title: "Peso", color: AppTheme.green)
            EvolutionLegendItem(title: "Rango saludable", color: AppTheme.greenSoft)
        }
    }
}

struct EvolutionActivityChart: View {
    let overview: EvolutionOverview
    let range: EvolutionRange
    let compact: Bool
    @State private var selectedDate: Date?

    private var points: [ActivityHistoryPoint] {
        overview.activities(for: range)
    }

    private var selectedPoint: ActivityHistoryPoint? {
        nearestPoint(to: selectedDate, in: points)
    }

    var body: some View {
        EvolutionChartCard(
            title: "Actividad diaria",
            subtitle: "Media de minutos al día",
            identifier: "evolution.activityChart"
        ) {
            Chart {
                ForEach(points) { point in
                    BarMark(
                        x: .value("Mes", point.date),
                        y: .value("Minutos", point.averageMinutesPerDay)
                    )
                    .foregroundStyle(AppTheme.orange.opacity(0.78))
                    .cornerRadius(5)
                }

                if let selectedPoint {
                    RuleMark(x: .value("Selección", selectedPoint.date))
                        .foregroundStyle(AppTheme.secondaryInk.opacity(0.45))
                        .annotation(position: .top, spacing: 6) {
                            chartAnnotation(
                                title: EvolutionFormatting.shortMonth(selectedPoint.date),
                                value: "\(selectedPoint.averageMinutesPerDay) min/día"
                            )
                        }
                }
            }
            .chartYScale(domain: 0 ... 40)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: compact ? 3 : 6)) {
                    AxisGridLine().foregroundStyle(AppTheme.border.opacity(0.55))
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(AppTheme.border.opacity(0.55))
                    AxisValueLabel()
                }
            }
            .chartXSelection(value: $selectedDate)
            .frame(height: compact ? 190 : 220)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Actividad diaria media de Neo")
            .accessibilityValue(
                "La media registrada cambia de 24 minutos al día en enero a 35 minutos al día en junio."
            )
        }
    }
}

struct EvolutionTrainingChart: View {
    let overview: EvolutionOverview
    let range: EvolutionRange
    let compact: Bool
    @State private var selectedDate: Date?

    private var points: [TrainingProgressPoint] {
        overview.training(for: range)
    }

    private var selectedPoint: TrainingProgressPoint? {
        nearestPoint(to: selectedDate, in: points)
    }

    var body: some View {
        EvolutionChartCard(
            title: "Progreso de entrenamiento",
            subtitle: "Trucos dominados por mes",
            identifier: "evolution.trainingChart"
        ) {
            Chart {
                ForEach(points) { point in
                    LineMark(
                        x: .value("Mes", point.date),
                        y: .value("Trucos", point.masteredTricks)
                    )
                    .foregroundStyle(AppTheme.green)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    PointMark(
                        x: .value("Mes", point.date),
                        y: .value("Trucos", point.masteredTricks)
                    )
                    .foregroundStyle(AppTheme.orange)
                    .symbolSize(compact ? 34 : 46)
                }

                if let selectedPoint {
                    RuleMark(x: .value("Selección", selectedPoint.date))
                        .foregroundStyle(AppTheme.secondaryInk.opacity(0.45))
                        .annotation(position: .top, spacing: 6) {
                            chartAnnotation(
                                title: EvolutionFormatting.shortMonth(selectedPoint.date),
                                value: masteredTricksText(selectedPoint.masteredTricks)
                            )
                        }
                }
            }
            .chartYScale(domain: 0 ... 5)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: compact ? 3 : 6)) {
                    AxisGridLine().foregroundStyle(AppTheme.border.opacity(0.55))
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 1, 2, 3, 4, 5]) {
                    AxisGridLine().foregroundStyle(AppTheme.border.opacity(0.55))
                    AxisValueLabel()
                }
            }
            .chartXSelection(value: $selectedDate)
            .frame(height: compact ? 190 : 220)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Progreso de entrenamiento de Neo")
            .accessibilityValue(
                "Los trucos dominados registrados cambian de uno en enero a cuatro en junio."
            )
        }
    }

    private func masteredTricksText(_ count: Int) -> String {
        count == 1
            ? String(localized: "1 truco")
            : String(localized: "\(count) trucos")
    }
}

struct EvolutionChartCard<Content: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let identifier: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
            content
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier(identifier)
    }
}

struct EvolutionLegendItem: View {
    let title: LocalizedStringKey
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
                .overlay(Circle().stroke(AppTheme.border, lineWidth: 0.5))
                .accessibilityHidden(true)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }
}

private func nearestPoint<Point>(
    to selectedDate: Date?,
    in points: [Point],
    date: (Point) -> Date
) -> Point? {
    guard let selectedDate else { return nil }
    return points.min {
        abs(date($0).timeIntervalSince(selectedDate))
            < abs(date($1).timeIntervalSince(selectedDate))
    }
}

private func nearestPoint(
    to selectedDate: Date?,
    in points: [WeightHistoryPoint]
) -> WeightHistoryPoint? {
    nearestPoint(to: selectedDate, in: points, date: \.date)
}

private func nearestPoint(
    to selectedDate: Date?,
    in points: [ActivityHistoryPoint]
) -> ActivityHistoryPoint? {
    nearestPoint(to: selectedDate, in: points, date: \.date)
}

private func nearestPoint(
    to selectedDate: Date?,
    in points: [TrainingProgressPoint]
) -> TrainingProgressPoint? {
    nearestPoint(to: selectedDate, in: points, date: \.date)
}

private func chartAnnotation(title: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(title)
            .font(.caption2)
            .foregroundStyle(AppTheme.secondaryInk)
        Text(value)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.ink)
    }
    .padding(.horizontal, 9)
    .padding(.vertical, 7)
    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 9))
    .overlay(
        RoundedRectangle(cornerRadius: 9)
            .stroke(AppTheme.border, lineWidth: 0.6)
    )
}

#Preview("Evolución · Gráfico de peso") {
    EvolutionWeightChart(
        overview: EvolutionPreviewData.neoOverview,
        range: .sixMonths,
        compact: false
    )
    .padding()
    .frame(width: 760)
    .appCanvas()
}
