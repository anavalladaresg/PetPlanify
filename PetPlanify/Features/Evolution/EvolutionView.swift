import SwiftUI

struct EvolutionView: View {
    @State private var selectedMetric: EvolutionMetric = .weight
    @State private var selectedRange: EvolutionRange = .sixMonths
    @State private var presentedMilestone: EvolutionMilestone?

    private let overview = EvolutionPreviewData.neoOverview

    var body: some View {
        Group {
            #if os(macOS)
            EvolutionMacView(
                overview: overview,
                selectedMetric: $selectedMetric,
                selectedRange: $selectedRange,
                onSelectMilestone: { presentedMilestone = $0 }
            )
            #else
            EvolutionPhoneView(
                overview: overview,
                selectedMetric: $selectedMetric,
                selectedRange: $selectedRange,
                onSelectMilestone: { presentedMilestone = $0 }
            )
            #endif
        }
        .environment(\.locale, EvolutionFormatting.spanishLocale)
        .sheet(item: $presentedMilestone) { milestone in
            EvolutionMilestoneDetailSheet(
                milestone: milestone,
                onDismiss: { presentedMilestone = nil }
            )
        }
    }
}
