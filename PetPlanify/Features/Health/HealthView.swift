import SwiftUI

struct HealthView: View {
    @State private var presentedDetail: HealthDetail?

    private let overview = HealthPreviewData.neoOverview

    var body: some View {
        Group {
            #if os(macOS)
            HealthMacView(
                overview: overview,
                onPresent: { presentedDetail = $0 }
            )
            #else
            HealthPhoneView(
                overview: overview,
                onPresent: { presentedDetail = $0 }
            )
            #endif
        }
        .environment(\.locale, HealthFormatting.spanishLocale)
        .sheet(item: $presentedDetail) { detail in
            HealthDetailSheet(
                detail: detail,
                overview: overview,
                onDismiss: { presentedDetail = nil }
            )
        }
    }
}
