import SwiftUI

struct HealthMacView: View {
    let overview: HealthOverview
    @Binding var selectedSection: HealthSection
    let onPresent: (HealthDetail) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HealthHeader(includesTitle: true) {
                    onPresent(.addRecord)
                }
                HealthSectionSelector(selection: $selectedSection)
                    .frame(maxWidth: 720)

                HealthSectionContent(
                    section: selectedSection,
                    overview: overview,
                    compact: false,
                    onPresent: onPresent,
                    onSelectSection: { selectedSection = $0 }
                )
            }
            .frame(maxWidth: 1_180, alignment: .leading)
            .padding(32)
        }
        .appCanvas()
        .accessibilityIdentifier("health.screen")
    }
}

struct HealthPhoneView: View {
    let overview: HealthOverview
    @Binding var selectedSection: HealthSection
    let onPresent: (HealthDetail) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HealthHeader(includesTitle: false) {
                    onPresent(.addRecord)
                }
                HealthSectionSelector(selection: $selectedSection)

                HealthSectionContent(
                    section: selectedSection,
                    overview: overview,
                    compact: true,
                    onPresent: onPresent,
                    onSelectSection: { selectedSection = $0 }
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .appCanvas()
        .accessibilityIdentifier("health.screen")
    }
}

private struct HealthHeader: View {
    let includesTitle: Bool
    let onAddRecord: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 20) {
                titleBlock
                Spacer(minLength: 12)
                addButton
            }
            VStack(alignment: .leading, spacing: 14) {
                titleBlock
                addButton
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            if includesTitle {
                Text("Salud")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("El historial de bienestar de Neo, claro y ordenado.")
                .font(includesTitle ? .title3 : .subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var addButton: some View {
        Button(action: onAddRecord) {
            Label("Añadir registro", systemImage: "plus")
                .frame(minHeight: 32)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityIdentifier("health.addRecord")
    }
}

#Preview("Salud · macOS") {
    HealthMacView(
        overview: HealthPreviewData.neoOverview,
        selectedSection: .constant(.overview),
        onPresent: { _ in }
    )
    .frame(width: 1_100, height: 860)
}

#Preview("Salud · iPhone") {
    NavigationStack {
        HealthPhoneView(
            overview: HealthPreviewData.neoOverview,
            selectedSection: .constant(.overview),
            onPresent: { _ in }
        )
        .navigationTitle("Salud")
    }
    .frame(width: 393, height: 852)
}
