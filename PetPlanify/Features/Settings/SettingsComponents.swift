import SwiftUI

struct SettingsSectionSelector: View {
    @Binding var selection: SettingsSection

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                sectionButtons
            }
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 138), spacing: 6)],
                spacing: 6
            ) {
                sectionButtons
            }
        }
        .padding(4)
        .background(AppTheme.surface.opacity(0.66), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.border, lineWidth: 0.75)
        )
        .accessibilityIdentifier("settings.sectionPicker")
    }

    @ViewBuilder
    private var sectionButtons: some View {
        ForEach(SettingsSection.allCases) { section in
            Button {
                selection = section
            } label: {
                Text(section.title)
                    .font(.subheadline.weight(selection == section ? .semibold : .regular))
                    .foregroundStyle(selection == section ? AppTheme.ink : AppTheme.secondaryInk)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selection == section ? AppTheme.surfaceMuted : .clear)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(selection == section ? .isSelected : [])
            .accessibilityIdentifier("settings.section.\(section.rawValue)")
        }
    }
}

struct SettingsGroupCard<Content: View>: View {
    let title: String
    let symbol: String
    let identifier: String?
    @ViewBuilder let content: Content

    init(
        _ title: String,
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
    }
}

struct SettingsValueRow: View {
    let label: String
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
        .accessibilityLabel("\(label), \(value)")
    }
}

struct SettingsActionRow: View {
    let action: SettingsFutureAction
    let detail: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: action.symbol)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.orange)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.orange.opacity(0.09), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(action.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text("Más adelante")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(AppTheme.orange.opacity(0.09), in: Capsule())
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .frame(minHeight: 48)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.title)
        .accessibilityValue("No disponible todavía")
        .accessibilityHint("Abre información sobre una función futura")
        .accessibilityIdentifier("settings.action.\(action.rawValue)")
    }
}

struct SettingsToggleRow: View {
    let title: String
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
    let title: String
    let detail: String
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
    let onEdit: () -> Void

    var body: some View {
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
        .padding(22)
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
                weightUnit.formattedRange(profile.healthyWeightRangeKilograms)
            )
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
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
        .accessibilityHint("Abre una vista previa sin almacenamiento")
        .accessibilityIdentifier("settings.editProfile")
    }
}

struct SettingsDataSummaryGrid: View {
    let items: [DataCategorySummary]
    let compact: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        if compact && dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        return Array(
            repeating: GridItem(.flexible(), spacing: 10),
            count: compact ? 2 : 3
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items) { item in
                HStack(spacing: 11) {
                    Image(systemName: item.symbol)
                        .foregroundStyle(AppTheme.green)
                        .frame(width: 30, height: 30)
                        .background(AppTheme.greenSoft.opacity(0.8), in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            item.count.formatted(
                                .number.locale(SettingsFormatting.spanishLocale)
                            )
                        )
                            .font(.headline)
                            .monospacedDigit()
                        Text(item.title)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryInk)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(AppTheme.surfaceMuted.opacity(0.55), in: RoundedRectangle(cornerRadius: 13))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.title), \(item.count) registros de demostración")
            }
        }
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
