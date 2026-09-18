import SwiftUI

struct AccentIcon: View {
    let systemName: String
    var accent: Color = AppTheme.green
    var size: CGFloat = 38

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(accent)
            .frame(width: size, height: size)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: size * 0.30, style: .continuous))
            .shadow(color: AppTheme.highlight.opacity(0.72), radius: 4, x: -2, y: -2)
            .shadow(color: AppTheme.shadow.opacity(0.18), radius: 4, x: 2, y: 2)
            .accessibilityHidden(true)
    }
}

struct StatusBadge: View {
    let title: String
    var symbol: String = "checkmark.circle.fill"
    var tint: Color = AppTheme.green

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, AppTheme.Space.sm)
            .padding(.vertical, AppTheme.Space.xs)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

struct SectionCard<Content: View>: View {
    let title: LocalizedStringKey
    var symbol: String
    var accent: Color = AppTheme.green
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            HStack(spacing: AppTheme.Space.md) {
                AccentIcon(systemName: symbol, accent: accent, size: 34)
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
            }
            content
        }
        .padding(AppTheme.Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(elevated: false)
    }
}

struct SettingRow<Content: View>: View {
    let title: LocalizedStringKey
    var detail: LocalizedStringKey? = nil
    var symbol: String? = nil
    var accent: Color = AppTheme.green
    @ViewBuilder var trailing: Content

    var body: some View {
        HStack(spacing: AppTheme.Space.md) {
            if let symbol { AccentIcon(systemName: symbol, accent: accent, size: 30) }
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(title).font(.body.weight(.medium)).foregroundStyle(AppTheme.ink)
                if let detail { Text(detail).font(.caption).foregroundStyle(AppTheme.secondaryInk) }
            }
            Spacer(minLength: AppTheme.Space.md)
            trailing
        }
        .frame(minHeight: 44)
    }
}

struct NavigationSettingRow: View {
    let title: LocalizedStringKey
    var detail: LocalizedStringKey? = nil
    var symbol: String
    var accent: Color = AppTheme.green
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingRow(title: title, detail: detail, symbol: symbol, accent: accent) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.secondaryInk)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct PetProfileCard: View {
    let name: String
    let subtitle: String
    var photoURL: URL? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Space.lg) {
                ZStack {
                    Circle().fill(AppTheme.greenSoft)
                    PetAvatarView(size: 66, photoURL: photoURL)
                }
                .frame(width: 76, height: 76)
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text(name.isEmpty ? "Sin nombre" : name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.secondaryInk)
            }
            .padding(AppTheme.Space.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .appSurface(elevated: true)
    }
}

struct PetProfileHeroCard: View {
    let name: String
    let subtitle: String
    var photoURL: URL? = nil
    let editAction: () -> Void
    let manageAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            HStack(alignment: .top) {
                Text("MI MASCOTA")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.green)
                Spacer()
                Button("Editar", systemImage: "pencil", action: editAction)
                    .font(.subheadline.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .buttonStyle(.borderless)
                    .foregroundStyle(AppTheme.green)
            }
            HStack(spacing: AppTheme.Space.xl) {
                ZStack {
                    Circle().fill(AppTheme.greenSoft)
                    Circle().stroke(AppTheme.highlight.opacity(0.65), lineWidth: 4)
                    PetAvatarView(size: 92, photoURL: photoURL)
                }
                .frame(width: 92, height: 92)
                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    Text(name.isEmpty ? "Sin nombre" : name)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer(minLength: 0)
            }
            Button("Gestionar mascotas y familia", systemImage: "person.2.fill", action: manageAction)
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.borderless)
                .foregroundStyle(AppTheme.green)
        }
        .padding(AppTheme.Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous)
                .fill(LinearGradient(colors: [AppTheme.greenSoft, AppTheme.lavenderSoft.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay(RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous).stroke(AppTheme.highlight.opacity(0.55), lineWidth: 1))
        .shadow(color: AppTheme.highlight.opacity(0.62), radius: 12, x: -6, y: -6)
        .shadow(color: AppTheme.shadow.opacity(0.30), radius: 16, x: 7, y: 8)
    }
}

struct FeatureSettingCard<Content: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let symbol: String
    let accent: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            AccentIcon(systemName: symbol, accent: accent, size: 48)
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(title).font(.title3.weight(.bold)).foregroundStyle(AppTheme.ink)
                Text(message).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
            }
            content
        }
        .padding(AppTheme.Space.xl)
        .frame(maxWidth: .infinity, minHeight: 178, alignment: .topLeading)
        .background(accent.opacity(0.15), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous).stroke(accent.opacity(0.22), lineWidth: 0.8))
        .shadow(color: AppTheme.highlight.opacity(0.56), radius: 9, x: -5, y: -5)
        .shadow(color: AppTheme.shadow.opacity(0.24), radius: 11, x: 5, y: 6)
    }
}

