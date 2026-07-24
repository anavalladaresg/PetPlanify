import SwiftUI

struct SelectedTricksCard: View {
    let tricks: [SelectedTrick]
    let onSelect: (TrickDefinition) -> Void

    var body: some View {
        TrainingGroupCard("Mis trucos", symbol: "checklist", identifier: "training.myTricks") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 12)], spacing: 12) {
                ForEach(tricks) { trick in
                    Button {
                        onSelect(trick.definition)
                    } label: {
                        HStack(spacing: 12) {
                            TrickIllustration(symbol: trick.definition.symbol, size: 48)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(trick.definition.name)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.ink)
                                Text(trick.status.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(trick.status == .mastered ? AppTheme.green : AppTheme.orange)
                                ProgressView(value: Double(trick.progress), total: 100)
                                    .tint(trick.status == .mastered ? AppTheme.green : AppTheme.orange)
                                    .accessibilityLabel("Progreso")
                                    .accessibilityValue("\(trick.progress) por ciento")
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryInk)
                                .accessibilityHidden(true)
                        }
                        .padding(12)
                        .background(AppTheme.surfaceMuted.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(trick.definition.name), \(trick.status.title), \(trick.progress) por ciento")
                }
            }
        }
    }
}

struct TrickLibraryPreviewCard: View {
    let available: [TrickDefinition]
    let onExplore: () -> Void

    var body: some View {
        TrainingGroupCard("Explorar trucos", symbol: "books.vertical", identifier: "training.library") {
            Text("Guías integradas por dificultad, categoría y requisitos previos.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
            HStack(spacing: 9) {
                ForEach(available.prefix(4)) { trick in
                    VStack(spacing: 5) {
                        TrickIllustration(symbol: trick.symbol, size: 42)
                        Text(trick.name).font(.caption).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
            Button("Abrir biblioteca", action: onExplore)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.green)
                .frame(minHeight: 40)
                .accessibilityIdentifier("training.explore")
        }
    }
}

struct BehaviorObservationsCard: View {
    let observations: [BehaviorObservation]
    let onSelect: (BehaviorObservation) -> Void

    var body: some View {
        TrainingGroupCard("Comportamiento", symbol: "pawprint", identifier: "training.behavior") {
            ForEach(observations) { observation in
                Button {
                    onSelect(observation)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(observation.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text("\(TrainingFormatting.date(observation.date)) · \(observation.body)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryInk)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if observation.id != observations.last?.id {
                    Divider().overlay(AppTheme.border)
                }
            }
            Text("Son observaciones personales, no diagnósticos de comportamiento.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .padding(.top, 5)
        }
    }
}

struct TrickIllustration: View {
    let symbol: String
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(AppTheme.greenSoft)
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(AppTheme.green)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct TrainingGroupCard<Content: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    let identifier: String
    @ViewBuilder let content: Content

    init(_ title: LocalizedStringKey, symbol: String, identifier: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.symbol = symbol
        self.identifier = identifier
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.system(.title3, design: .serif, weight: .semibold))
            content
        }
        .padding(18)
        .appSurface()
        .accessibilityIdentifier(identifier)
    }
}
