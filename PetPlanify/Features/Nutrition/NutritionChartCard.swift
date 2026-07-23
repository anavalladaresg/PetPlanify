import Charts
import SwiftUI

struct NutritionChartCard: View {
    let plan: FoodPlan
    @Binding var selectedRange: NutritionChartRange
    let compact: Bool

    private var points: [NutritionHistoryPoint] {
        plan.history(for: selectedRange)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            rangePicker
            legend

            VStack(spacing: 14) {
                weightChart
                foodAmountChart
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Relación entre peso y alimentación de Neo")
            .accessibilityValue(
                "Muestra el peso en kilogramos y la cantidad diaria de alimento en gramos durante el periodo seleccionado"
            )
        }
        .padding(compact ? 18 : 20)
        .appSurface()
        .accessibilityIdentifier("nutrition.chart")
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 18) {
                chartTitle
                Spacer(minLength: 12)
                weightSummary
            }
            VStack(alignment: .leading, spacing: 12) {
                chartTitle
                weightSummary
            }
        }
    }

    private var chartTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Relación entre peso y alimentación")
                .font(.headline)
            Text("Seguimiento local con datos de ejemplo")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private var weightSummary: some View {
        HStack(spacing: 16) {
            summaryValue(
                title: "Peso actual",
                value: NutritionFormatting.weight(plan.currentWeightKilograms)
            )
            summaryValue(
                title: "Rango saludable",
                value: NutritionFormatting.weightRange(plan.healthyWeightRange)
            )
        }
    }

    private func summaryValue(title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }

    private var rangePicker: some View {
        Picker("Periodo del gráfico", selection: $selectedRange) {
            ForEach(NutritionChartRange.allCases) { range in
                Text(range.rawValue)
                    .tag(range)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: compact ? .infinity : 360)
        .accessibilityIdentifier("nutrition.chartRange")
    }

    private var legend: some View {
        HStack(spacing: compact ? 14 : 22) {
            legendItem(title: "Peso (kg)", color: AppTheme.green)
            legendItem(title: "Alimento diario (g)", color: AppTheme.orange)
        }
        .font(.caption)
        .foregroundStyle(AppTheme.secondaryInk)
    }

    private func legendItem(title: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(title)
        }
    }

    private var weightChart: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Fecha", point.date),
                y: .value("Peso", point.weightKilograms)
            )
            .foregroundStyle(AppTheme.green)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            PointMark(
                x: .value("Fecha", point.date),
                y: .value("Peso", point.weightKilograms)
            )
            .foregroundStyle(AppTheme.green)
            .symbolSize(compact ? 26 : 34)
        }
        .chartYScale(domain: 6.4 ... 7.2)
        .chartXAxis(.hidden)
        .frame(height: compact ? 104 : 122)
    }

    private var foodAmountChart: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Fecha", point.date),
                y: .value("Alimento", point.dailyFoodGrams)
            )
            .foregroundStyle(AppTheme.orange)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            PointMark(
                x: .value("Fecha", point.date),
                y: .value("Alimento", point.dailyFoodGrams)
            )
            .foregroundStyle(AppTheme.orange)
            .symbolSize(compact ? 26 : 34)
        }
        .chartYScale(domain: 190 ... 260)
        .frame(height: compact ? 112 : 128)
    }
}