struct EmptyStateCard: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var symbol: String = "sparkles"
    var accent: Color = AppTheme.green

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Space.md) {
            AccentIcon(systemName: symbol, accent: accent, size: 42)
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(AppTheme.ink)
                Text(message).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Space.lg)
        .appSurface(cornerRadius: AppTheme.compactRadius)
    }
}

struct DestructiveActionCard<Content: View>: View {
    let title: LocalizedStringKey
    var message: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            HStack(spacing: AppTheme.Space.md) {
                AccentIcon(systemName: "exclamationmark.triangle", accent: AppTheme.orange, size: 34)
                Text(title).font(.headline.weight(.semibold)).foregroundStyle(AppTheme.ink)
            }
            Text(message).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
            content
        }
        .padding(AppTheme.Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.orangeSoft, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous).stroke(AppTheme.orange.opacity(0.24), lineWidth: 0.8))
        .shadow(color: AppTheme.highlight.opacity(0.55), radius: 8, x: -4, y: -4)
        .shadow(color: AppTheme.shadow.opacity(0.20), radius: 8, x: 4, y: 5)
    }
}

struct PrimaryActionButton: View {
    let title: LocalizedStringKey
    var symbol: String = "arrow.right"
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.green)
        .disabled(isDisabled)
    }
}

struct SecondaryActionButton: View {
    let title: LocalizedStringKey
    var symbol: String = "arrow.right"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .frame(minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(AppTheme.green)
    }
}

struct InlineValidationMessage: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.orange)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
    }
}

struct FormSectionCard<Content: View>: View {
    let title: LocalizedStringKey
    var symbol: String = "square.stack.3d.up"
    var accent: Color = AppTheme.green
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            HStack(spacing: AppTheme.Space.sm) {
                CareSymbol(systemName: symbol, accent: accent, size: 30)
                Text(title).font(.headline.weight(.semibold)).foregroundStyle(AppTheme.ink)
            }
            content
        }
        .padding(AppTheme.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceElevated, in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous).stroke(AppTheme.border.opacity(0.45), lineWidth: 0.7))
    }
}

struct TimelineRow<Content: View>: View {
    let isLast: Bool
    var accent: Color = AppTheme.green
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Space.md) {
            VStack(spacing: 0) {
                Circle().fill(accent).frame(width: 9, height: 9).padding(.top, 6)
                if !isLast { Rectangle().fill(accent.opacity(0.35)).frame(width: 1).frame(maxHeight: .infinity) }
            }
            content.frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct ActionCard<Content: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let symbol: String
    var accent: Color = AppTheme.orange
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            CareSymbol(systemName: symbol, accent: accent, size: 42)
            Text(title).font(.title3.weight(.bold)).foregroundStyle(AppTheme.ink)
            Text(message).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
            content
        }
        .padding(AppTheme.Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.15), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous).stroke(accent.opacity(0.28), lineWidth: 0.8))
    }
}

struct StatusCard<Content: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    var accent: Color = AppTheme.green
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            HStack(spacing: AppTheme.Space.sm) {
                CareSymbol(systemName: symbol, accent: accent, size: 34)
                Text(title).font(.headline.weight(.semibold)).foregroundStyle(AppTheme.ink)
            }
            content
        }
        .padding(AppTheme.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.scoreSurface, in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous).stroke(accent.opacity(0.24), lineWidth: 0.8))
    }
}

struct QuickActionButton: View {
    let title: LocalizedStringKey
    let subtitle: String
    let symbol: String
    var accent: Color = AppTheme.green
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                Image(systemName: symbol)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(accent)
                    .frame(width: 38, height: 38)
                    .background(accent.opacity(0.16), in: Circle())
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.ink)
                Text(subtitle).font(.caption.weight(.medium)).foregroundStyle(AppTheme.secondaryInk).lineLimit(1)
            }
            .padding(AppTheme.Space.md)
            .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
            .background(AppTheme.quickSurface.opacity(isHovered ? 0.98 : 0.82), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous).stroke(accent.opacity(isHovered ? 0.48 : 0.26), lineWidth: 0.8))
            .scaleEffect(isHovered ? 1.01 : 1)
        }
        .buttonStyle(QuickActionPressStyle())
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
    }
}

struct QuickActionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.035 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct AppSheet<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cerrar") { dismiss() }
                    }
                }
        }
        .careSheet()
    }
}
