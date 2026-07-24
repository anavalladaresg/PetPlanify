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
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentedDetail = .addRecord
                } label: {
                    Label("Añadir registro", systemImage: "plus")
                }
                .accessibilityIdentifier("health.addRecord")
            }
        }
        #endif
        .sheet(item: $presentedDetail) { detail in
            HealthDetailSheet(
                detail: detail,
                overview: overview,
                onDismiss: { presentedDetail = nil }
            )
        }
    }
}
