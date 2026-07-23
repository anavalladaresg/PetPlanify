import Charts
import SwiftUI

struct WeightTrendCard: View {
    let entries: [WeightEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            weightChart
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("home.weightTrend")
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Evolución del peso")
                    .font(.headline)
                Text("Últimos seis meses")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
            Spacer()
            Label("Estable", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.green)
        }
    }

    private var weightChart: some View {
        Chart(entries) { entry in
            LineMark(
                x: .value("Mes", entry.month),
                y: .value("Peso", entry.kilograms)
            )
            .foregroundStyle(AppTheme.green)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

            PointMark(
                x: .value("Mes", entry.month),
                y: .value("Peso", entry.kilograms)
            )
            .foregroundStyle(AppTheme.orange)
            .symbolSize(36)
        }
        .chartYScale(domain: 6.4 ... 7.1)
        .frame(height: 180)
        .accessibilityLabel("Evolución del peso de Neo")
        .accessibilityValue("Peso estable; valor actual 6,8 kilogramos")
    }
}
