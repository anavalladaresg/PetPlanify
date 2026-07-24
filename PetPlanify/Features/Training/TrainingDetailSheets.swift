import SwiftUI

struct TrainingDetailSheet: View {
    let detail: TrainingDetail
    let library: [TrickDefinition]
    let selectedIDs: Set<String>
    let onAdd: (TrickDefinition) -> Void
    let onDismiss: () -> Void
    @State private var difficulty: TrickDifficulty?
    @State private var category: TrickCategory?

    private var filteredLibrary: [TrickDefinition] {
        library.filter { trick in
            (difficulty == nil || trick.difficulty == difficulty)
                && (category == nil || trick.category == category)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(title)
                        .font(.system(.title2, design: .serif, weight: .semibold))
                    Spacer()
                    Button("Cerrar", action: onDismiss)
                        .buttonStyle(.bordered)
                }
                content
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(26)
        }
        .appCanvas()
        .accessibilityIdentifier("training.detail")
    }

    private var title: String {
        switch detail {
        case .customTrick: "Truco personalizado"
        case .library: "Explorar trucos"
        case let .trick(trick): trick.name
        case let .behavior(observation): observation.title
        }
    }

    @ViewBuilder
    private var content: some View {
        switch detail {
        case .customTrick:
            futureCustom
        case .library:
            libraryContent
        case let .trick(trick):
            guideContent(trick)
        case let .behavior(observation):
            behaviorContent(observation)
        }
    }

    private var futureCustom: some View {
        VStack(spacing: 15) {
            TrickIllustration(symbol: "plus", size: 70)
            Text("La creación de trucos personalizados se activará con los formularios funcionales.")
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .appSurface()
    }

    private var libraryContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack { difficultyPicker; categoryPicker }
                VStack { difficultyPicker; categoryPicker }
            }
            ForEach(filteredLibrary) { trick in
                HStack(spacing: 12) {
                    TrickIllustration(symbol: trick.symbol, size: 48)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(trick.name).font(.headline)
                        Text("\(trick.difficulty.title) · \(trick.category.title)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryInk)
                        if !trick.prerequisites.isEmpty {
                            Text("Requisitos: \(trick.prerequisites.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryInk)
                        }
                    }
                    Spacer()
                    Button(selectedIDs.contains(trick.id) ? "Elegido" : "Añadir") {
                        onAdd(trick)
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedIDs.contains(trick.id))
                }
                .padding(12)
                .appSurface(cornerRadius: 14)
            }
        }
    }

    private var difficultyPicker: some View {
        Picker("Dificultad", selection: $difficulty) {
            Text("Todas las dificultades").tag(TrickDifficulty?.none)
            ForEach(TrickDifficulty.allCases) { value in
                Text(value.title).tag(Optional(value))
            }
        }
    }

    private var categoryPicker: some View {
        Picker("Categoría", selection: $category) {
            Text("Todas las categorías").tag(TrickCategory?.none)
            ForEach(TrickCategory.allCases) { value in
                Text(value.title).tag(Optional(value))
            }
        }
    }

    private func guideContent(_ trick: TrickDefinition) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                TrickIllustration(symbol: trick.symbol, size: 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(trick.difficulty.title) · \(trick.category.title)")
                        .font(.headline)
                    Text(trick.guide.objective)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
            }
            guideSection("Material necesario", text: trick.guide.materials)
            numberedSection("Pasos", items: trick.guide.steps)
            numberedSection("Errores habituales", items: trick.guide.commonMistakes)
            guideSection("Duración de cada intento", text: trick.guide.recommendedAttempt)
            guideSection("Recompensa", text: trick.guide.reward)
            guideSection("Cuándo avanzar", text: trick.guide.advancement)
            guideSection("Precauciones", text: trick.guide.precautions)
            Text("Esta guía es general y no sustituye el acompañamiento de un profesional de la educación canina.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private func behaviorContent(_ observation: BehaviorObservation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(TrainingFormatting.date(observation.date))
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(observation.body)
            guideSection("Contexto que ayudó", text: observation.helpfulContext)
            Text("Es una observación personal y no un diagnóstico de comportamiento.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .padding(18)
        .appSurface()
    }

    private func guideSection(_ title: LocalizedStringKey, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(text).foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private func numberedSection(_ title: LocalizedStringKey, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline)
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 9) {
                    Text("\(index + 1).").font(.subheadline.weight(.semibold))
                    Text(item).foregroundStyle(AppTheme.secondaryInk)
                }
            }
        }
    }
}
