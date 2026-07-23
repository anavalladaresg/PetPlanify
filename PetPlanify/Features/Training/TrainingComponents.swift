import SwiftUI

struct TrainingSectionSelector: View {
    @Binding var selection: TrainingSection

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(TrainingSection.allCases) { section in
                    Button {
                        selection = section
                    } label: {
                        Text(section.title)
                            .font(.subheadline.weight(selection == section ? .semibold : .regular))
                            .foregroundStyle(selection == section ? AppTheme.ink : AppTheme.secondaryInk)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 40)
                            .background(
                                Capsule()
                                    .fill(selection == section ? AppTheme.surfaceMuted : .clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == section ? .isSelected : [])
                    .accessibilityIdentifier("training.section.\(section.rawValue)")
                }
            }
            .padding(4)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.surface.opacity(0.66), in: Capsule())
        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 0.75))
        .accessibilityIdentifier("training.sectionPicker")
    }
}

struct TrainingOverviewGrid: View {
    let overview: TrainingOverview
    let compact: Bool

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 12),
            count: compact ? 2 : 4
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            TrainingMetricCard(
                title: "Trucos totales",
                value: overview.tricks.count.formatted(),
                symbol: "sparkles",
                accent: AppTheme.green
            )
            TrainingMetricCard(
                title: "Dominados",
                value: overview.masteredCount.formatted(),
                symbol: "checkmark.seal",
                accent: AppTheme.green
            )
            TrainingMetricCard(
                title: "En progreso",
                value: overview.inProgressCount.formatted(),
                symbol: "chart.line.uptrend.xyaxis",
                accent: AppTheme.orange
            )
            TrainingMetricCard(
                title: "Minutos esta semana",
                value: overview.weeklyMinutes.formatted(),
                symbol: "clock",
                accent: AppTheme.orange
            )
        }
        .accessibilityIdentifier("training.overview")
    }
}

struct TrainingMetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let symbol: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 32, height: 32)
                .background(accent.opacity(0.11), in: Circle())
                .accessibilityHidden(true)
            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 106, alignment: .topLeading)
        .padding(16)
        .appSurface(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }
}

struct TricksProgressCard: View {
    let tricks: [TrainingTrick]
    let onSelect: (TrainingTrick) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TrainingCardHeader(title: "Trucos aprendidos", symbol: "figure.dog")
                .padding(.bottom, 6)

            ForEach(tricks) { trick in
                TrickProgressRow(trick: trick, onSelect: { onSelect(trick) })
                if trick.id != tricks.last?.id {
                    Divider().overlay(AppTheme.border)
                }
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("training.tricks")
    }
}

struct TrickProgressRow: View {
    let trick: TrainingTrick
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    titleBlock
                        .frame(minWidth: 130, alignment: .leading)
                    progressBlock
                    practiceBlock
                    disclosure
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        titleBlock
                        Spacer(minLength: 10)
                        disclosure
                    }
                    progressBlock
                    practiceBlock
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(trick.name), \(trick.status.title), \(trick.progress) %, última práctica \(trick.lastPractised.title)"
        )
        .accessibilityHint("Abre el detalle del truco")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            onSelect()
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trick.name)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            TrainingStatusBadge(title: trick.status.title, accent: accent)
        }
        .multilineTextAlignment(.leading)
    }

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Progreso")
                Spacer()
                Text("\(trick.progress) %")
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryInk)

            TrainingProgressDots(progress: trick.progress, accent: accent)
        }
        .frame(maxWidth: .infinity)
    }

    private var practiceBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Última práctica")
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(trick.lastPractised.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(minWidth: 92, alignment: .leading)
    }

    private var disclosure: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.secondaryInk)
            .accessibilityHidden(true)
    }

    private var accent: Color {
        switch trick.status {
        case .mastered: AppTheme.green
        case .inProgress: AppTheme.orange
        case .notStarted: AppTheme.secondaryInk
        }
    }
}

struct TrainingProgressDots: View {
    let progress: Int
    let accent: Color

