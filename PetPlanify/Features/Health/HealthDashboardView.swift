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
                    UpcomingHealthCard(vaccination: vaccination) {
                        onPresent(.vaccination(vaccination))
                    }
                }

                HealthWeightCard(overview: overview, compact: compact) {
                    onPresent(.registerWeight)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        VaccinationTimelineCard(vaccinations: overview.vaccinations) {
                            onPresent(.vaccination($0))
                        }
                        MedicationCard(overview: overview) {
                            onPresent(.medicationHistory)
                        }
                        .frame(minWidth: 300)
                    }
                    VStack(spacing: 14) {
                        VaccinationTimelineCard(vaccinations: overview.vaccinations) {
                            onPresent(.vaccination($0))
                        }
                        MedicationCard(overview: overview) {
                            onPresent(.medicationHistory)
                        }
                    }
                }

                VisitsCard(visits: overview.visits) {
                    onPresent(.visit($0))
                }
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
            VStack(alignment: .leading, spacing: 10) {
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
            Text("Peso, cuidados e historial veterinario de Neo")
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private var addButton: some View {
        Button {
            onPresent(.addRecord)
        } label: {
            Label("Añadir registro", systemImage: "plus")
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("health.addRecord")
    }
}

#Preview("Salud · macOS") {
    HealthMacView(overview: HealthPreviewData.neoOverview, onPresent: { _ in })
        .frame(width: 1_100, height: 900)
}

#Preview("Salud · iPhone") {
    NavigationStack {
        HealthPhoneView(overview: HealthPreviewData.neoOverview, onPresent: { _ in })
    }
    .frame(width: 393, height: 852)
}
