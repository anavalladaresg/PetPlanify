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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: compact ? 16 : 20) {
                header

                Text("\(overview.masteredCount) dominado · \(overview.inProgressCount) en progreso · \(overview.weeklyMinutes) min esta semana")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .accessibilityIdentifier("training.summary")

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        TricksProgressCard(
                            tricks: overview.tricks,
                            onSelect: { onPresent(.trick($0)) }
                        )
                        VStack(spacing: 14) {
                            RecentSessionsCard(
                                sessions: overview.sessions,
                                limit: 3,
                                onSelect: { onPresent(.session($0)) }
                            )
                            BehaviorNotesCard(
                                notes: overview.behaviorNotes,
                                limit: 1,
                                onSelect: { onPresent(.behaviorNote($0)) }
                            )
                        }
                        .frame(minWidth: 350)
                    }
                    VStack(spacing: 14) {
                        TricksProgressCard(
                            tricks: overview.tricks,
                            onSelect: { onPresent(.trick($0)) }
                        )
                        RecentSessionsCard(
                            sessions: overview.sessions,
                            limit: 3,
                            onSelect: { onPresent(.session($0)) }
                        )
                        BehaviorNotesCard(
                            notes: overview.behaviorNotes,
                            limit: 1,
                            onSelect: { onPresent(.behaviorNote($0)) }
                        )
                    }
                }
            }
            .frame(maxWidth: 1_080, alignment: .leading)
            .padding(compact ? 18 : 28)
        }
        .appCanvas()
        .accessibilityIdentifier("training.screen")
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                titleBlock
                Spacer()
                actions
            }
            VStack(alignment: .leading, spacing: 12) {
                titleBlock
                actions
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            if includesTitle {
                Text("Entrenamiento")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("Práctica breve y avances cotidianos")
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private var actions: some View {
        HStack(spacing: 9) {
            Button {
                onPresent(.addSession)
            } label: {
                Label("Registrar sesión", systemImage: "stopwatch")
                    .frame(minHeight: 34)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("training.addSession")

            Button {
                onPresent(.addTrick)
            } label: {
                Label("Añadir truco", systemImage: "plus")
                    .frame(minHeight: 34)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.green)
            .accessibilityIdentifier("training.addTrick")
        }
    }
}

#Preview("Entrenamiento · macOS") {
    TrainingMacView(overview: TrainingPreviewData.neoOverview, onPresent: { _ in })
        .frame(width: 1_100, height: 820)
}

#Preview("Entrenamiento · iPhone") {
    NavigationStack {
        TrainingPhoneView(overview: TrainingPreviewData.neoOverview, onPresent: { _ in })
    }
    .frame(width: 393, height: 852)
}
