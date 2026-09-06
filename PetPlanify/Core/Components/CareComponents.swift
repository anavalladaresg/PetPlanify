import SwiftUI

struct CarePage<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) { content }
                .frame(maxWidth: 860, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
        }
        .appCanvas()
    }
}

struct CareSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title3.weight(.semibold)).fontDesign(.serif)
            VStack(alignment: .leading, spacing: 14) { content }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .appSurface()
    }
}

struct EmptyCareState: View {
    let title: LocalizedStringKey
    var symbol: String = "leaf"
    var message: LocalizedStringKey = ""
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(AppTheme.green).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                if message != "" { Text(message).font(.subheadline).foregroundStyle(AppTheme.secondaryInk) }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CareForm<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    let title: LocalizedStringKey
    let onSave: () async -> Bool
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
                        Button("Guardar") {
                            saving = true
                            Task {
                                saveFailed = false
                                if await onSave() { dismiss() } else { saveFailed = true }
                                saving = false
                            }
                        }.disabled(saving).accessibilityIdentifier("form.save")
                    }
                }
                .interactiveDismissDisabled(saving)
        }
        #if os(macOS)
        .frame(minWidth: 420, idealWidth: 520, minHeight: 480, idealHeight: 650)
        #endif
    }
}

extension View {
    func decimalEntry() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}
