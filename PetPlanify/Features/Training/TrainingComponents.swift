import SwiftUI

struct TrickIllustration: View {
    let definition: TrickDefinition
    var width: CGFloat = 100
    var height: CGFloat = 88

    private var pose: DogPoseIllustration.Pose {
        switch definition.id {
        case "sentado", "mirame": .sitting
        case "tumba", "a-tu-sitio": .lying
        case "pata", "saluda": .offeringPaw
        case "ven-aqui", "junto", "trae": .coming
        default: .standing
        }
    }

    private var hasDedicatedPose: Bool {
        ["sentado", "tumba", "quieto", "pata", "ven-aqui"].contains(definition.id)
    }

    var body: some View {
        Group {
            if let asset = definition.illustrationAssetName {
                Image(asset).resizable().scaledToFit()
            } else {
                DogPoseIllustration(pose: pose)
                    .overlay(alignment: .topTrailing) {
                        if !hasDedicatedPose {
                            Image(systemName: definition.iconIdentifier)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.green)
                                .padding(5)
                                .background(AppTheme.surface, in: Circle())
                        }
                    }
            }
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

/// One or two balanced columns, with a single readable column for accessibility text sizes.
struct TrainingTileLayout: Layout {
    var singleColumn = false
    var spacing: CGFloat = AppTheme.Space.md

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 600
        let rows = rowHeights(width: width, subviews: subviews)
        return CGSize(width: width, height: rows.reduce(0, +) + CGFloat(max(0, rows.count - 1)) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columns = columnCount(width: bounds.width)
        let cellWidth = (bounds.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
        let rows = rowHeights(width: bounds.width, subviews: subviews)
        var y = bounds.minY
        for (index, subview) in subviews.enumerated() {
            let row = index / columns
            let column = index % columns
            subview.place(
                at: CGPoint(x: bounds.minX + CGFloat(column) * (cellWidth + spacing), y: y),
                proposal: ProposedViewSize(width: cellWidth, height: rows[row])
            )
            if column == columns - 1 { y += rows[row] + spacing }
        }
    }

    private func columnCount(width: CGFloat) -> Int { !singleColumn && width >= 580 ? 2 : 1 }

    private func rowHeights(width: CGFloat, subviews: Subviews) -> [CGFloat] {
        let columns = columnCount(width: width)
        let cellWidth = (width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
        var rows: [CGFloat] = []
        for (index, subview) in subviews.enumerated() {
            let height = subview.sizeThatFits(ProposedViewSize(width: cellWidth, height: nil)).height
            if index % columns == 0 { rows.append(height) }
            else { rows[rows.count - 1] = max(rows[rows.count - 1], height) }
        }
        return rows
    }
}

struct TrainingTrickRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let definition: TrickDefinition
    var selected: SelectedTrick? = nil
    var isCustom = false

    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: AppTheme.Space.sm))
            : AnyLayout(HStackLayout(alignment: .center, spacing: AppTheme.Space.md))
    }

    var body: some View {
        layout {
            TrickIllustration(definition: definition)
            VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                    Text(definition.name).font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryInk.opacity(0.7))
                        .accessibilityHidden(true)
                }
                if let selected {
                    Text(selected.status.title)
                        .font(.subheadline)
                        .foregroundStyle(selected.status == .mastered ? AppTheme.green : AppTheme.secondaryInk)
                    HStack(spacing: AppTheme.Space.sm) {
                        ProgressView(value: Double(selected.progress), total: 100)
                            .tint(AppTheme.green)
                            .accessibilityHidden(true)
                        Text("\(selected.progress) %")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(AppTheme.secondaryInk)
                            .fixedSize()
                    }
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: selected.progress)
                } else {
                    Text(definition.difficulty.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.green)
                        .padding(.horizontal, AppTheme.Space.sm)
                        .padding(.vertical, AppTheme.Space.xs)
                        .background(AppTheme.greenSoft.opacity(0.65), in: Capsule())
                    Text(isCustom ? String(localized: "Guía propia") : definition.category.title)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppTheme.Space.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .appSurface()
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

struct TrainingActionRow: View {
    let title: LocalizedStringKey
    let symbol: String
    let subtitle: LocalizedStringKey

    var body: some View {
        HStack(spacing: AppTheme.Space.md) {
            CareSymbol(systemName: symbol)
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryInk)
                .accessibilityHidden(true)
        }
        .padding(.vertical, AppTheme.Space.xs)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct BehaviorObservationRow: View {
    let record: BehaviorObservation

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Space.md) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppTheme.greenSoft)
                .frame(width: 3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(TrainingFormatting.date(record.date))
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                Text(record.title).font(.headline)
                Text(record.observation)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineLimit(2)
                if !record.status.isEmpty {
                    Text(record.status).font(.caption).foregroundStyle(AppTheme.green)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.vertical, AppTheme.Space.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("training.observation.\(record.id.uuidString)")
    }
}

struct TrainingGuideSection: View {
    let title: LocalizedStringKey
    let text: String

    var body: some View {
        if !text.isEmpty {
            CareSection(title: title, style: .compact) {
                Text(text).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct TrainingGuideStep: View {
    let number: Int
    let text: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Space.md) {
            Text("\(number)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(AppTheme.green)
                .frame(width: 30, height: 30)
                .background(AppTheme.greenSoft, in: Circle())
                .frame(maxHeight: .infinity, alignment: .top)
                .background(alignment: .top) {
                    if !isLast {
                        Rectangle().fill(AppTheme.greenSoft)
                            .frame(width: 1)
                            .padding(.top, 30)
                    }
                }
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, AppTheme.Space.xs)
                .padding(.bottom, isLast ? 0 : AppTheme.Space.xl)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Paso \(number). \(text)")
    }
}

extension View {
    func trainingSheetSize() -> some View {
        #if os(macOS)
        frame(minWidth: 500, idealWidth: 690, minHeight: 500, idealHeight: 740)
        #else
        self.presentationDetents([.large]).presentationDragIndicator(.visible)
        #endif
    }
}
