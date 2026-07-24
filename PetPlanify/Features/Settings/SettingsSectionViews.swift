import SwiftUI

struct SettingsProfileSection: View {
    let profile: PetProfileSettings
    let weightUnit: WeightUnit
    let compact: Bool
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            SettingsProfileHeader(
                profile: profile,
                weightUnit: weightUnit,
                onEdit: onEdit
            )

            if compact {
                identityCard
                careCard
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        identityCard
                        careCard
                    }
                    VStack(spacing: 18) {
                        identityCard
                        careCard
                    }
                }
            }
        }
    }

    private var identityCard: some View {
        SettingsGroupCard("Información del perfil", symbol: "pawprint") {
            SettingsValueRow(label: "Nombre", value: profile.name)
            rowDivider
            SettingsValueRow(label: "Especie", value: profile.species)
            rowDivider
            SettingsValueRow(label: "Raza", value: profile.breed)
            rowDivider
            SettingsValueRow(
                label: "Fecha de nacimiento",
                value: SettingsFormatting.date(profile.birthDate)
            )
            rowDivider
            SettingsValueRow(label: "Edad", value: profile.age)
            rowDivider
            SettingsValueRow(label: "Sexo", value: profile.sex)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var careCard: some View {
        SettingsGroupCard("Salud e identificación", symbol: "heart.text.square") {
            SettingsValueRow(
                label: "Peso actual",
                value: weightUnit.formattedWeight(kilograms: profile.currentWeightKilograms)
            )
            rowDivider
            SettingsValueRow(
                label: "Rango saludable",
                value: weightUnit.formattedRange(profile.healthyWeightRangeKilograms)
            )
            rowDivider
            SettingsValueRow(
                label: "Microchip",
                value: profile.microchipStatus,
                accent: AppTheme.orange
            )
            rowDivider
            SettingsValueRow(
                label: "Clínica veterinaria",
                value: profile.veterinaryClinic
            )
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var rowDivider: some View {
        Divider().overlay(AppTheme.border)
    }
}

struct SettingsPreferencesSection: View {
    let preferences: AppPreferences
    @Binding var weightUnit: WeightUnit
    @Binding var distanceUnit: DistanceUnit
    @Binding var reminderPreferences: ReminderPreferences
    let compact: Bool
    let onPresent: (SettingsFutureAction) -> Void

    var body: some View {
        VStack(spacing: 18) {
            adaptiveColumns(first: languageCard, second: unitsCard)
            adaptiveColumns(first: remindersCard, second: appearanceCard)
        }
    }

    private var languageCard: some View {
        SettingsGroupCard(
            "Idioma y región",
            symbol: "globe",
            identifier: "settings.preferences"
        ) {
            SettingsValueRow(label: "Idioma", value: preferences.language.title)
            rowDivider
            SettingsValueRow(label: "Formato de fecha", value: preferences.dateFormat)
            rowDivider
            SettingsValueRow(label: "Formato de hora", value: preferences.timeFormat.title)
            rowDivider
            SettingsValueRow(
                label: "Primer día de la semana",
                value: preferences.weekStartDay.title
            )
            Text("La interfaz está disponible actualmente en español.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .padding(.top, 7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var unitsCard: some View {
        SettingsGroupCard("Unidades", symbol: "ruler", identifier: "settings.units") {
            SettingsSelectionCard(
                title: "Peso",
                detail: "La selección solo actualiza los valores mostrados en Ajustes.",
                options: WeightUnit.allCases,
                selection: $weightUnit,
                label: \.title,
                identifier: "settings.weightUnit"
            )
            rowDivider
            SettingsSelectionCard(
                title: "Distancia",
                detail: "Esta preferencia es temporal.",
                options: DistanceUnit.allCases,
                selection: $distanceUnit,
                label: \.title,
                identifier: "settings.distanceUnit"
            )
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var remindersCard: some View {
        SettingsGroupCard(
            "Preferencias de recordatorios",
            symbol: "bell",
            identifier: "settings.reminders"
        ) {
            SettingsToggleRow(
                title: "Recordatorios de salud",
                isOn: $reminderPreferences.healthEnabled,
                identifier: "settings.reminder.health"
            )
            rowDivider
            SettingsToggleRow(
                title: "Recordatorios de alimentación",
                isOn: $reminderPreferences.nutritionEnabled,
                identifier: "settings.reminder.nutrition"
            )
            rowDivider
            SettingsToggleRow(
                title: "Recordatorios de entrenamiento",
                isOn: $reminderPreferences.trainingEnabled,
                identifier: "settings.reminder.training"
            )
            rowDivider
            HStack(spacing: 14) {
                Text("Avisar con")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                Spacer()
                Picker("Avisar con", selection: $reminderPreferences.advanceTime) {
                    ForEach(ReminderAdvanceTime.allCases) { advanceTime in
                        Text(advanceTime.title).tag(advanceTime)
                    }
                }
                .labelsHidden()
                .accessibilityLabel("Avisar con")
                .accessibilityValue(reminderPreferences.advanceTime.title)
                .accessibilityIdentifier("settings.reminder.advance")
            }
            .frame(minHeight: 42)

            Text("Las notificaciones reales se configurarán en una fase posterior.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .padding(.top, 5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var appearanceCard: some View {
        SettingsGroupCard(
            "Apariencia",
            symbol: "sun.max",
            identifier: "settings.appearance"
        ) {
            SettingsValueRow(
                label: "Apariencia actual",
                value: preferences.appearance,
                symbol: "sun.max",
                accent: AppTheme.orange
            )
            rowDivider
            SettingsActionRow(
                action: .appearance,
                detail: "Más opciones visuales"
            ) {
                onPresent(.appearance)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func adaptiveColumns<First: View, Second: View>(
        first: First,
        second: Second
    ) -> some View {
        if compact {
            VStack(spacing: 18) {
                first
                second
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    first
                    second
                }
                VStack(spacing: 18) {
                    first
                    second
                }
            }
        }
    }

    private var rowDivider: some View {
        Divider().overlay(AppTheme.border)
    }
}

struct SettingsDataPrivacySection: View {
    let dataSummaries: [DataCategorySummary]
    let compact: Bool
    let onPresent: (SettingsFutureAction) -> Void

    var body: some View {
        VStack(spacing: 18) {
            SettingsGroupCard(
                "Datos de demostración",
                symbol: "square.stack.3d.up",
                identifier: "settings.data"
            ) {
                SettingsDataSummaryGrid(items: dataSummaries, compact: compact)
                Label(
                    "Los datos actuales son de demostración y todavía no se guardan de forma permanente.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .padding(.top, 9)
                .fixedSize(horizontal: false, vertical: true)
            }

            if compact {
                storageCard
                privacyCard
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        storageCard
                        privacyCard
                    }
                    VStack(spacing: 18) {
                        storageCard
                        privacyCard
                    }
                }
            }
        }
    }

    private var storageCard: some View {
        SettingsGroupCard("Almacenamiento y copias", symbol: "internaldrive") {
            SettingsActionRow(
                action: .localStorage,
                detail: "Todavía no disponible"
            ) { onPresent(.localStorage) }
            rowDivider
            SettingsActionRow(
                action: .iCloud,
                detail: "No está activa"
            ) { onPresent(.iCloud) }
            rowDivider
            SettingsActionRow(
                action: .export,
                detail: "Acción informativa"
            ) { onPresent(.export) }
            rowDivider
            SettingsActionRow(
                action: .importData,
                detail: "Acción informativa"
            ) { onPresent(.importData) }
            rowDivider
            SettingsActionRow(
                action: .backup,
                detail: "Acción informativa"
            ) { onPresent(.backup) }
            rowDivider
            SettingsActionRow(
                action: .reset,
                detail: "No elimina ningún dato"
            ) { onPresent(.reset) }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var privacyCard: some View {
        SettingsGroupCard(
            "Privacidad",
            symbol: "hand.raised",
            identifier: "settings.privacy"
        ) {
            privacyStatement(
                "PetPlanify está diseñado para mantener la información de tu mascota bajo tu control.",
                symbol: "lock.shield"
            )
            rowDivider
            privacyStatement(
                "Esta versión no envía datos a servidores externos.",
                symbol: "network.slash"
            )
            rowDivider
            privacyStatement(
                "No se utilizan servicios de análisis ni publicidad.",
                symbol: "eye.slash"
            )
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func privacyStatement(_ text: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(AppTheme.green)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
    }

    private var rowDivider: some View {
        Divider().overlay(AppTheme.border)
    }
}

struct SettingsAboutSection: View {
    let information: AppInformation
    let compact: Bool

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AppTheme.greenSoft)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(AppTheme.green)
                        .accessibilityHidden(true)
                }
                .frame(width: 86, height: 86)

                Text(information.name)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                Text(information.tagline)
                    .font(.title3)
                    .foregroundStyle(AppTheme.secondaryInk)
                Text(information.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 650)
            }
            .frame(maxWidth: .infinity)
            .padding(compact ? 22 : 30)
            .appSurface()

            if compact {
                appDetailsCard
                developmentCard
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        appDetailsCard
                        developmentCard
                    }
                    VStack(spacing: 18) {
                        appDetailsCard
                        developmentCard
                    }
                }
            }

            Text(information.credit)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
        }
        .accessibilityIdentifier("settings.about")
    }

    private var appDetailsCard: some View {
        SettingsGroupCard("Información de la aplicación", symbol: "info.circle") {
            SettingsValueRow(label: "Versión", value: information.version)
            rowDivider
            SettingsValueRow(label: "Compilación", value: information.build)
            rowDivider
            SettingsValueRow(label: "Plataformas", value: information.platforms)
            rowDivider
            SettingsValueRow(
                label: "Idioma de la interfaz",
                value: information.interfaceLanguage
            )
            rowDivider
            SettingsValueRow(label: "Tecnología", value: information.technology)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var developmentCard: some View {
        SettingsGroupCard("Estado actual", symbol: "hammer") {
            aboutStatusRow(
                "Datos de demostración",
                detail: "Los contenidos actuales son locales y temporales.",
                symbol: "shippingbox"
            )
            rowDivider
            aboutStatusRow(
                "Sin servicios externos",
                detail: "La aplicación no utiliza redes, análisis ni publicidad.",
                symbol: "network.slash"
            )
            rowDivider
            aboutStatusRow(
                "Desarrollada con SwiftUI",
                detail: "Experiencia nativa para iPhone y Mac.",
                symbol: "swift"
            )
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func aboutStatusRow(
        _ title: String,
        detail: String,
        symbol: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(AppTheme.green)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
    }

    private var rowDivider: some View {
        Divider().overlay(AppTheme.border)
    }
}

#Preview("Ajustes · Perfil") {
    ScrollView {
        SettingsProfileSection(
            profile: SettingsPreviewData.neoProfile,
            weightUnit: .kilograms,
            compact: false,
            onEdit: {}
        )
        .padding()
    }
    .frame(width: 1_000, height: 760)
    .appCanvas()
}

#Preview("Ajustes · Preferencias") {
    ScrollView {
        SettingsPreferencesSection(
            preferences: SettingsPreviewData.preferences,
            weightUnit: .constant(.kilograms),
            distanceUnit: .constant(.kilometers),
            reminderPreferences: .constant(SettingsPreviewData.reminderPreferences),
            compact: false,
            onPresent: { _ in }
        )
        .padding()
    }
    .frame(width: 1_000, height: 800)
    .appCanvas()
}

#Preview("Ajustes · Datos y privacidad") {
    ScrollView {
        SettingsDataPrivacySection(
            dataSummaries: SettingsPreviewData.dataSummaries,
            compact: false,
            onPresent: { _ in }
        )
        .padding()
    }
    .frame(width: 1_000, height: 800)
    .appCanvas()
}
