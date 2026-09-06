import SwiftUI
import QuickLook
import UniformTypeIdentifiers

struct HealthDocumentsView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.snapshot.health.documents.sorted { $0.createdAt > $1.createdAt }) { document in
                    HealthDocumentRow(document: document, showsVisit: true)
                }
            }
            .overlay {
                if store.snapshot.health.documents.isEmpty {
                    ContentUnavailableView("No hay documentos", systemImage: "doc", description: Text("Puedes adjuntarlos desde los detalles de una visita veterinaria."))
                }
            }
            .scrollContentBackground(.hidden)
            .appCanvas()
            .navigationTitle("Documentos")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } } }
        }
        #if os(macOS)
        .frame(minWidth: 420, idealWidth: 620, minHeight: 420, idealHeight: 600)
        #endif
    }
}

struct HealthDocumentRow: View {
    @Environment(PetPlanifyStore.self) private var store
    let document: DocumentAttachment
    var showsVisit = false
    @State private var previewURL: URL?
    @State private var renaming = false
    @State private var linking = false
    @State private var confirmsDelete = false
    @State private var confirmsUnlink = false
    @State private var error: String?
    @State private var busy = false

    private var visit: VeterinaryVisit? { store.snapshot.health.visits.first { $0.id == document.linkedVisitID } }
    private var typeLabel: String {
        if UTType(document.type)?.conforms(to: .pdf) == true { return String(localized: "PDF") }
        return String(localized: "Imagen")
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                if let url = store.documentURL(for: document) { previewURL = url }
                else { error = String(localized: "El documento no está disponible en este dispositivo.") }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "doc").foregroundStyle(AppTheme.green).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(document.displayName).foregroundStyle(AppTheme.ink).multilineTextAlignment(.leading)
                        Text("\(typeLabel) · \(AppFormat.date(document.createdAt))").font(.caption).foregroundStyle(AppTheme.secondaryInk)
                        if showsVisit {
                            Text(visit?.reason ?? String(localized: "Sin visita vinculada")).font(.caption).foregroundStyle(AppTheme.secondaryInk)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Abre una vista previa del documento")
            Menu {
                Button("Cambiar nombre", systemImage: "pencil") { renaming = true }
                Button("Vincular a una visita", systemImage: "link") { linking = true }
                if document.linkedVisitID != nil {
                    Button("Quitar de esta visita", systemImage: "link.badge.plus") { confirmsUnlink = true }
                }
                Button("Eliminar documento", systemImage: "trash", role: .destructive) { confirmsDelete = true }
            } label: {
                Image(systemName: "ellipsis.circle").frame(minWidth: 44, minHeight: 44)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .accessibilityLabel("Opciones de \(document.displayName)")
        }
        .disabled(busy)
        .quickLookPreview($previewURL)
        .sheet(isPresented: $renaming) { DocumentMetadataEditor(document: document) }
        .sheet(isPresented: $linking) { DocumentMetadataEditor(document: document, editsVisit: true) }
        .confirmationDialog("¿Eliminar este documento?", isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("Eliminar documento", role: .destructive) {
                busy = true
                Task {
                    if !(await store.deleteDocument(document.id)) { error = String(localized: "No se pudo eliminar el documento.") }
                    busy = false
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: { Text("Se eliminará de PetPlanify y de la visita vinculada.") }
        .confirmationDialog("¿Quitar el documento de esta visita?", isPresented: $confirmsUnlink, titleVisibility: .visible) {
            Button("Quitar de la visita") {
                busy = true
                Task {
                    let success = await store.update { snapshot in
                        if let index = snapshot.health.documents.firstIndex(where: { $0.id == document.id }) {
                            snapshot.health.documents[index].linkedVisitID = nil
                        }
                        for index in snapshot.health.visits.indices { snapshot.health.visits[index].documentIDs.removeAll { $0 == document.id } }
                    }
                    if !success { error = String(localized: "No se pudo quitar el documento de la visita.") }
                    busy = false
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: { Text("El archivo seguirá disponible en la lista Documentos de Salud.") }
        .alert("No se pudo completar la operación", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Aceptar", role: .cancel) { error = nil }
        } message: { Text(error ?? "") }
    }
}

private struct DocumentMetadataEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    let document: DocumentAttachment
    let editsVisit: Bool
    @State private var name: String
    @State private var visitID: UUID?
    @State private var error: String?

    init(document: DocumentAttachment, editsVisit: Bool = false) {
        self.document = document
        self.editsVisit = editsVisit
        _name = State(initialValue: document.displayName)
        _visitID = State(initialValue: document.linkedVisitID)
    }

    var body: some View {
        CareForm(title: editsVisit ? "Vincular documento" : "Cambiar nombre", onSave: save) {
            Section {
                if editsVisit {
                    Picker("Visita", selection: $visitID) {
                        Text("Sin vincular").tag(nil as UUID?)
                        ForEach(store.snapshot.health.visits.sorted { $0.date > $1.date }) { visit in
                            Text("\(visit.reason) · \(AppFormat.date(visit.date))").tag(Optional(visit.id))
                        }
                    }
                } else {
                    TextField("Nombre del documento", text: $name)
                }
            }
            if let error { Section { Text(error).foregroundStyle(.red) } }
        }
    }

    private func save() async -> Bool {
        guard !name.healthTrimmed.isEmpty else { error = String(localized: "Escribe un nombre para el documento."); return false }
        let success = await store.update { snapshot in
            guard let index = snapshot.health.documents.firstIndex(where: { $0.id == document.id }) else { return }
            if editsVisit {
                snapshot.health.documents[index].linkedVisitID = visitID
                for index in snapshot.health.visits.indices {
                    snapshot.health.visits[index].documentIDs.removeAll { $0 == document.id }
                    if snapshot.health.visits[index].id == visitID { snapshot.health.visits[index].documentIDs.append(document.id) }
                }
            } else { snapshot.health.documents[index].displayName = name.healthTrimmed }
        }
        if !success { error = String(localized: "No se pudieron guardar los cambios. Vuelve a intentarlo.") }
        return success
    }
}
