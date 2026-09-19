import SwiftUI

struct TrashView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var permanentlyDeleting: DeletedCareRecord?

    var body: some View {
        NavigationStack {
            Group {
                if store.deletedRecordsForActivePet.isEmpty {
                    ContentUnavailableView(
                        "La papelera está vacía",
                        systemImage: "trash",
                        description: Text("Los registros que elimines podrán restaurarse desde aquí.")
                    )
                } else {
                    CarePage {
                        Text("Los registros se conservan en este dispositivo hasta que decidas eliminarlos definitivamente.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(store.deletedRecordsForActivePet) { item in
                            HStack(alignment: .center, spacing: AppTheme.Space.md) {
                                CareSymbol(systemName: item.kind.symbol, accent: AppTheme.green, size: 38)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(AppTheme.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text("\(item.kind.title) · eliminado el \(AppFormat.date(item.deletedAt))")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryInk)
                                }
                                Spacer(minLength: AppTheme.Space.sm)
                                Button("Restaurar") { Task { _ = await store.restoreDeletedRecord(item.id) } }
                                    .buttonStyle(.borderedProminent)
                                    .tint(AppTheme.green)
                                Menu {
                                    Button("Eliminar definitivamente", systemImage: "trash", role: .destructive) {
                                        permanentlyDeleting = item
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .frame(minWidth: 44, minHeight: 44)
                                }
                                .accessibilityLabel("Más acciones para \(item.title)")
                            }
                            .padding(AppTheme.Space.lg)
                            .appSurface(cornerRadius: AppTheme.compactRadius)
                            .accessibilityElement(children: .contain)
                        }
                    }
                }
            }
            .navigationTitle("Papelera")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
            }
        }
        .careSheet()
        .alert(
            "¿Eliminar definitivamente?",
            isPresented: Binding(get: { permanentlyDeleting != nil }, set: { if !$0 { permanentlyDeleting = nil } }),
        ) {
            Button("Eliminar definitivamente", role: .destructive) {
                guard let item = permanentlyDeleting else { return }
                Task {
                    _ = await store.permanentlyDeleteRecord(item.id)
                    permanentlyDeleting = nil
                }
            }
            Button("Cancelar", role: .cancel) { permanentlyDeleting = nil }
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
        .accessibilityIdentifier("settings.trash")
    }
}
