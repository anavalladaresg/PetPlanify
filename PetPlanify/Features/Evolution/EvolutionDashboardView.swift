import SwiftUI

struct EvolutionMacView: View {
    let overview: EvolutionOverview
    @Binding var selectedMetric: EvolutionMetric
    @Binding var selectedRange: EvolutionRange
    let onSelectMilestone: (EvolutionMilestone) -> Void

    var body: some View {
        EvolutionDashboardContent(
            overview: overview,
            selectedMetric: $selectedMetric,
            selectedRange: $selectedRange,
            includesTitle: true,
            compact: false,
            onSelectMilestone: onSelectMilestone
        )
    }
}

struct EvolutionPhoneView: View {
    let overview: EvolutionOverview
    @Binding var selectedMetric: EvolutionMetric
    @Binding var selectedRange: EvolutionRange
    let onSelectMilestone: (EvolutionMilestone) -> Void

    var body: some View {
        EvolutionDashboardContent(
            overview: overview,
            selectedMetric: $selectedMetric,
            selectedRange: $selectedRange,
            includesTitle: false,
            compact: true,
            onSelectMilestone: onSelectMilestone
        )
    }
}

private struct EvolutionDashboardContent: View {
    let overview: EvolutionOverview
    @Binding var selectedMetric: EvolutionMetric
    @Binding var selectedRange: EvolutionRange
    let includesTitle: Bool
    let compact: Bool
    let onSelectMilestone: (EvolutionMilestone) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: compact ? 16 : 20) {
                header
                controls
                summary
                    .accessibilityIdentifier("evolution.summary")
                selectedChart
                EvolutionMilestonesCard(
                    milestones: overview.milestones,
                    limit: 3,
                    onSelect: onSelectMilestone
                )
            }
            .frame(maxWidth: 1_080, alignment: .leading)
            .padding(compact ? 18 : 28)
        }
        .appCanvas()
        .accessibilityIdentifier("evolution.screen")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            if includesTitle {
                Text("Evolución")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("Una tendencia cada vez, con el contexto necesario")
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private var controls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) {
                metricPicker
                Spacer()
                EvolutionRangePicker(selection: $selectedRange)
            }
            VStack(alignment: .leading, spacing: 12) {
                metricPicker
                EvolutionRangePicker(selection: $selectedRange)
            }
        }
    }

    private var metricPicker: some View {
        Picker("Métrica", selection: $selectedMetric) {
            ForEach(EvolutionMetric.allCases) { metric in
                Text(metric.title).tag(metric)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 430)
        .accessibilityIdentifier("evolution.metricPicker")
    }

    private var summary: some View {
        HStack(spacing: 0) {
            summaryItem("Peso actual", EvolutionFormatting.weight(overview.currentWeight))
            Divider().frame(height: 36)
            summaryItem("Actividad", "\(overview.currentActivity) min/día")
            Divider().frame(height: 36)
            summaryItem("Trucos dominados", overview.masteredTricks.formatted())
        }
        .padding(14)
        .appSurface(cornerRadius: 16)
    }

    private func summaryItem(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(AppTheme.secondaryInk)
            Text(value).font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var selectedChart: some View {
        switch selectedMetric {
        case .weight:
            EvolutionWeightChart(overview: overview, range: selectedRange, compact: compact)
        case .activity:
            EvolutionActivityChart(overview: overview, range: selectedRange, compact: compact)
        case .training:
            EvolutionTrainingChart(overview: overview, range: selectedRange, compact: compact)
        }
    }
}

#Preview("Evolución · macOS") {
    EvolutionMacView(
        overview: EvolutionPreviewData.neoOverview,
        selectedMetric: .constant(.weight),
        selectedRange: .constant(.sixMonths),
        onSelectMilestone: { _ in }
    )
    .frame(width: 1_100, height: 820)
}

#Preview("Evolución · iPhone") {
    NavigationStack {
        EvolutionPhoneView(
            overview: EvolutionPreviewData.neoOverview,
            selectedMetric: .constant(.activity),
            selectedRange: .constant(.sixMonths),
            onSelectMilestone: { _ in }
        )
    }
    .frame(width: 393, height: 852)
}
