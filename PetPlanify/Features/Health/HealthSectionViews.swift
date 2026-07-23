import SwiftUI

struct HealthSectionContent: View {
    let section: HealthSection
    let overview: HealthOverview
    let compact: Bool
    let onPresent: (HealthDetail) -> Void
    let onSelectSection: (HealthSection) -> Void

    @ViewBuilder
    var body: some View {
        switch section {
        case .overview:
            HealthSummaryContent(
                overview: overview,
                compact: compact,
                onPresent: onPresent,
                onSelectSection: onSelectSection
            )
        case .vaccinations:
            VaccinationsSectionView(overview: overview, onPresent: onPresent)
        case .medications:
            MedicationsSectionView(overview: overview, onPresent: onPresent)
        case .symptoms:
            SymptomsSectionView(overview: overview, onPresent: onPresent)
        case .visits:
            VisitsSectionView(overview: overview, onPresent: onPresent)
        case .documents:
            DocumentsSectionView(overview: overview, onPresent: onPresent)
        }
    }
}

private struct HealthSummaryContent: View {
    let overview: HealthOverview
    let compact: Bool
    let onPresent: (HealthDetail) -> Void
    let onSelectSection: (HealthSection) -> Void

    var body: some View {
        VStack(spacing: compact ? 16 : 18) {
            if let vaccination = overview.upcomingVaccination {
                UpcomingHealthCard(
                    vaccination: vaccination,
                    visit: overview.upcomingVisit,
                    onSelect: { onPresent(.vaccination(vaccination)) }
                )
            }

            if compact {
                compactContent
            } else {
                desktopContent
            }
        }
    }

    private var compactContent: some View {
        VStack(spacing: 16) {
            vaccinationCard
            medicationCard
            symptomsCard
            visitsCard
            documentsCard
        }
    }

    private var desktopContent: some View {
        VStack(spacing: 18) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    vaccinationCard
                        .frame(minWidth: 500)
                    VStack(spacing: 18) {
                        medicationCard
                        symptomsCard
                    }
                    .frame(minWidth: 330)
                }
                compactContent
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    visitsCard
                    documentsCard
                }
                VStack(spacing: 18) {
                    visitsCard
                    documentsCard
                }
            }
        }
    }

    private var vaccinationCard: some View {
        VaccinationTimelineCard(
            vaccinations: overview.vaccinations,
            onSelect: { onPresent(.vaccination($0)) }
        )
    }

    private var medicationCard: some View {
        MedicationCard(
            history: overview.medicationHistory,
            showsHistory: false,
            onShowHistory: { onSelectSection(.medications) }
        )
    }

    private var symptomsCard: some View {
        SymptomsCard(
            symptoms: overview.symptoms,
            showsAll: false,
            onSelect: { onPresent(.symptom($0)) }
        )
    }

    private var visitsCard: some View {
        VisitsCard(
            visits: overview.visits,
            showsAll: false,
            onSelect: { onPresent(.visit($0)) }
        )
    }

    private var documentsCard: some View {
        DocumentsCard(
            documents: overview.documents,
            showsStorageNote: false,
            onSelect: { onPresent(.document($0)) },
            onShowAll: { onSelectSection(.documents) }
        )
    }
}

private struct VaccinationsSectionView: View {
    let overview: HealthOverview
    let onPresent: (HealthDetail) -> Void

    var body: some View {
        VStack(spacing: 18) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) {
                    HealthSummaryMetric(
                        title: "Vacunas completadas",
                        value: overview.completedVaccinationCount.formatted(),
                        symbol: "checkmark.seal",
                        accent: AppTheme.green
                    )
                    if let upcoming = overview.upcomingVaccination {
                        HealthSummaryMetric(
                            title: "Próxima vacuna",
                            value: HealthFormatting.shortDate(upcoming.date),
                            symbol: "calendar.badge.clock",
                            accent: AppTheme.orange
                        )
                    }
                }
                VStack(spacing: 14) {
                    HealthSummaryMetric(
                        title: "Vacunas completadas",
                        value: overview.completedVaccinationCount.formatted(),
                        symbol: "checkmark.seal",
                        accent: AppTheme.green
                    )
                    if let upcoming = overview.upcomingVaccination {
                        HealthSummaryMetric(
                            title: "Próxima vacuna",
                            value: HealthFormatting.shortDate(upcoming.date),
                            symbol: "calendar.badge.clock",
                            accent: AppTheme.orange
                        )
                    }
                }
            }
            VaccinationTimelineCard(
                vaccinations: overview.vaccinations,
                onSelect: { onPresent(.vaccination($0)) }
            )
        }
    }
}

private struct MedicationsSectionView: View {
    let overview: HealthOverview
    let onPresent: (HealthDetail) -> Void

    var body: some View {
        MedicationCard(
            history: overview.medicationHistory,
            showsHistory: true,
            onShowHistory: { onPresent(.medicationHistory) }
        )
    }
}

private struct SymptomsSectionView: View {
    let overview: HealthOverview
    let onPresent: (HealthDetail) -> Void

    var body: some View {
        VStack(spacing: 14) {
            SymptomsCard(
                symptoms: overview.symptoms,
                showsAll: true,
                onSelect: { onPresent(.symptom($0)) }
            )
            Label(
                "Estos registros son observaciones personales y no sustituyen la valoración de un profesional veterinario.",
                systemImage: "info.circle"
            )
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryInk)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}

private struct VisitsSectionView: View {
    let overview: HealthOverview
    let onPresent: (HealthDetail) -> Void

    var body: some View {
        VisitsCard(
            visits: overview.visits,
            showsAll: true,
            onSelect: { onPresent(.visit($0)) }
        )
    }
}

private struct DocumentsSectionView: View {
    let overview: HealthOverview
    let onPresent: (HealthDetail) -> Void

    var body: some View {
        VStack(spacing: 14) {
            DocumentsCard(
                documents: overview.documents,
                showsStorageNote: true,
                onSelect: { onPresent(.document($0)) },
                onShowAll: {}
            )
            Button {
                onPresent(.addRecord)
            } label: {
                Label("Añadir documento", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("health.addDocument")
        }
    }
}

private struct HealthSummaryMetric: View {
    let title: LocalizedStringKey
    let value: String
    let symbol: String
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(accent)
                .frame(width: 42, height: 42)
                .background(accent.opacity(0.11), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                Text(value)
                    .font(.headline)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .appSurface(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Salud · Vacunas") {
    ScrollView {
        HealthSectionContent(
            section: .vaccinations,
            overview: HealthPreviewData.neoOverview,
            compact: true,
            onPresent: { _ in },
            onSelectSection: { _ in }
        )
        .padding()
    }
    .frame(width: 393, height: 800)
    .appCanvas()
}
