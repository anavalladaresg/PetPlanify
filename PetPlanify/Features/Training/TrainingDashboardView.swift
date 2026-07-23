import SwiftUI

struct TrainingMacView: View {
    let overview: TrainingOverview
    @Binding var selectedSection: TrainingSection
    let onPresent: (TrainingDetail) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                TrainingHeader(includesTitle: true, onPresent: onPresent)
                TrainingSectionSelector(selection: $selectedSection)
                    .frame(maxWidth: 720)

                TrainingSectionContent(
                    section: selectedSection,
                    overview: overview,
                    compact: false,
                    onPresent: onPresent,
                    onSelectSection: { selectedSection = $0 }
                )
            }
            .frame(maxWidth: 1_180, alignment: .leading)
            .padding(32)
        }
        .appCanvas()
        .accessibilityIdentifier("training.screen")
    }
}

struct TrainingPhoneView: View {
    let overview: TrainingOverview
    @Binding var selectedSection: TrainingSection
    let onPresent: (TrainingDetail) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TrainingHeader(includesTitle: false, onPresent: onPresent)
                TrainingSectionSelector(selection: $selectedSection)

                TrainingSectionContent(
                    section: selectedSection,
                    overview: overview,
                    compact: true,
                    onPresent: onPresent,
                    onSelectSection: { selectedSection = $0 }
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .appCanvas()
        .accessibilityIdentifier("training.screen")
    }
}

private struct TrainingHeader: View {
    let includesTitle: Bool
    let onPresent: (TrainingDetail) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 20) {
                titleBlock
                Spacer(minLength: 12)
                actions
            }

            VStack(alignment: .leading, spacing: 14) {
                titleBlock
                actions
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            if includesTitle {
                Text("Entrenamiento")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("Pequeños avances que fortalecen la rutina de Neo.")
                .font(includesTitle ? .title3 : .subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                onPresent(.addSession)
            } label: {
                Label("Registrar sesión", systemImage: "stopwatch")
                    .frame(minHeight: 32)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityHint("Abre una vista previa para registrar una sesión")
            .accessibilityIdentifier("training.addSession")

            Button {
                onPresent(.addTrick)
            } label: {
                Label("Añadir truco", systemImage: "plus")
                    .frame(minHeight: 32)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Abre una vista previa para añadir un truco")
            .accessibilityIdentifier("training.addTrick")
        }
    }
}

struct TrainingSectionContent: View {
    let section: TrainingSection
    let overview: TrainingOverview
    let compact: Bool
    let onPresent: (TrainingDetail) -> Void
    let onSelectSection: (TrainingSection) -> Void

    @ViewBuilder
    var body: some View {
        switch section {
        case .tricks:
            TricksSectionView(
                overview: overview,
                compact: compact,
                onPresent: onPresent,
                onSelectSection: onSelectSection
            )
        case .sessions:
            SessionsSectionView(overview: overview, compact: compact, onPresent: onPresent)
        case .behaviorNotes:
            BehaviorNotesSectionView(overview: overview, onPresent: onPresent)
        }
    }
}

private struct TricksSectionView: View {
    let overview: TrainingOverview
    let compact: Bool
    let onPresent: (TrainingDetail) -> Void
    let onSelectSection: (TrainingSection) -> Void

    var body: some View {
        VStack(spacing: compact ? 16 : 18) {
            TrainingOverviewGrid(overview: overview, compact: compact)

            if compact {
                VStack(spacing: 16) {
                    tricksCard
                    sessionsCard
                    notesCard
                    quickActions
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        tricksCard
                            .frame(minWidth: 570)
                        VStack(spacing: 18) {
                            sessionsCard
                            notesCard
                        }
                        .frame(minWidth: 340)
                    }

                    VStack(spacing: 18) {
                        tricksCard
                        sessionsCard
                        notesCard
                    }
                }
            }
        }
    }

    private var tricksCard: some View {
        TricksProgressCard(
            tricks: overview.tricks,
            onSelect: { onPresent(.trick($0)) }
        )
    }

    private var sessionsCard: some View {
        VStack(spacing: 10) {
            RecentSessionsCard(
                sessions: overview.sessions,
                limit: 2,
                onSelect: { onPresent(.session($0)) }
            )
            Button("Ver todas las sesiones") {
                onSelectSection(.sessions)
            }
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.green)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    private var notesCard: some View {
        VStack(spacing: 10) {
            BehaviorNotesCard(
                notes: overview.behaviorNotes,
                limit: 1,
                onSelect: { onPresent(.behaviorNote($0)) }
            )
            Button("Ver todas las notas") {
                onSelectSection(.behaviorNotes)
            }
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.green)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button {
                onPresent(.addTrick)
            } label: {
                Label("Añadir truco", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)

            Button {
                onPresent(.addSession)
            } label: {
                Label("Registrar sesión", systemImage: "stopwatch")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct SessionsSectionView: View {
    let overview: TrainingOverview
    let compact: Bool
    let onPresent: (TrainingDetail) -> Void

    var body: some View {
        VStack(spacing: 18) {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 12),
                    count: compact ? 1 : 3
                ),
                spacing: 12
            ) {
                TrainingMetricCard(
                    title: "Sesiones recientes",
                    value: overview.sessions.count.formatted(),
                    symbol: "calendar",
                    accent: AppTheme.green
                )
                TrainingMetricCard(
                    title: "Minutos registrados",
                    value: overview.recentSessionMinutes.formatted(),
                    symbol: "clock",
                    accent: AppTheme.orange
                )
                TrainingMetricCard(
                    title: "Trucos practicados",
                    value: overview.practisedTrickCount.formatted(),
                    symbol: "sparkles",
                    accent: AppTheme.green
                )
            }

            RecentSessionsCard(
                sessions: overview.sessions,
                onSelect: { onPresent(.session($0)) }
            )
        }
    }
}

private struct BehaviorNotesSectionView: View {
    let overview: TrainingOverview
    let onPresent: (TrainingDetail) -> Void

    var body: some View {
        BehaviorNotesCard(
            notes: overview.behaviorNotes,
            showsDisclaimer: true,
            onSelect: { onPresent(.behaviorNote($0)) }
        )
    }
}

#Preview("Entrenamiento · macOS") {
    TrainingMacView(
        overview: TrainingPreviewData.neoOverview,
        selectedSection: .constant(.tricks),
        onPresent: { _ in }
    )
    .frame(width: 1_150, height: 900)
}

#Preview("Entrenamiento · iPhone") {
    NavigationStack {
        TrainingPhoneView(
            overview: TrainingPreviewData.neoOverview,
            selectedSection: .constant(.tricks),
            onPresent: { _ in }
        )
        .navigationTitle("Entrenamiento")
    }
    .frame(width: 393, height: 852)
}

#Preview("Entrenamiento · Notas") {
    ScrollView {
        TrainingSectionContent(
            section: .behaviorNotes,
            overview: TrainingPreviewData.neoOverview,
            compact: true,
            onPresent: { _ in },
            onSelectSection: { _ in }
        )
        .padding()
    }
    .frame(width: 393, height: 800)
    .appCanvas()
}
