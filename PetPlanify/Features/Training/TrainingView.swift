import SwiftUI

struct TrainingView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var presentedDetail: TrainingPresentation?

    private var training: TrainingData { store.snapshot.training }
    private var observations: [BehaviorObservation] {
        training.observations.sorted { $0.date > $1.date }
    }

    private var masteredCount: Int {
        training.selectedTricks.filter { $0.status == .mastered }.count
    }

    private var averageProgress: Int {
        guard !training.selectedTricks.isEmpty else { return 0 }
        let total = training.selectedTricks.reduce(0) { $0 + $1.progress }
        return Int((Double(total) / Double(training.selectedTricks.count)).rounded())
    }

    var body: some View {
        CarePage {
            TrainingOverview(
                selectedCount: training.selectedTricks.count,
                masteredCount: masteredCount,
                averageProgress: averageProgress
            )

            CareSection(title: "Mis trucos", style: training.selectedTricks.isEmpty ? .highlighted : .plain) {
                if training.selectedTricks.isEmpty {
                    firstTrick
                } else {
                    TrainingTileLayout(singleColumn: dynamicTypeSize.isAccessibilitySize) {
                        ForEach(training.selectedTricks) { selected in
                            if let definition = training.definition(for: selected.trickID) {
                                Button { presentedDetail = .trick(definition.id) } label: {
                                    TrainingTrickRow(definition: definition, selected: selected)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("training.selected.\(selected.id.uuidString)")
                            }
                        }
                    }
                }
            }

            CareSection(title: "Explorar trucos", style: .compact) {
                Button { presentedDetail = .library } label: {
                    TrainingActionRow(
                        title: "Biblioteca de trucos", symbol: "books.vertical",
                        subtitle: "Guías breves para aprender con calma y premios."
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("training.library")
                Divider()
                Button { presentedDetail = .customTrick } label: {
                    TrainingActionRow(
                        title: "Crear un truco", symbol: "plus",
                        subtitle: "Guarda una guía propia."
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("training.addCustom")
            }

            CareSection(title: "Comportamiento", style: .compact, symbol: "square.and.pencil") {
                if observations.isEmpty {
                    Text("Anota lo que observas y qué le ayuda en cada situación.")
                        .foregroundStyle(AppTheme.secondaryInk)
                } else {
                    ForEach(Array(observations.prefix(3))) { observation in
                        Button { presentedDetail = .observation(observation.id) } label: {
                            BehaviorObservationRow(record: observation)
                        }
                        .buttonStyle(.plain)
                        if observation.id != observations.prefix(3).last?.id { Divider() }
                    }
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppTheme.Space.lg) { observationActions }
                    VStack(alignment: .leading, spacing: AppTheme.Space.sm) { observationActions }
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("Elegir truco", systemImage: "books.vertical") { presentedDetail = .library }
                    Button("Crear truco", systemImage: "pawprint") { presentedDetail = .customTrick }
                    Button("Añadir observación", systemImage: "square.and.pencil") { presentedDetail = .newObservation }
                } label: {
                    Label("Añadir", systemImage: "plus")
                }
                .accessibilityIdentifier("training.add")
            }
        }
        .sheet(item: $presentedDetail) { detail in
            switch detail {
            case .library:
                TrickLibraryView()
            case .customTrick:
                CustomTrickEditor()
            case let .trick(id):
                NavigationStack { TrickDetailView(trickID: id) }
            case let .observation(id):
                if let record = training.observations.first(where: { $0.id == id }) {
                    BehaviorObservationEditor(record: record)
                }
            case .newObservation:
                BehaviorObservationEditor()
            case .history:
                BehaviorHistoryView()
            }
        }
    }

    private var firstTrick: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: AppTheme.Space.md))
            : AnyLayout(HStackLayout(alignment: .center, spacing: AppTheme.Space.md))
        return layout {
            DogPoseIllustration(pose: .sitting).frame(width: 110, height: 100)
            VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                Text("Un pequeño paso para empezar").font(.headline)
                Text("Elige un truco y adapta el aprendizaje a su ritmo.")
                    .font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                Button("Elegir un truco", systemImage: "plus") { presentedDetail = .library }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("training.chooseFirst")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var observationActions: some View {
        Button("Añadir observación", systemImage: "plus") { presentedDetail = .newObservation }
            .frame(minHeight: 44)
            .accessibilityIdentifier("training.addObservation")
        if !observations.isEmpty {
            Button("Ver historial", systemImage: "clock") { presentedDetail = .history }
                .frame(minHeight: 44)
                .accessibilityIdentifier("training.behaviorHistory")
        }
    }
}

private enum TrainingPresentation: Identifiable {
    case library, customTrick, trick(String), observation(UUID), newObservation, history

    var id: String {
        switch self {
        case .library: "library"
        case .customTrick: "custom"
        case let .trick(id): "trick-\(id)"
        case let .observation(id): "observation-\(id.uuidString)"
        case .newObservation: "new-observation"
        case .history: "history"
        }
    }
}

#Preview("Entrenamiento") {
    NavigationStack { TrainingView() }.environment(PetPlanifyStore.preview())
}

#Preview("Primeros trucos") {
    NavigationStack { TrainingView() }.environment(PetPlanifyStore.preview(empty: true))
}
