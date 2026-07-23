import SwiftUI

struct EvolutionSectionSelector: View {
    @Binding var selection: EvolutionSection

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(EvolutionSection.allCases) { section in
                    Button {
                        selection = section
                    } label: {
                        Text(section.title)
                            .font(.subheadline.weight(selection == section ? .semibold : .regular))
                            .foregroundStyle(selection == section ? AppTheme.ink : AppTheme.secondaryInk)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 40)
                            .background(
                                Capsule()
                                    .fill(selection == section ? AppTheme.surfaceMuted : .clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == section ? .isSelected : [])
                    .accessibilityIdentifier("evolution.section.\(section.rawValue)")
                }
            }
            .padding(4)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.surface.opacity(0.66), in: Capsule())
        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 0.75))
        .accessibilityIdentifier("evolution.sectionPicker")
    }
}

struct EvolutionRangePicker: View {
    @Binding var selection: EvolutionRange

    var body: some View {
        Picker("Periodo de evolución", selection: $selection) {
            ForEach(EvolutionRange.allCases) { range in
                Text(range.rawValue)
                    .tag(range)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 360)
        .accessibilityHint("Cambia el periodo mostrado en los gráficos")
        .accessibilityIdentifier("evolution.rangePicker")
    }
}

struct EvolutionSummaryGrid: View {
    let overview: EvolutionOverview
    let compact: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 12),
            count: compact && dynamicTypeSize.isAccessibilitySize ? 1 : compact ? 2 : 4
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            EvolutionMetricCard(
                title: "Peso actual",
                value: EvolutionFormatting.weight(overview.currentWeight),
                detail: "Último registro",
                symbol: "scalemass",
                accent: AppTheme.green
            )
            EvolutionMetricCard(
                title: "Cambio en 6 meses",
                value: EvolutionFormatting.signedWeight(overview.sixMonthWeightChange),
                detail: "Sin valoración asociada",
                symbol: "arrow.left.and.right",
                accent: AppTheme.orange
            )
            EvolutionMetricCard(
                title: "Actividad media",
                value: "\(overview.currentActivity) min/día",
                detail: "Registro de junio",
                symbol: "figure.walk",
                accent: AppTheme.orange
            )
            EvolutionMetricCard(
                title: "Trucos dominados",
                value: overview.masteredTricks.formatted(),
                detail: "Progreso registrado",
                symbol: "checkmark.seal",
                accent: AppTheme.green
            )
        }
        .accessibilityIdentifier("evolution.summary")
    }
}

struct EvolutionMetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let detail: LocalizedStringKey
    let symbol: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 32, height: 32)
                .background(accent.opacity(0.11), in: Circle())
                .accessibilityHidden(true)

            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .minimumScaleFactor(0.78)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.ink)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
        .padding(16)
        .appSurface(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }
}

struct EvolutionMilestonesCard: View {
    let milestones: [EvolutionMilestone]
    var limit: Int?
    let onSelect: (EvolutionMilestone) -> Void

    private var displayedMilestones: [EvolutionMilestone] {
        if let limit {
            Array(milestones.prefix(limit))
        } else {
            milestones
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            EvolutionCardHeader(title: "Hitos recientes", symbol: "flag")
                .padding(.bottom, 6)

            if displayedMilestones.isEmpty {
                Text("No hay hitos en esta categoría.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .frame(maxWidth: .infinity, minHeight: 90)
            } else {
                ForEach(Array(displayedMilestones.enumerated()), id: \.element.id) { index, milestone in
                    EvolutionMilestoneRow(
                        milestone: milestone,
                        isLast: index == displayedMilestones.count - 1,
                        onSelect: { onSelect(milestone) }
                    )
                }
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("evolution.milestones")
    }
}

struct EvolutionMilestoneRow: View {
    let milestone: EvolutionMilestone
    let isLast: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 14) {
                timeline

                VStack(alignment: .leading, spacing: 5) {
                    Text(EvolutionFormatting.date(milestone.date))
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                    Text(milestone.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(milestone.description)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 7) {
                        Text(milestone.category.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(categoryAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(categoryAccent.opacity(0.11), in: Capsule())
                        Text(milestone.context)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryInk)
                    }
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(EvolutionFormatting.date(milestone.date)), \(milestone.title), categoría \(milestone.category.title), \(milestone.context)"
        )
        .accessibilityHint("Abre el detalle del hito")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            onSelect()
        }
    }

    private var timeline: some View {
        VStack(spacing: 0) {
            Image(systemName: milestone.category.symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(categoryAccent)
                .frame(width: 30, height: 30)
                .background(categoryAccent.opacity(0.11), in: Circle())

            if !isLast {
                Rectangle()
                    .fill(AppTheme.border)
                    .frame(width: 1.5)
                    .frame(minHeight: 72)
            }
        }
        .accessibilityHidden(true)
    }

    private var categoryAccent: Color {
        switch milestone.category {
        case .weight, .health, .training: AppTheme.green
        case .nutrition, .activity: AppTheme.orange
        }
    }
}

struct EvolutionMilestoneFilterPicker: View {
    @Binding var selection: EvolutionMilestoneFilter

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 7) {
                ForEach(EvolutionMilestoneFilter.allCases) { filter in
                    Button {
                        selection = filter
                    } label: {
                        Text(filter.title)
                            .font(.caption.weight(selection == filter ? .semibold : .regular))
                            .foregroundStyle(selection == filter ? AppTheme.ink : AppTheme.secondaryInk)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 38)
                            .background(
                                Capsule()
                                    .fill(selection == filter ? AppTheme.greenSoft.opacity(0.72) : AppTheme.surface)
                            )
                            .overlay(Capsule().stroke(AppTheme.border, lineWidth: 0.65))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == filter ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
        .accessibilityLabel("Filtrar hitos")
        .accessibilityHint("Muestra hitos de una categoría")
        .accessibilityIdentifier("evolution.milestoneFilter")
    }
}

struct WeightRecordsCard: View {
    let points: [WeightHistoryPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            EvolutionCardHeader(title: "Registros mensuales", symbol: "list.bullet")
                .padding(.bottom, 6)

            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                HStack {
                    Text(EvolutionFormatting.month(point.date))
                        .font(.subheadline)
                    Spacer()
                    Text(EvolutionFormatting.weight(point.kilograms))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                    if index > 0 {
                        Text(
                            EvolutionFormatting.signedWeight(
                                point.kilograms - points[index - 1].kilograms
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .frame(width: 64, alignment: .trailing)
                    }
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)

                if point.id != points.last?.id {
                    Divider().overlay(AppTheme.border)
                }
            }
        }
        .padding(20)
        .appSurface()
    }
}

struct EvolutionCardHeader: View {
    let title: LocalizedStringKey
    let symbol: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(.title3, design: .serif, weight: .semibold))
            Spacer(minLength: 0)
        }
    }
}