    private let dotCount = 10

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(index < filledCount ? accent : AppTheme.surfaceMuted)
                    .overlay(Circle().stroke(AppTheme.border, lineWidth: 0.5))
                    .frame(maxWidth: 14)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progreso: \(progress) %")
    }

    private var filledCount: Int {
        min(dotCount, max(0, Int(ceil(Double(progress) / 10))))
    }
}

struct RecentSessionsCard: View {
    let sessions: [TrainingSession]
    var limit: Int?
    let onSelect: (TrainingSession) -> Void

    private var displayedSessions: [TrainingSession] {
        if let limit {
            Array(sessions.prefix(limit))
        } else {
            sessions
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TrainingCardHeader(title: "Últimas sesiones", symbol: "clock.arrow.circlepath")
                .padding(.bottom, 6)

            ForEach(displayedSessions) { session in
                TrainingSessionRow(session: session, onSelect: { onSelect(session) })
                if session.id != displayedSessions.last?.id {
                    Divider().overlay(AppTheme.border)
                }
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("training.sessions")
    }
}

struct TrainingSessionRow: View {
    let session: TrainingSession
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: "stopwatch")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.orange)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.orange.opacity(0.1), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(TrainingFormatting.sessionDate(session.date))
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                    HStack(alignment: .firstTextBaseline) {
                        Text(session.type)
                            .font(.subheadline.weight(.semibold))
                        Spacer(minLength: 8)
                        Text("\(session.durationMinutes) min")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.green)
                    }
                    Text(session.tricks.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                    Text(session.result)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .padding(.top, 4)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(TrainingFormatting.sessionDate(session.date)), \(session.durationMinutes) minutos, \(session.type), trucos \(session.tricks.joined(separator: ", "))"
        )
        .accessibilityHint("Abre el detalle de la sesión")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            onSelect()
        }
    }
}

struct BehaviorNotesCard: View {
    let notes: [BehaviorNote]
    var limit: Int?
    var showsDisclaimer = false
    let onSelect: (BehaviorNote) -> Void

    private var displayedNotes: [BehaviorNote] {
        if let limit {
            Array(notes.prefix(limit))
        } else {
            notes
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TrainingCardHeader(title: "Notas de comportamiento", symbol: "pawprint")
                .padding(.bottom, 4)

            ForEach(displayedNotes) { note in
                BehaviorNoteRow(note: note, onSelect: { onSelect(note) })
                if note.id != displayedNotes.last?.id {
                    Divider().overlay(AppTheme.border)
                }
            }

            if showsDisclaimer {
                Label(
                    "Estas notas son observaciones personales y no sustituyen la valoración de un educador canino o profesional veterinario.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("training.behaviorNotes")
    }
}

struct BehaviorNoteRow: View {
    let note: BehaviorNote
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(TrainingFormatting.date(note.date))
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryInk)
                        Text(note.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                    }
                    Spacer(minLength: 10)
                    TrainingStatusBadge(title: note.status.title, accent: statusAccent)
                }

                Text(note.description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    ForEach(note.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppTheme.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.greenSoft.opacity(0.55), in: Capsule())
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryInk)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(TrainingFormatting.date(note.date)), \(note.title), \(note.status.title), etiquetas \(note.tags.joined(separator: ", ")), \(note.description)"
        )
        .accessibilityHint("Abre el detalle de la nota")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            onSelect()
        }
    }

    private var statusAccent: Color {
        switch note.status {
        case .working: AppTheme.orange
        case .observation: AppTheme.secondaryInk
        case .improvement: AppTheme.green
        }
    }
}

struct TrainingStatusBadge: View {
    let title: String
    let accent: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(accent)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(accent.opacity(0.11), in: Capsule())
            .accessibilityLabel("Estado: \(title)")
    }
}

struct TrainingCardHeader: View {
    let title: LocalizedStringKey
    let symbol: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(.title3, design: .serif, weight: .semibold))
            Spacer(minLength: 0)
        }
    }
}

#Preview("Progreso de truco") {
    TrickProgressRow(
        trick: TrainingPreviewData.neoOverview.tricks[1],
        onSelect: {}
    )
    .padding()
    .frame(width: 620)
    .appCanvas()
}
