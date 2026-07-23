import SwiftUI

struct EvolutionMacView: View {
    let overview: EvolutionOverview
    @Binding var selectedSection: EvolutionSection
    @Binding var selectedRange: EvolutionRange
    @Binding var selectedCategory: EvolutionMilestoneFilter
    let onSelectMilestone: (EvolutionMilestone) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                EvolutionHeader(
                    includesTitle: true,
                    selectedRange: $selectedRange
                )
                EvolutionSectionSelector(selection: $selectedSection)
                    .frame(maxWidth: 720)

                EvolutionSectionContent(
                    section: selectedSection,
                    overview: overview,
                    selectedRange: selectedRange,
                    selectedCategory: $selectedCategory,
                    compact: false,
                    onSelectMilestone: onSelectMilestone
                )
            }
            .frame(maxWidth: 1_180, alignment: .leading)
            .padding(32)
        }
        .appCanvas()
        .accessibilityIdentifier("evolution.screen")
    }
}

struct EvolutionPhoneView: View {
    let overview: EvolutionOverview
    @Binding var selectedSection: EvolutionSection
    @Binding var selectedRange: EvolutionRange
    @Binding var selectedCategory: EvolutionMilestoneFilter
    let onSelectMilestone: (EvolutionMilestone) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                EvolutionHeader(
                    includesTitle: false,
                    selectedRange: $selectedRange
                )
                EvolutionSectionSelector(selection: $selectedSection)

                EvolutionSectionContent(
                    section: selectedSection,
                    overview: overview,
                    selectedRange: selectedRange,
                    selectedCategory: $selectedCategory,
                    compact: true,
                    onSelectMilestone: onSelectMilestone
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .appCanvas()
        .accessibilityIdentifier("evolution.screen")
    }
}

