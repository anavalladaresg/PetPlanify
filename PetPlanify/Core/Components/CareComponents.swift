import SwiftUI

struct CarePage<Content: View>: View {
    @ViewBuilder var content: Content
    private var margin: CGFloat {
        #if os(macOS)
        AppTheme.Space.section
        #else
        AppTheme.Space.xl
        #endif
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Space.xxl) { content }
                .frame(maxWidth: 1040, alignment: .leading)
                .padding(.horizontal, margin)
                .padding(.top, AppTheme.Space.lg)
                .padding(.bottom, AppTheme.Space.xxl)
                .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .appCanvas()
    }
}

enum CareSectionStyle { case standard, compact, highlighted, plain }

struct CareSection<Content: View>: View {
    let title: LocalizedStringKey
    var style: CareSectionStyle = .standard
    var symbol: String? = nil
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            HStack(spacing: AppTheme.Space.sm) {
                if let symbol {
                    CareSymbol(systemName: symbol, accent: style == .highlighted ? AppTheme.orange : AppTheme.green, size: 30)
                }
                Text(title)
                    .font(.title3.weight(.medium)).fontDesign(.serif)
                    .foregroundStyle(AppTheme.ink)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(alignment: .leading, spacing: AppTheme.Space.md) { content }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(style == .plain ? 0 : style == .compact ? AppTheme.Space.lg : AppTheme.Space.xl)
        .background {
            if style != .plain {
                RoundedRectangle(cornerRadius: style == .compact ? AppTheme.compactRadius : AppTheme.cornerRadius)
                    .fill(style == .highlighted ? AppTheme.orangeSoft : AppTheme.surface)
                    .shadow(color: AppTheme.shadow.opacity(style == .highlighted ? 0.07 : 0.025), radius: style == .highlighted ? 12 : 4, y: style == .highlighted ? 4 : 1)
            }
        }
        .overlay {
            if style != .plain {
                RoundedRectangle(cornerRadius: style == .compact ? AppTheme.compactRadius : AppTheme.cornerRadius)
                    .stroke(style == .highlighted ? AppTheme.orange.opacity(0.15) : AppTheme.border.opacity(0.7), lineWidth: 0.75)
            }
        }
    }
}

struct CareSymbol: View {
    let systemName: String
    var accent: Color = AppTheme.green
    var size: CGFloat = 36
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.43, weight: .medium))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(accent)
            .frame(width: size, height: size)
            .background(accent.opacity(0.085), in: RoundedRectangle(cornerRadius: size * 0.32))
            .accessibilityHidden(true)
    }
}

struct EmptyCareState: View {
    let title: LocalizedStringKey
    var symbol: String = "leaf"
    var message: LocalizedStringKey = ""
    var illustration: PetCareIllustration.Kind? = nil
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Space.md) {
            if let illustration {
                PetCareIllustration(kind: illustration).frame(width: 96, height: 76)
            } else {
                CareSymbol(systemName: symbol, size: 40)
            }
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(title).font(.body.weight(.medium))
                if message != "" {
                    Text(message).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, AppTheme.Space.xs)
    }
}

struct CareForm<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    let title: LocalizedStringKey
    let onSave: () async -> Bool
    var saveDisabled = false
    @ViewBuilder var content: Content
    @State private var saving = false
    @State private var saveFailed = false
    var body: some View {
        NavigationStack {
            Form {
                content
                if saveFailed { Text("No se han podido guardar los cambios. Revisa los datos e inténtalo de nuevo.").foregroundStyle(.red) }
            }.disabled(saving)
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .appCanvas()
                .navigationTitle(title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { dismiss() }.disabled(saving)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if saving {
                            ProgressView().controlSize(.small).accessibilityLabel("Guardando…")
                        } else {
                            Button("Guardar") {
                                saving = true
                                Task {
                                    saveFailed = false
                                    if await onSave() { dismiss() } else { saveFailed = true }
                                    saving = false
                                }
                            }.disabled(saveDisabled).accessibilityIdentifier("form.save")
                        }
                    }
                }
                .interactiveDismissDisabled(saving)
        }
        .careSheet()
    }
}

extension View {
    func careSheet() -> some View {
        #if os(macOS)
        self.frame(minWidth: 480, idealWidth: 620, minHeight: 460, idealHeight: 650)
        #else
        self.presentationDetents([.large]).presentationDragIndicator(.visible)
        #endif
    }
    func decimalEntry() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}
