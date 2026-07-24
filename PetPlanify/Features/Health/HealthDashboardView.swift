import SwiftUI

struct HealthMacView: View {
    let overview: HealthOverview
    let onPresent: (HealthDetail) -> Void

    var body: some View {
        HealthDashboardContent(overview: overview, includesTitle: true, compact: false, onPresent: onPresent)
    }
}

struct HealthPhoneView: View {
    let overview: HealthOverview
    let onPresent: (HealthDetail) -> Void

    var body: some View {
        HealthDashboardContent(overview: overview, includesTitle: false, compact: true, onPresent: onPresent)
    }
}

private struct HealthDashboardContent: View {
    let overview: HealthOverview
    let includesTitle: Bool
    let compact: Bool
    let onPresent: (HealthDetail) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: compact ? 16 : 20) {
                header

                if let vaccination = overview.upcomingVaccination {
                    UpcomingHealthCard(
                        vaccination: vaccination,
                        visit: overview.upcomingVisit,
                        onSelect: { onPresent(.vaccination(vaccination)) }
                    )
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        vaccinationHistory
                        MedicationCard(
                            history: overview.medicationHistory,
                            showsHistory: false,
                            onShowHistory: { onPresent(.medicationHistory) }
                        )
                    }
                    VStack(spacing: 14) {
                        vaccinationHistory
                        MedicationCard(
                            history: overview.medicationHistory,
                            showsHistory: false,
                            onShowHistory: { onPresent(.medicationHistory) }
                        )
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        healthObservation
                        VisitsCard(
                            visits: Array(overview.visits.dropFirst()),
                            showsAll: true,
                            onSelect: { onPresent(.visit($0)) }
                        )
                    }
                    VStack(spacing: 14) {
                        healthObservation
                        VisitsCard(
                            visits: Array(overview.visits.dropFirst()),
                            showsAll: true,
                            onSelect: { onPresent(.visit($0)) }
                        )
                    }
                }

                DocumentsCard(
                    documents: overview.documents,
                    showsStorageNote: false,
                    onSelect: { onPresent(.document($0)) },
                    onShowAll: {}
                )
            }
            .frame(maxWidth: 1_080, alignment: .leading)
            .padding(compact ? 18 : 28)
        }
        .appCanvas()
        .accessibilityIdentifier("health.screen")
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                titleBlock
                Spacer()
                addButton
            }
            VStack(alignment: .leading, spacing: 12) {
                titleBlock
                addButton
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            if includesTitle {
                Text("Salud")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("Cuidados, observaciones e historial de Neo")
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private var addButton: some View {
        Button {
            onPresent(.addRecord)
        } label: {
            Label("Añadir registro", systemImage: "plus")
                .frame(minHeight: 34)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("health.addRecord")
    }

    private var vaccinationHistory: some View {
        VaccinationTimelineCard(
            vaccinations: Array(overview.vaccinations.filter { $0.status == .completed }.suffix(2)),
            onSelect: { onPresent(.vaccination($0)) }
        )
    }

    private var healthObservation: some View {
        let observation = DailyCarePreviewData.observations.first { $0.context == .health }!
        return VStack(alignment: .leading, spacing: 8) {
            Label("Observación reciente", systemImage: "waveform.path.ecg")
                .font(.headline)
            Text(observation.title).font(.subheadline.weight(.semibold))
            Text(observation.body)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
            Text("Este registro es una observación personal y no sustituye la valoración veterinaria.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .appSurface()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("health.observations")
    }
}

#Preview("Salud · macOS") {
    HealthMacView(overview: HealthPreviewData.neoOverview, onPresent: { _ in })
        .frame(width: 1_100, height: 860)
}

#Preview("Salud · iPhone") {
    NavigationStack {
        HealthPhoneView(overview: HealthPreviewData.neoOverview, onPresent: { _ in })
    }
    .frame(width: 393, height: 852)
}
