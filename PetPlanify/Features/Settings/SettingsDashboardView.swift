import SwiftUI

struct SettingsMacView: View {
    let overview: SettingsOverview
    @Binding var weightUnit: WeightUnit
    @Binding var distanceUnit: DistanceUnit
    @Binding var reminderPreferences: ReminderPreferences
    let onPresent: (SettingsFutureAction) -> Void

    var body: some View {
        SettingsDashboardContent(
            overview: overview,
            weightUnit: $weightUnit,
            distanceUnit: $distanceUnit,
            reminderPreferences: $reminderPreferences,
            includesTitle: true,
            compact: false,
            onPresent: onPresent
        )
    }
}

struct SettingsPhoneView: View {
    let overview: SettingsOverview
    @Binding var weightUnit: WeightUnit
    @Binding var distanceUnit: DistanceUnit
    @Binding var reminderPreferences: ReminderPreferences
    let onPresent: (SettingsFutureAction) -> Void

    var body: some View {
        SettingsDashboardContent(
            overview: overview,
            weightUnit: $weightUnit,
            distanceUnit: $distanceUnit,
            reminderPreferences: $reminderPreferences,
            includesTitle: false,
            compact: true,
            onPresent: onPresent
        )
    }
}

private struct SettingsDashboardContent: View {
    let overview: SettingsOverview
    @Binding var weightUnit: WeightUnit
    @Binding var distanceUnit: DistanceUnit
    @Binding var reminderPreferences: ReminderPreferences
    let includesTitle: Bool
    let compact: Bool
    let onPresent: (SettingsFutureAction) -> Void

    private var divider: some View { Divider().overlay(AppTheme.border) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: compact ? 16 : 20) {
                header
                SettingsProfileHeader(
                    profile: overview.profile,
                    weightUnit: weightUnit,
                    onEdit: { onPresent(.editProfile) }
                )

                adaptive(first: preferencesCard, second: remindersCard)
                adaptive(first: dataPrivacyCard, second: aboutCard)
            }
            .frame(maxWidth: 1_080, alignment: .leading)
            .padding(compact ? 18 : 28)
        }
        .appCanvas()
        .accessibilityIdentifier("settings.screen")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            if includesTitle {
                Text("Ajustes")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("Perfil y preferencias de PetPlanify")
                .foregroundStyle(AppTheme.secondaryInk)
            Text("Los cambios de esta versión son temporales.")
                .font(.caption)
                .foregroundStyle(AppTheme.orange)
        }
    }

    private var preferencesCard: some View {
        SettingsGroupCard("Preferencias", symbol: "slider.horizontal.3", identifier: "settings.preferences") {
            SettingsValueRow(label: "Idioma", value: overview.preferences.language.title)
            divider
            SettingsValueRow(label: "Formato", value: "\(overview.preferences.dateFormat) · \(overview.preferences.timeFormat.title)")
            divider
            SettingsSelectionCard(
                title: "Peso",
                detail: "Solo cambia los valores mostrados aquí.",
                options: WeightUnit.allCases,
                selection: $weightUnit,
                label: \.title,
                identifier: "settings.weightUnit"
            )
            divider
            SettingsSelectionCard(
                title: "Distancia",
                detail: "Preferencia temporal.",
                options: DistanceUnit.allCases,
                selection: $distanceUnit,
                label: \.title,
                identifier: "settings.distanceUnit"
            )
            divider
            Button {
                onPresent(.appearance)
            } label: {
                SettingsValueRow(label: "Apariencia", value: overview.preferences.appearance, symbol: "sun.max", accent: AppTheme.orange)
            }
            .buttonStyle(.plain)
        }
        .accessibilityIdentifier("settings.units")
    }

    private var remindersCard: some View {
        SettingsGroupCard("Recordatorios", symbol: "bell", identifier: "settings.reminders") {
            SettingsToggleRow(title: "Salud", isOn: $reminderPreferences.healthEnabled, identifier: "settings.reminder.health")
            divider
            SettingsToggleRow(title: "Alimentación", isOn: $reminderPreferences.nutritionEnabled, identifier: "settings.reminder.nutrition")
            divider
            SettingsToggleRow(title: "Entrenamiento", isOn: $reminderPreferences.trainingEnabled, identifier: "settings.reminder.training")
            divider
            Picker("Avisar con", selection: $reminderPreferences.advanceTime) {
                ForEach(ReminderAdvanceTime.allCases) { value in
                    Text(value.title).tag(value)
                }
            }
            .accessibilityIdentifier("settings.reminder.advance")
            Text("Las notificaciones reales se configurarán en una fase posterior.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private var dataPrivacyCard: some View {
        SettingsGroupCard("Datos y privacidad", symbol: "hand.raised", identifier: "settings.privacy") {
            Text("Los datos actuales son de demostración y todavía no se guardan de forma permanente.")
                .font(.subheadline)
            divider
            Button {
                onPresent(.localStorage)
            } label: {
                HStack {
                    Label("Almacenamiento, iCloud y copias", systemImage: "internaldrive")
                    Spacer()
                    Text("Más adelante")
                        .font(.caption)
                        .foregroundStyle(AppTheme.orange)
                    Image(systemName: "chevron.right").accessibilityHidden(true)
                }
                .frame(minHeight: 42)
                .foregroundStyle(AppTheme.ink)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Almacenamiento, iCloud y copias, no disponible todavía")
            divider
            Text("Esta versión no envía datos a servidores externos ni utiliza análisis o publicidad.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .accessibilityIdentifier("settings.data")
    }

    private var aboutCard: some View {
        SettingsGroupCard("Acerca de", symbol: "info.circle", identifier: "settings.about") {
            SettingsValueRow(label: overview.appInformation.name, value: overview.appInformation.tagline)
            divider
            SettingsValueRow(label: "Versión", value: "\(overview.appInformation.version) (\(overview.appInformation.build))")
            divider
            SettingsValueRow(label: "Plataformas", value: overview.appInformation.platforms)
            divider
            Text(overview.appInformation.description)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(overview.appInformation.credit)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    @ViewBuilder
    private func adaptive<First: View, Second: View>(first: First, second: Second) -> some View {
        if compact {
            VStack(spacing: 16) { first; second }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) { first; second }
                VStack(spacing: 16) { first; second }
            }
        }
    }
}
