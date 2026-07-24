import SwiftUI

struct SettingsView: View {
    @State private var selectedSection: SettingsSection = .profile
    @State private var weightUnit: WeightUnit = .kilograms
    @State private var distanceUnit: DistanceUnit = .kilometers
    @State private var reminderPreferences = SettingsPreviewData.reminderPreferences
    @State private var presentedAction: SettingsFutureAction?

    var body: some View {
        Group {
            #if os(macOS)
            SettingsMacView(
                overview: SettingsPreviewData.overview,
                selectedSection: $selectedSection,
                weightUnit: $weightUnit,
                distanceUnit: $distanceUnit,
                reminderPreferences: $reminderPreferences,
                onPresent: { presentedAction = $0 }
            )
            #else
            SettingsPhoneView(
                overview: SettingsPreviewData.overview,
                selectedSection: $selectedSection,
                weightUnit: $weightUnit,
                distanceUnit: $distanceUnit,
                reminderPreferences: $reminderPreferences,
                onPresent: { presentedAction = $0 }
            )
            #endif
        }
        .environment(\.locale, SettingsFormatting.spanishLocale)
        .sheet(item: $presentedAction) { action in
            SettingsDetailSheet(
                action: action,
                profile: SettingsPreviewData.neoProfile,
                onDismiss: { presentedAction = nil }
            )
        }
    }
}

#Preview("Ajustes · macOS") {
    SettingsMacView(
        overview: SettingsPreviewData.overview,
        selectedSection: .constant(.profile),
        weightUnit: .constant(.kilograms),
        distanceUnit: .constant(.kilometers),
        reminderPreferences: .constant(SettingsPreviewData.reminderPreferences),
        onPresent: { _ in }
    )
    .frame(width: 1_180, height: 900)
}

#Preview("Ajustes · iPhone") {
    NavigationStack {
        SettingsPhoneView(
            overview: SettingsPreviewData.overview,
            selectedSection: .constant(.profile),
            weightUnit: .constant(.kilograms),
            distanceUnit: .constant(.kilometers),
            reminderPreferences: .constant(SettingsPreviewData.reminderPreferences),
            onPresent: { _ in }
        )
        .navigationTitle("Ajustes")
    }
    .frame(width: 393, height: 852)
}
