import SwiftUI

struct TrainingView: View {
    @State private var presentedDetail: TrainingDetail?

    private let overview = TrainingPreviewData.neoOverview

    var body: some View {
        Group {
            #if os(macOS)
            TrainingMacView(
                overview: overview,
                onPresent: { presentedDetail = $0 }
            )
            #else
            TrainingPhoneView(
                overview: overview,
                onPresent: { presentedDetail = $0 }
            )
            #endif
        }
        .environment(\.locale, TrainingFormatting.spanishLocale)
        .sheet(item: $presentedDetail) { detail in
            TrainingDetailSheet(
                detail: detail,
                onDismiss: { presentedDetail = nil }
            )
        }
    }
}
