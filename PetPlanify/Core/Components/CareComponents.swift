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
                    .shadow(color: AppTheme.highlight.opacity(0.82), radius: 8, x: -4, y: -4)
                    .shadow(color: AppTheme.shadow.opacity(style == .highlighted ? 0.30 : 0.22), radius: 9, x: 4, y: 5)
            }
        }
        .overlay {
            if style != .plain {
                RoundedRectangle(cornerRadius: style == .compact ? AppTheme.compactRadius : AppTheme.cornerRadius)
                    .stroke(style == .highlighted ? AppTheme.orange.opacity(0.25) : AppTheme.border.opacity(0.35), lineWidth: 0.65)
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
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: size * 0.32))
            .overlay(RoundedRectangle(cornerRadius: size * 0.32).fill(accent.opacity(0.10)))
            .shadow(color: AppTheme.highlight.opacity(0.78), radius: 4, x: -2, y: -2)
            .shadow(color: AppTheme.shadow.opacity(0.18), radius: 4, x: 2, y: 2)
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
    var saveTitle: LocalizedStringKey = "Guardar"
    var saveDisabled = false
    var error: Binding<String?> = .constant(nil)
    var symbol: String = "square.and.pencil"
    @ViewBuilder var content: Content
    @State private var saving = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: AppTheme.Space.sm) {
                        Image(systemName: symbol)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(AppTheme.green)
                            .frame(width: 64, height: 64)
                            .background(AppTheme.greenSoft.opacity(0.72), in: Circle())
                        Text(title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.ink)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                content
            }.disabled(saving)
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .appCanvas()
                .navigationTitle("")
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
                            Button(saveTitle) {
                                saving = true
                                Task {
                                    if await onSave() { dismiss() }
                                    saving = false
                                }
                            }.disabled(saveDisabled).accessibilityIdentifier("form.save")
                        }
                    }
                }
                .interactiveDismissDisabled(saving)
        }
        .overlay {
            if let message = error.wrappedValue, !message.isEmpty {
                ZStack {
                    Color.black.opacity(0.16)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { error.wrappedValue = nil }
                        .accessibilityLabel("Cerrar mensaje de error")

                    ZStack(alignment: .topTrailing) {
                        VStack(alignment: .center, spacing: AppTheme.Space.md) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 38, weight: .medium))
                                .foregroundStyle(AppTheme.orange)
                                .accessibilityHidden(true)
                            Text(message)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                        }

                        Button("Cerrar", systemImage: "xmark") {
                            error.wrappedValue = nil
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .frame(width: 44, height: 44)
                        .accessibilityLabel("Cerrar mensaje de error")
                    }
                    .padding(AppTheme.Space.lg)
                    .frame(maxWidth: 360)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous).stroke(AppTheme.orange.opacity(0.28), lineWidth: 1))
                    .shadow(color: AppTheme.shadow.opacity(0.28), radius: 22, y: 10)
                    .accessibilityElement(children: .contain)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
                .animation(.easeOut(duration: 0.2), value: message)
            }
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
