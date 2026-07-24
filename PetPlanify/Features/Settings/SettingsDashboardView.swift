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
    private let foodPlan = NutritionPreviewData.neoPlan

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                SettingsProfileHeader(
                    profile: overview.profile,
                    weightUnit: weightUnit,
                    compact: compact,
                    onEdit: { onPresent(.editProfile) }
                )
                feedingCard
                healthCard
                preferencesCard
                dataPrivacyCard
                aboutCard
            }
            .frame(maxWidth: 900, alignment: .leading)
            .padding(compact ? 16 : 18)
            .padding(.bottom, compact ? 12 : 0)
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
            Text("Perfil y configuración de PetPlanify")
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private var feedingCard: some View {
        SettingsGroupCard("Alimentación", symbol: "fork.knife", identifier: "settings.feeding") {
            SettingsValueRow(label: "Alimento", value: foodPlan.currentFood.name)
            divider
            SettingsValueRow(label: "Cantidad diaria", value: NutritionFormatting.grams(foodPlan.dailyAmountGrams))
            divider
            SettingsValueRow(label: "Comidas", value: "\(foodPlan.mealsPerDay) al día")
            divider
            actionRow("Editar alimentación", detail: "Producto, cantidades y horarios") {
                onPresent(.foodPlan)
            }
        }
    }

    private var healthCard: some View {
        SettingsGroupCard("Salud", symbol: "cross.case", identifier: "settings.health") {
            SettingsValueRow(label: "Clínica veterinaria", value: overview.profile.veterinaryClinic)
            divider
            SettingsValueRow(label: "Microchip", value: overview.profile.microchipStatus)
            divider
            SettingsValueRow(
                label: "Rango saludable opcional",
                value: overview.profile.healthyWeightRangeKilograms.map(weightUnit.formattedRange) ?? "No indicado"
            )
            divider
            actionRow("Editar datos de salud", detail: "Valores introducidos manualmente") {
                onPresent(.healthData)
            }
        }
    }

    private var preferencesCard: some View {
        SettingsGroupCard("Preferencias", symbol: "slider.horizontal.3", identifier: "settings.preferences") {
            SettingsValueRow(label: "Idioma", value: overview.preferences.language.title)
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
            SettingsToggleRow(title: "Recordatorios de salud", isOn: $reminderPreferences.healthEnabled, identifier: "settings.reminder.health")
            SettingsToggleRow(title: "Recordatorios de alimentación", isOn: $reminderPreferences.nutritionEnabled, identifier: "settings.reminder.nutrition")
            SettingsToggleRow(title: "Recordatorios de entrenamiento", isOn: $reminderPreferences.trainingEnabled, identifier: "settings.reminder.training")
            Picker("Avisar con", selection: $reminderPreferences.advanceTime) {
                ForEach(ReminderAdvanceTime.allCases) { value in
                    Text(value.title).tag(value)
                }
            }
            Text("Las notificaciones reales se configurarán en una fase posterior.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .accessibilityIdentifier("settings.units")
    }

    private var dataPrivacyCard: some View {
        SettingsGroupCard("Datos y privacidad", symbol: "hand.raised", identifier: "settings.privacy") {
            Text("Los datos actuales son de demostración y todavía no se guardan de forma permanente.")
                .font(.subheadline)
            divider
            actionRow("Almacenamiento, iCloud y copias", detail: "Más adelante") {
                onPresent(.localStorage)
            }
            divider
            Text("Esta versión no envía datos a servidores externos ni utiliza análisis o publicidad.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .accessibilityIdentifier("settings.data")
    }

    private var aboutCard: some View {
        SettingsGroupCard("Acerca de", symbol: "info.circle", identifier: "settings.about") {
            SettingsValueRow(label: "PetPlanify", value: overview.appInformation.tagline)
            divider
            SettingsValueRow(label: "Versión", value: "\(overview.appInformation.version) (\(overview.appInformation.build))")
            divider
            SettingsValueRow(label: "Plataformas", value: overview.appInformation.platforms)
            divider
            Text("PetPlanify reúne la alimentación, salud y entrenamiento de Neo en un único espacio.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(overview.appInformation.credit)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private func actionRow(
        _ title: LocalizedStringKey,
        detail: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(detail).font(.caption).foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.ink)
    }
}
