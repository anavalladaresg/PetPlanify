import SwiftUI

struct EvolutionRangePicker: View {
    @Binding var selection: EvolutionRange

    var body: some View {
        Picker("Periodo de evolución", selection: $selection) {
            ForEach(EvolutionRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 340)
        .accessibilityHint("Cambia el periodo mostrado en el gráfico")
        .accessibilityIdentifier("evolution.rangePicker")
    }
}

struct EvolutionMilestonesCard: View {
    let milestones: [EvolutionMilestone]
    var limit: Int?
    let onSelect: (EvolutionMilestone) -> Void

    private var displayedMilestones: [EvolutionMilestone] {
        limit.map { Array(milestones.prefix($0)) } ?? milestones
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            EvolutionCardHeader(title: "Hitos recientes", symbol: "flag")
                .padding(.bottom, 5)

            ForEach(Array(displayedMilestones.enumerated()), id: \.element.id) { index, milestone in
                Button {
                    onSelect(milestone)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: milestone.category.symbol)
                            .foregroundStyle(index.isMultiple(of: 2) ? AppTheme.green : AppTheme.orange)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(milestone.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                            Text("\(EvolutionFormatting.date(milestone.date)) · \(milestone.category.title)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryInk)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryInk)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(EvolutionFormatting.date(milestone.date)), \(milestone.title), \(milestone.category.title)")
                if milestone.id != displayedMilestones.last?.id {
                    Divider().overlay(AppTheme.border)
                }
            }
        }
        .padding(18)
        .appSurface()
        .accessibilityIdentifier("evolution.milestones")
    }
}

struct EvolutionCardHeader: View {
    let title: LocalizedStringKey
    let symbol: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(.title3, design: .serif, weight: .semibold))
            Spacer()
        }
    }
}
