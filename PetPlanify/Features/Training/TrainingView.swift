import SwiftUI

struct TrainingView: View {
    @Environment(PetPlanifyStore.self) private var store
    @State private var presentedDetail: TrainingPresentation?

    private var training: TrainingData { store.snapshot.training }
    private var observations: [BehaviorObservation] {
        training.observations.sorted { $0.date > $1.date }
    }

    var body: some View {
        CarePage {
            CareSection(title: "Mis trucos") {
                if training.selectedTricks.isEmpty {
                    EmptyCareState(
                        title: "Un pequeño paso para empezar", symbol: "pawprint",
                        message: "Elige un truco y adapta el aprendizaje a su ritmo."
                    )
                    Button("Elegir un truco", systemImage: "plus") { presentedDetail = .library }
                        .accessibilityIdentifier("training.chooseFirst")
                } else {
                    ForEach(training.selectedTricks) { selected in
                        if let definition = training.definition(for: selected.trickID) {
                            Button { presentedDetail = .trick(definition.id) } label: {
                                TrainingTrickRow(definition: definition, selected: selected)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("training.selected.\(selected.id.uuidString)")
                            if selected.id != training.selectedTricks.last?.id { Divider() }
                        }
                    }
                }
            }

            CareSection(title: "Explorar trucos") {
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

            CareSection(title: "Comportamiento") {
                if observations.isEmpty {
                    Text("Anota lo que observas y qué le ayuda en cada situación.")
                        .foregroundStyle(AppTheme.secondaryInk)
                } else {
                    ForEach(Array(observations.prefix(3))) { observation in
                        Button { presentedDetail = .observation(observation.id) } label: {
                            BehaviorObservationRow(record: observation)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                Button("Añadir observación", systemImage: "plus") { presentedDetail = .newObservation }
                    .accessibilityIdentifier("training.addObservation")
                if !observations.isEmpty {
                    Button("Ver historial", systemImage: "clock") { presentedDetail = .history }
                        .accessibilityIdentifier("training.behaviorHistory")
                }
                Text("Estas observaciones no sustituyen la valoración de un educador canino o profesional veterinario.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
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
