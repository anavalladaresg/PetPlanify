import SwiftUI

struct TrainingMacView: View {
    let overview: TrainingOverview
    let onPresent: (TrainingDetail) -> Void

    var body: some View {
        TrainingDashboardContent(overview: overview, includesTitle: true, compact: false, onPresent: onPresent)
    }
}

struct TrainingPhoneView: View {
    let overview: TrainingOverview
    let onPresent: (TrainingDetail) -> Void

    var body: some View {
        TrainingDashboardContent(overview: overview, includesTitle: false, compact: true, onPresent: onPresent)
    }
}

private struct TrainingDashboardContent: View {
    let overview: TrainingOverview
    let includesTitle: Bool
    let compact: Bool
    let onPresent: (TrainingDetail) -> Void

    private var available: [TrickDefinition] {
        let selected = Set(overview.selectedTricks.map(\.id))
        return overview.library.filter { !selected.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: compact ? 16 : 20) {
                header
                SelectedTricksCard(tricks: overview.selectedTricks) {
                    onPresent(.trick($0))
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        TrickLibraryPreviewCard(available: available) {
                            onPresent(.library)
                        }
                        BehaviorObservationsCard(observations: overview.behaviorObservations) {
                            onPresent(.behavior($0))
                        }
                    }
                    VStack(spacing: 14) {
                        TrickLibraryPreviewCard(available: available) {
                            onPresent(.library)
                        }
                        BehaviorObservationsCard(observations: overview.behaviorObservations) {
                            onPresent(.behavior($0))
                        }
                    }
                }
            }
            .frame(maxWidth: 1_080, alignment: .leading)
            .padding(compact ? 16 : 28)
            .padding(.bottom, compact ? 12 : 0)
        }
        .appCanvas()
        .accessibilityIdentifier("training.screen")
    }

    private var header: some View {
        Group {
            if compact {
                titleBlock
            } else {
            HStack {
                titleBlock
                Spacer()
                customButton
            }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            if includesTitle {
                Text("Entrenamiento")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("Trucos elegidos para Neo y guías prudentes para enseñarlos")
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private var customButton: some View {
        Button {
            onPresent(.customTrick)
        } label: {
            Label("Truco personalizado", systemImage: "plus")
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("training.addCustom")
    }
}

#Preview("Entrenamiento · macOS") {
    TrainingMacView(overview: TrainingPreviewData.neoOverview, onPresent: { _ in })
        .frame(width: 1_100, height: 840)
}

#Preview("Entrenamiento · iPhone") {
    NavigationStack {
        TrainingPhoneView(overview: TrainingPreviewData.neoOverview, onPresent: { _ in })
    }
    .frame(width: 393, height: 852)
}
