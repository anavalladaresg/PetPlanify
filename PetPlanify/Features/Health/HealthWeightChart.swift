import Charts
import SwiftUI

struct HealthWeightCard: View {
    let overview: HealthOverview
    let compact: Bool
    let onRegister: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    title
                    Spacer()
                    registerButton
                }
                VStack(alignment: .leading, spacing: 10) {
                    title
                    registerButton
                }
            }

            HStack(spacing: 22) {
                metric("Peso actual", HealthFormatting.weight(overview.currentWeight))
                if let range = overview.healthyWeightRange {
                    metric("Rango orientativo", HealthFormatting.weightRange(range))
                }
            }

            Chart {
                if let range = overview.healthyWeightRange,
                   let first = overview.weightRecords.first,
                   let last = overview.weightRecords.last {
                    RectangleMark(
                        xStart: .value("Inicio", first.date),
                        xEnd: .value("Fin", last.date),
                        yStart: .value("Rango inferior", range.lowerBound),
                        yEnd: .value("Rango superior", range.upperBound)
                    )
                    .foregroundStyle(AppTheme.greenSoft.opacity(0.42))
                }
                ForEach(overview.weightRecords) { record in
                    LineMark(x: .value("Mes", record.date), y: .value("Peso", record.kilograms))
                        .foregroundStyle(AppTheme.green)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    PointMark(x: .value("Mes", record.date), y: .value("Peso", record.kilograms))
                        .foregroundStyle(AppTheme.green)
                }
            }
            .chartYScale(domain: 6.4 ... 7.6)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: compact ? 3 : 6)) {
                    AxisGridLine().foregroundStyle(AppTheme.border)
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(AppTheme.border)
                    AxisValueLabel()
                }
            }
            .frame(height: compact ? 200 : 250)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Evolución del peso de Neo")
            .accessibilityValue("De 7,3 kg en enero a 6,8 kg en junio. El rango mostrado fue introducido manualmente.")

            Text("El rango saludable es una referencia introducida manualmente y no sustituye la valoración veterinaria.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .padding(18)
        .appSurface()
        .accessibilityIdentifier("health.weightChart")
    }

    private var title: some View {
        Label("Evolución del peso", systemImage: "chart.line.uptrend.xyaxis")
            .font(.system(.title3, design: .serif, weight: .semibold))
    }

    private var registerButton: some View {
        Button(action: onRegister) {
            Label("Registrar peso", systemImage: "plus")
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("health.registerWeight")
    }

    private func metric(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(AppTheme.secondaryInk)
            Text(value).font(.headline)
        }
        .accessibilityElement(children: .combine)
    }
}
