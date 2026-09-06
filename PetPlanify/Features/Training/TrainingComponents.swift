import SwiftUI

struct TrickIllustration: View {
    let definition: TrickDefinition

    var body: some View {
        Group {
            if let asset = definition.illustrationAssetName {
                Image(asset).resizable().scaledToFit()
            } else {
                Image(systemName: definition.iconIdentifier)
                    .font(.title3)
            }
        }
        .foregroundStyle(AppTheme.green)
        .frame(width: 44, height: 44)
        .background(AppTheme.greenSoft, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}

struct TrainingTrickRow: View {
    let definition: TrickDefinition
    var selected: SelectedTrick? = nil
    var isCustom = false

    var body: some View {
        HStack(spacing: 12) {
            TrickIllustration(definition: definition)
            VStack(alignment: .leading, spacing: 5) {
                Text(definition.name).font(.headline)
                if let selected {
                    Text("\(selected.status.title) · \(selected.progress) %")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                    ProgressView(value: Double(selected.progress), total: 100)
                        .tint(AppTheme.green)
                        .accessibilityHidden(true)
                } else {
                    Text("\(definition.difficulty.title) · \(definition.category.title)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                    if isCustom {
                        Text("Guía propia").font(.caption).foregroundStyle(AppTheme.secondaryInk)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryInk)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 5)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct TrainingActionRow: View {
    let title: LocalizedStringKey
    let symbol: String
    let subtitle: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(AppTheme.green)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryInk)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct BehaviorObservationRow: View {
    let record: BehaviorObservation

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(record.title).font(.headline)
            Text(TrainingFormatting.date(record.date))
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(record.observation)
                .font(.body)
                .foregroundStyle(AppTheme.secondaryInk)
                .lineLimit(2)
            if !record.status.isEmpty {
                Text(record.status).font(.subheadline).foregroundStyle(AppTheme.green)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.vertical, 4)
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
            CareSection(title: title) {
                Text(text).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension View {
    func trainingSheetSize() -> some View {
        #if os(macOS)
        frame(minWidth: 430, idealWidth: 540, minHeight: 450, idealHeight: 650)
        #else
        self
        #endif
    }
}
