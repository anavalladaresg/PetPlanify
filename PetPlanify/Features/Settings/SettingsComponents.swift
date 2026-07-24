import SwiftUI

struct SettingsGroupCard<Content: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    let identifier: String?
    @ViewBuilder let content: Content

    init(
        _ title: LocalizedStringKey,
        symbol: String,
        identifier: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.identifier = identifier
        self.content = content()
    }

    var body: some View {
        Group {
            if let identifier {
                card.accessibilityIdentifier(identifier)
            } else {
                card
            }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
            } icon: {
                Image(systemName: symbol)
                    .foregroundStyle(AppTheme.green)
                    .accessibilityHidden(true)
            }
            .padding(.bottom, 7)

            content
        }
        .padding(19)
        .appSurface()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsValueRow: View {
    let label: LocalizedStringKey
    let value: String
    var symbol: String? = nil
    var accent: Color = AppTheme.green

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.subheadline)
                    .foregroundStyle(accent)
                    .frame(width: 22)
                    .accessibilityHidden(true)
            }
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
            Spacer(minLength: 14)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: 38)
        .accessibilityElement(children: .combine)
    }
}

struct SettingsToggleRow: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool
    let identifier: String

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.ink)
                Text(isOn ? "Activado localmente" : "Desactivado localmente")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(.switch)
        .tint(AppTheme.green)
        .frame(minHeight: 48)
        .accessibilityHint(
            isOn
                ? "Desactiva esta preferencia temporal"
                : "Activa esta preferencia temporal"
        )
        .accessibilityIdentifier(identifier)
    }
}

struct SettingsSelectionCard<Option: CaseIterable & Identifiable & Hashable>: View
where Option.AllCases: RandomAccessCollection {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let options: Option.AllCases
    @Binding var selection: Option
    let label: (Option) -> String
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.medium))
            Text(detail)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
            Picker(title, selection: $selection) {
                ForEach(options) { option in
                    Text(label(option)).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(identifier)
        }
        .padding(.vertical, 4)
    }
}

struct SettingsProfileHeader: View {
    let profile: PetProfileSettings
    let weightUnit: WeightUnit
    let compact: Bool
    let onEdit: () -> Void

    var body: some View {
        Group {
            if compact {
                VStack(alignment: .leading, spacing: 16) {
                    profileIdentity
                    profileMetrics
                    editButton
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 20) {
                        profileIdentity
                        Spacer(minLength: 16)
                        profileMetrics
                        editButton
                    }
                    VStack(alignment: .leading, spacing: 18) {
                        profileIdentity
                        profileMetrics
                        editButton
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 16 : 22)
        .appSurface()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings.profile")
    }

    private var profileIdentity: some View {
        HStack(spacing: 15) {
            PetAvatarView(size: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.system(.title, design: .serif, weight: .semibold))
                Text("\(profile.breed) · \(profile.age)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                Label(profile.veterinaryClinic, systemImage: "cross.case")
                    .font(.caption)
                    .foregroundStyle(AppTheme.green)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(profile.name), \(profile.breed), \(profile.age), clínica veterinaria \(profile.veterinaryClinic)"
        )
    }

    private var profileMetrics: some View {
        HStack(spacing: 10) {
            metric(
                "Peso actual",
                weightUnit.formattedWeight(kilograms: profile.currentWeightKilograms)
            )
            metric(
                "Rango saludable",
                profile.healthyWeightRangeKilograms.map(weightUnit.formattedRange) ?? "No indicado"
            )
        }
        .frame(maxWidth: compact ? .infinity : nil, alignment: .leading)
    }

    private func metric(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(AppTheme.surfaceMuted.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var editButton: some View {
        Button(action: onEdit) {
            Label("Editar perfil", systemImage: "pencil")
                .frame(minHeight: 32)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .frame(maxWidth: compact ? .infinity : nil, alignment: .leading)
        .accessibilityHint("Abre una vista previa sin almacenamiento")
        .accessibilityIdentifier("settings.editProfile")
    }
}

#Preview("Grupo de ajustes") {
    SettingsGroupCard("Idioma y región", symbol: "globe") {
        SettingsValueRow(label: "Idioma", value: "Español")
        Divider().overlay(AppTheme.border)
        SettingsValueRow(label: "Formato de hora", value: "24 horas")
    }
    .frame(width: 430)
    .padding()
    .appCanvas()
}
