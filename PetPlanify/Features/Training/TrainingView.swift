import SwiftUI

struct TrainingView: View {
    @State private var selectedTricks = TrainingPreviewData.neoOverview.selectedTricks
    @State private var presentedDetail: TrainingDetail?

    private var overview: TrainingOverview {
        TrainingOverview(
            selectedTricks: selectedTricks,
            library: TrainingPreviewData.library,
            behaviorObservations: TrainingPreviewData.neoOverview.behaviorObservations
        )
    }

    var body: some View {
        Group {
            #if os(macOS)
            TrainingMacView(overview: overview, onPresent: { presentedDetail = $0 })
            #else
            TrainingPhoneView(overview: overview, onPresent: { presentedDetail = $0 })
            #endif
        }
        .environment(\.locale, TrainingFormatting.spanishLocale)
        .sheet(item: $presentedDetail) { detail in
            TrainingDetailSheet(
                detail: detail,
                library: overview.library,
                selectedIDs: Set(selectedTricks.map(\.id)),
                onAdd: addTrick,
                onDismiss: { presentedDetail = nil }
            )
        }
    }

    private func addTrick(_ definition: TrickDefinition) {
        guard !selectedTricks.contains(where: { $0.id == definition.id }) else { return }
        selectedTricks.append(
            SelectedTrick(definition: definition, status: .notStarted, progress: 0)
        )
    }
}
