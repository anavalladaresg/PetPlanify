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
                if let care = nextCare {
                    UpcomingHealthCard(
                        title: care.title,
                        date: care.date,
                        context: care.context,
                        symbol: care.symbol
                    ) {
                        onPresent(care.destination)
                    }
                }

                HealthWeightCard(overview: overview, compact: compact) {
                    onPresent(.registerWeight)
                }

                if compact {
                    VStack(spacing: 12) {
                        vaccinationCard
                        DewormingCard(
                            records: overview.dewormingRecords,
                            onShowHistory: { onPresent(.dewormingHistory) },
                            onAdd: { onPresent(.addDeworming) }
                        )
                        MedicationCard(overview: overview) {
                            onPresent(.medicationHistory)
                        }
                    }
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 14) {
                            vaccinationCard
                                .frame(minWidth: 340)
                            dewormingAndMedication
                                .frame(minWidth: 380)
                        }
                        VStack(spacing: 14) {
                            vaccinationCard
                            dewormingAndMedication
                        }
                    }
                }

                VisitsCard(visits: overview.visits) {
                    onPresent(.visit($0))
                }
            }
            .frame(maxWidth: 1_080, alignment: .leading)
            .padding(compact ? 16 : 28)
            .padding(.bottom, compact ? 12 : 0)
        }
        .appCanvas()
        .accessibilityIdentifier("health.screen")
    }

    private struct UpcomingCare {
        let title: String
        let date: Date
        let context: String
        let symbol: String
        let destination: HealthDetail
    }

    private var nextCare: UpcomingCare? {
        var care: [UpcomingCare] = []
        if let vaccination = overview.upcomingVaccination {
            care.append(
                UpcomingCare(
                    title: vaccination.title,
                    date: vaccination.date,
                    context: vaccination.clinic,
                    symbol: "syringe",
                    destination: .vaccination(vaccination)
                )
            )
        }
        if let visit = overview.upcomingVisit {
            care.append(
                UpcomingCare(
                    title: visit.reason,
                    date: visit.date,
                    context: visit.clinic,
                    symbol: "cross.case",
                    destination: .visit(visit)
                )
            )
        }
        for record in overview.dewormingRecords {
            guard let nextDueAt = record.nextDueAt, nextDueAt > Date.now else { continue }
            care.append(
                UpcomingCare(
                    title: record.kind.title,
                    date: nextDueAt,
                    context: record.productName ?? String(localized: "Cuidado registrado manualmente"),
                    symbol: record.kind.symbol,
                    destination: .dewormingHistory
                )
            )
        }
        return care.min { $0.date < $1.date }
    }

    private var header: some View {
        Group {
            if compact {
                titleBlock
            } else {
                HStack {
                    titleBlock
                    Spacer()
                    addButton
                }
            }
        }
    }

    private var vaccinationCard: some View {
        VaccinationTimelineCard(
            vaccinations: overview.vaccinations,
            maxRecords: compact ? 3 : 4,
            onSelect: { onPresent(.vaccination($0)) },
            onShowHistory: { onPresent(.vaccinationHistory) }
        )
    }

    private var dewormingAndMedication: some View {
        VStack(spacing: 14) {
            DewormingCard(
                records: overview.dewormingRecords,
                onShowHistory: { onPresent(.dewormingHistory) },
                onAdd: { onPresent(.addDeworming) }
            )
            MedicationCard(overview: overview) {
                onPresent(.medicationHistory)
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
