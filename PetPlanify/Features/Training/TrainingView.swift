import SwiftUI

struct TrainingView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var presentedDetail: TrainingPresentation?

    private var training: TrainingData { store.snapshot.training }
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
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: AppTheme.Space.sm) { trainingActions }
                        VStack(alignment: .leading, spacing: AppTheme.Space.sm) { trainingActions }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("Elegir truco", systemImage: "books.vertical") { presentedDetail = .library }
                    Button("Crear truco", systemImage: "pawprint") { presentedDetail = .customTrick }
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
                Button("Explorar biblioteca", systemImage: "books.vertical") { presentedDetail = .library }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.green)
                    .accessibilityIdentifier("training.chooseFirst")
                Button("Crear un truco", systemImage: "plus") { presentedDetail = .customTrick }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.green)
                    .accessibilityIdentifier("training.addCustom")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var trainingActions: some View {
        Button("Explorar biblioteca", systemImage: "books.vertical") { presentedDetail = .library }
            .buttonStyle(.bordered)
            .tint(AppTheme.green)
            .accessibilityIdentifier("training.library")
        Button("Crear un truco", systemImage: "plus") { presentedDetail = .customTrick }
            .buttonStyle(.bordered)
            .tint(AppTheme.green)
            .accessibilityIdentifier("training.addCustom")
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
