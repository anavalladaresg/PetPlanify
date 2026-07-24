import SwiftUI

struct SettingsDetailSheet: View {
    let action: SettingsFutureAction
    let profile: PetProfileSettings
    let onDismiss: () -> Void

    @ViewBuilder
    var body: some View {
        #if os(macOS)
        sheetContent
            .frame(minWidth: 380, idealWidth: 600, minHeight: 420, idealHeight: 600)
        #else
        sheetContent
            .presentationDetents([.large])
        #endif
    }

    private var sheetContent: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if action == .editProfile {
                        profileEditor
                    } else {
                        information
                    }
                }
                .frame(maxWidth: 620, alignment: .leading)
                .padding(24)
            }
            .appCanvas()
            .navigationTitle(action.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar", action: onDismiss)
                }
            }
        }
    }

    private var profileEditor: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 15) {
                PetAvatarView(size: 68)
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.system(.title2, design: .serif, weight: .semibold))
                    Text("Vista previa del perfil")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
            }

            SettingsGroupCard("Datos de Neo", symbol: "pawprint") {
                previewField("Foto", value: "Avatar local de Neo")
                rowDivider
                previewField("Nombre", value: profile.name)
                rowDivider
                previewField("Especie", value: profile.species)
                rowDivider
                previewField("Raza", value: profile.breed)
                rowDivider
                previewField(
                    "Fecha de nacimiento",
                    value: SettingsFormatting.date(profile.birthDate)
                )
                rowDivider
                previewField("Edad aproximada", value: profile.age)
                rowDivider
                previewField("Sexo", value: profile.sex)
                rowDivider
                previewField(
                    "Peso actual",
                    value: WeightUnit.kilograms.formattedWeight(kilograms: profile.currentWeightKilograms)
                )
                rowDivider
                previewField(
                    "Rango saludable opcional",
                    value: profile.healthyWeightRangeKilograms.map(WeightUnit.kilograms.formattedRange) ?? "No indicado"
                )
                rowDivider
                previewField("Clínica veterinaria", value: profile.veterinaryClinic)
                rowDivider
                previewField("Microchip opcional", value: profile.microchipStatus)
            }

            limitation(
                "La edición del perfil estará disponible cuando se añada el almacenamiento de PetPlanify."
            )
        }
        .accessibilityIdentifier("settings.editProfile.sheet")
    }

    private var information: some View {
        VStack(alignment: .leading, spacing: 22) {
            Image(systemName: action.symbol)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(AppTheme.orange)
                .frame(width: 64, height: 64)
                .background(AppTheme.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(action.title)
                    .font(.system(.title, design: .serif, weight: .semibold))
                Text(action.explanation)
                    .font(.body)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            limitation(
                "Esta pantalla es informativa. No se guardan cambios ni se accede a archivos o servicios externos."
            )
        }
        .padding(4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings.futureState.\(action.rawValue)")
    }

    private func previewField(_ label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(value)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                .padding(.horizontal, 11)
                .background(
                    AppTheme.surfaceMuted.opacity(0.55),
                    in: RoundedRectangle(cornerRadius: 10)
                )
        }
        .accessibilityElement(children: .combine)
    }

    private func limitation(_ text: LocalizedStringKey) -> some View {
        Label(text, systemImage: "info.circle")
            .font(.subheadline)
            .foregroundStyle(AppTheme.secondaryInk)
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.greenSoft.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var rowDivider: some View {
        Divider().overlay(AppTheme.border)
    }
}

#Preview("Editor de perfil futuro") {
    SettingsDetailSheet(
        action: .editProfile,
        profile: SettingsPreviewData.neoProfile,
        onDismiss: {}
    )
}
