import SwiftUI

struct EvolutionView: View {
    @State private var selectedSection: EvolutionSection = .summary
    @State private var selectedRange: EvolutionRange = .sixMonths
    @State private var selectedCategory: EvolutionMilestoneFilter = .all
    @State private var presentedMilestone: EvolutionMilestone?

    private let overview = EvolutionPreviewData.neoOverview

    var body: some View {
        Group {
            #if os(macOS)
            EvolutionMacView(
                overview: overview,
                selectedSection: $selectedSection,
                selectedRange: $selectedRange,
                selectedCategory: $selectedCategory,
                onSelectMilestone: { presentedMilestone = $0 }
            )
            #else
            EvolutionPhoneView(
                overview: overview,
                selectedSection: $selectedSection,
                selectedRange: $selectedRange,
                selectedCategory: $selectedCategory,
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
