import SwiftUI

struct TrainingOverview: View {
    let selectedCount: Int
    let masteredCount: Int
    let averageProgress: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    private var completion: Double {
        guard selectedCount > 0 else { return 0 }
        return Double(masteredCount) / Double(selectedCount)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalLayout
            verticalLayout
        }
        .padding(AppTheme.Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                colors: [AppTheme.greenSoft.opacity(0.9), AppTheme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .appSurface(cornerRadius: AppTheme.heroRadius, elevated: true)
        .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.985)
        .opacity(hasAppeared || reduceMotion ? 1 : 0)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.35)) { hasAppeared = true }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("training.overview")
    }

    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: AppTheme.Space.xl) {
            DogPoseIllustration(pose: .offeringPaw)
                .frame(width: 122, height: 96)
            copy
            Spacer(minLength: AppTheme.Space.sm)
            TrainingProgressRing(value: completion, label: "Dominados")
        }
    }

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            HStack(alignment: .center, spacing: AppTheme.Space.lg) {
                DogPoseIllustration(pose: .offeringPaw)
                    .frame(width: 110, height: 88)
                copy
            }
            HStack(spacing: AppTheme.Space.lg) {
                TrainingStat(value: selectedCount, label: "En progreso")
                TrainingStat(value: masteredCount, label: "Dominados")
                TrainingStat(value: averageProgress, suffix: "%", label: "Avance medio")
            }
        }
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
            Text("Entrena a su ritmo")
                .font(.title2.weight(.semibold))
                .fontDesign(.serif)
                .foregroundStyle(AppTheme.ink)
                .accessibilityAddTraits(.isHeader)
            Text(selectedCount == 0
                 ? "Un momento breve cada día hace la diferencia."
                 : "Pequeños pasos, mucha confianza.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TrainingStat: View {
    let value: Int
    var suffix: String = ""
    let label: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
            Text("\(value)\(suffix)")
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(AppTheme.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct TrainingProgressRing: View {
    let value: Double
    let label: LocalizedStringKey
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.greenSoft, lineWidth: 8)
            Circle()
                .trim(from: 0, to: max(0, min(value, 1)))
                .stroke(AppTheme.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: value)
            VStack(spacing: 0) {
                Text("\(Int((value * 100).rounded()))%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(AppTheme.ink)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .frame(width: 82, height: 82)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(Int((value * 100).rounded())) por ciento")
    }
}

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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.greenSoft.opacity(0.82), AppTheme.surfaceMuted.opacity(0.46)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: definition.iconIdentifier)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.green.opacity(0.42))
                        .padding(AppTheme.Space.sm)
                        .accessibilityHidden(true)
                }
            if let asset = definition.illustrationAssetName {
                Image(asset).resizable().scaledToFit().padding(AppTheme.Space.sm)
            } else {
                DogPoseIllustration(pose: pose)
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