private struct EvolutionHeader: View {
    let includesTitle: Bool
    @Binding var selectedRange: EvolutionRange

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 24) {
                titleBlock
                Spacer(minLength: 16)
                EvolutionRangePicker(selection: $selectedRange)
            }

            VStack(alignment: .leading, spacing: 14) {
                titleBlock
                EvolutionRangePicker(selection: $selectedRange)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            if includesTitle {
                Text("Evolución")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("Una mirada serena a los cambios registrados de Neo.")
                .font(includesTitle ? .title3 : .subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct EvolutionSectionContent: View {
    let section: EvolutionSection
    let overview: EvolutionOverview
    let selectedRange: EvolutionRange
    @Binding var selectedCategory: EvolutionMilestoneFilter
    let compact: Bool
    let onSelectMilestone: (EvolutionMilestone) -> Void

    @ViewBuilder
    var body: some View {
        switch section {
        case .summary:
            EvolutionSummarySection(
                overview: overview,
                selectedRange: selectedRange,
                compact: compact,
                onSelectMilestone: onSelectMilestone
            )
        case .weight:
            EvolutionWeightSection(
                overview: overview,
                selectedRange: selectedRange,
                compact: compact
            )
        case .activity:
            EvolutionActivitySection(
                overview: overview,
                selectedRange: selectedRange,
                compact: compact,
                onSelectMilestone: onSelectMilestone
            )
        case .milestones:
            EvolutionMilestonesSection(
                overview: overview,
                selectedCategory: $selectedCategory,
                onSelectMilestone: onSelectMilestone
            )
        }
    }
}

private struct EvolutionSummarySection: View {
    let overview: EvolutionOverview
    let selectedRange: EvolutionRange
    let compact: Bool
    let onSelectMilestone: (EvolutionMilestone) -> Void

    var body: some View {
        VStack(spacing: compact ? 16 : 18) {
            EvolutionSummaryGrid(overview: overview, compact: compact)

            if compact {
                VStack(spacing: 16) {
                    weightChart
                    activityChart
                    trainingChart
                    milestones
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        weightChart
                            .frame(minWidth: 620)
                        VStack(spacing: 18) {
                            activityChart
                            trainingChart
                        }
                        .frame(minWidth: 360)
                    }

                    VStack(spacing: 18) {
                        weightChart
                        activityChart
                        trainingChart
                    }
                }
                milestones
            }
        }
    }

    private var weightChart: some View {
        EvolutionWeightChart(
            overview: overview,
            range: selectedRange,
            compact: compact
        )
    }

    private var activityChart: some View {
        EvolutionActivityChart(
            overview: overview,
            range: selectedRange,
            compact: compact
        )
    }

    private var trainingChart: some View {
        EvolutionTrainingChart(
            overview: overview,
            range: selectedRange,
            compact: compact
        )
    }

    private var milestones: some View {
        EvolutionMilestonesCard(
            milestones: overview.milestones,
            limit: 3,
            onSelect: onSelectMilestone
        )
    }
}

private struct EvolutionWeightSection: View {
    let overview: EvolutionOverview
    let selectedRange: EvolutionRange
    let compact: Bool

    var body: some View {
        VStack(spacing: 18) {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 12),
                    count: compact ? 1 : 3
                ),
                spacing: 12
            ) {
                EvolutionMetricCard(
                    title: "Peso actual",
                    value: EvolutionFormatting.weight(overview.currentWeight),
                    detail: "Último registro manual",
                    symbol: "scalemass",
                    accent: AppTheme.green
                )
                EvolutionMetricCard(
                    title: "Rango saludable",
                    value: EvolutionFormatting.weightRange(overview.healthyWeightRange),
                    detail: "Referencia registrada",
                    symbol: "arrow.up.and.down",
                    accent: AppTheme.green
                )
                EvolutionMetricCard(
                    title: "Diferencia del periodo",
                    value: EvolutionFormatting.signedWeight(
                        overview.weightChangeFromPreviousRecord
                    ),
                    detail: "Desde el registro anterior",
                    symbol: "arrow.left.and.right",
                    accent: AppTheme.orange
                )
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    EvolutionWeightChart(
                        overview: overview,
                        range: selectedRange,
                        compact: false
                    )
                    .frame(minWidth: 620)
                    WeightRecordsCard(points: overview.weights(for: selectedRange))
                        .frame(minWidth: 330)
                }
                VStack(spacing: 18) {
                    EvolutionWeightChart(
                        overview: overview,
                        range: selectedRange,
                        compact: compact
                    )
                    WeightRecordsCard(points: overview.weights(for: selectedRange))
                }
            }

            Label("Datos registrados manualmente", systemImage: "hand.draw")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.green)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("El peso es un registro de seguimiento y no sustituye la valoración veterinaria.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct EvolutionActivitySection: View {
    let overview: EvolutionOverview
    let selectedRange: EvolutionRange
    let compact: Bool
    let onSelectMilestone: (EvolutionMilestone) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var activityMilestones: [EvolutionMilestone] {
        overview.milestones(filteredBy: .activity)
    }

    var body: some View {
        VStack(spacing: 18) {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 12),
                    count: compact && dynamicTypeSize.isAccessibilitySize ? 1 : compact ? 2 : 4
                ),
                spacing: 12
            ) {
                EvolutionMetricCard(
                    title: "Actividad media",
                    value: "\(overview.currentActivity) min/día",
                    detail: "Media de junio",
                    symbol: "figure.walk",
                    accent: AppTheme.orange
                )
                EvolutionMetricCard(
                    title: "Mes más activo",
                    value: overview.mostActivePoint.map {
                        EvolutionFormatting.shortMonth($0.date)
                    } ?? "—",
                    detail: "Según datos registrados",
                    symbol: "calendar",
                    accent: AppTheme.green
                )
                EvolutionMetricCard(
                    title: "Paseos este mes",
                    value: "\(overview.walkingMinutesThisMonth) min",
                    detail: "Suma de ejemplo",
                    symbol: "pawprint",
                    accent: AppTheme.green
                )
                EvolutionMetricCard(
                    title: "Entrenamiento este mes",
                    value: "\(overview.trainingMinutesThisMonth) min",
                    detail: "Suma de ejemplo",
                    symbol: "stopwatch",
                    accent: AppTheme.orange
                )
            }

            EvolutionActivityChart(
                overview: overview,
                range: selectedRange,
                compact: compact
            )

            EvolutionMilestonesCard(
                milestones: activityMilestones,
                onSelect: onSelectMilestone
            )

            Text("La actividad mostrada es un registro descriptivo y no establece una cantidad ideal.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct EvolutionMilestonesSection: View {
    let overview: EvolutionOverview
    @Binding var selectedCategory: EvolutionMilestoneFilter
    let onSelectMilestone: (EvolutionMilestone) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            EvolutionMilestoneFilterPicker(selection: $selectedCategory)
            EvolutionMilestonesCard(
                milestones: overview.milestones(filteredBy: selectedCategory),
                onSelect: onSelectMilestone
            )
        }
    }
}

#Preview("Evolución · macOS") {
    EvolutionMacView(
        overview: EvolutionPreviewData.neoOverview,
        selectedSection: .constant(.summary),
        selectedRange: .constant(.sixMonths),
        selectedCategory: .constant(.all),
        onSelectMilestone: { _ in }
    )
    .frame(width: 1_180, height: 900)
}

#Preview("Evolución · iPhone") {
    NavigationStack {
        EvolutionPhoneView(
            overview: EvolutionPreviewData.neoOverview,
            selectedSection: .constant(.summary),
            selectedRange: .constant(.sixMonths),
            selectedCategory: .constant(.all),
            onSelectMilestone: { _ in }
        )
        .navigationTitle("Evolución")
    }
    .frame(width: 393, height: 852)
}

#Preview("Evolución · Peso") {
    ScrollView {
        EvolutionSectionContent(
            section: .weight,
            overview: EvolutionPreviewData.neoOverview,
            selectedRange: .sixMonths,
            selectedCategory: .constant(.all),
            compact: true,
            onSelectMilestone: { _ in }
        )
        .padding()
    }
    .frame(width: 430, height: 850)
    .appCanvas()
}

#Preview("Evolución · Hitos") {
    ScrollView {
        EvolutionSectionContent(
            section: .milestones,
            overview: EvolutionPreviewData.neoOverview,
            selectedRange: .sixMonths,
            selectedCategory: .constant(.all),
            compact: true,
            onSelectMilestone: { _ in }
        )
        .padding()
    }
    .frame(width: 430, height: 850)
    .appCanvas()
}
