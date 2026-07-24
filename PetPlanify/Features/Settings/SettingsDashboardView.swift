import SwiftUI

struct SettingsMacView: View {
    let overview: SettingsOverview
    @Binding var selectedSection: SettingsSection
    @Binding var weightUnit: WeightUnit
    @Binding var distanceUnit: DistanceUnit
    @Binding var reminderPreferences: ReminderPreferences
    let onPresent: (SettingsFutureAction) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsHeader(includesTitle: true)
                SettingsSectionSelector(selection: $selectedSection)
                    .frame(maxWidth: 800)
                SettingsSectionContent(
                    section: selectedSection,
                    overview: overview,
                    weightUnit: $weightUnit,
                    distanceUnit: $distanceUnit,
                    reminderPreferences: $reminderPreferences,
                    compact: false,
                    onPresent: onPresent
                )
            }
            .frame(maxWidth: 1_180, alignment: .leading)
            .padding(32)
        }
        .appCanvas()
        .accessibilityIdentifier("settings.screen")
    }
}

struct SettingsPhoneView: View {
    let overview: SettingsOverview
    @Binding var selectedSection: SettingsSection
    @Binding var weightUnit: WeightUnit
    @Binding var distanceUnit: DistanceUnit
    @Binding var reminderPreferences: ReminderPreferences
    let onPresent: (SettingsFutureAction) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SettingsHeader(includesTitle: false)
                SettingsSectionSelector(selection: $selectedSection)
                SettingsSectionContent(
                    section: selectedSection,
                    overview: overview,
                    weightUnit: $weightUnit,
                    distanceUnit: $distanceUnit,
                    reminderPreferences: $reminderPreferences,
                    compact: true,
                    onPresent: onPresent
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .appCanvas()
        .accessibilityIdentifier("settings.screen")
    }
}

private struct SettingsHeader: View {
    let includesTitle: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if includesTitle {
                Text("Ajustes")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("Personaliza la experiencia de Neo y consulta cómo gestiona PetPlanify sus datos.")
                .font(includesTitle ? .title3 : .subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)

            Label(
                "Los cambios realizados en esta versión son temporales.",
                systemImage: "clock.arrow.circlepath"
            )
            .font(.caption)
            .foregroundStyle(AppTheme.orange)
            .padding(.top, 2)
            .accessibilityElement(children: .combine)
        }
    }
}

struct SettingsSectionContent: View {
    let section: SettingsSection
    let overview: SettingsOverview
    @Binding var weightUnit: WeightUnit
    @Binding var distanceUnit: DistanceUnit
    @Binding var reminderPreferences: ReminderPreferences
    let compact: Bool
    let onPresent: (SettingsFutureAction) -> Void

    var body: some View {
        Group {
            switch section {
            case .profile:
                SettingsProfileSection(
                    profile: overview.profile,
                    weightUnit: weightUnit,
                    compact: compact,
                    onEdit: { onPresent(.editProfile) }
                )
            case .preferences:
                SettingsPreferencesSection(
                    preferences: overview.preferences,
                    weightUnit: $weightUnit,
                    distanceUnit: $distanceUnit,
                    reminderPreferences: $reminderPreferences,
                    compact: compact,
                    onPresent: onPresent
                )
            case .dataPrivacy:
                SettingsDataPrivacySection(
                    dataSummaries: overview.dataSummaries,
                    compact: compact,
                    onPresent: onPresent
                )
            case .about:
                SettingsAboutSection(
                    information: overview.appInformation,
                    compact: compact
                )
            }
        }
    }
}
