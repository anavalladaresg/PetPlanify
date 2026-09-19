import SwiftUI

struct ObservationEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    var context: ObservationContext = .general
    var record: PetObservation?
    @State private var value = PetObservation()
    @State private var error: String?
    @State private var loaded = false
    var body: some View {
        CareForm(title: "Observación", onSave: save, symbol: "text.bubble.fill") {
            Section {
                Picker("Dónde guardarla", selection: $value.context) {
                    ForEach(ObservationContext.allCases) { Text($0.title).tag($0) }
                }.disabled(record != nil)
                TextField("Título", text: $value.title)
                DatePicker("Fecha", selection: $value.date, displayedComponents: .date)
                TextField("Qué quieres recordar", text: $value.body, axis: .vertical).lineLimit(4...10)
                if value.context == .general { Text("Se guardará con las observaciones de Salud.").foregroundStyle(AppTheme.secondaryInk).font(.caption) }
            }
            if let error { Text(error).foregroundStyle(.red) }
            if let record {
                Section {
                    HealthDeleteButton(title: "Eliminar observación") {
                        if record.context == .training { await store.softDeleteTrainingObservation(record.id) }
                        else { await store.softDeleteObservation(record) }
                    }
                }
            }
        }.onAppear { guard !loaded else { return }; loaded = true; value = record ?? PetObservation(context: context) }
    }
    private func save() async -> Bool {
        guard !value.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { error = String(localized: "Escribe la observación."); return false }
        guard !AppInputValidation.isFutureDay(value.date) else { error = String(localized: "Una observación no puede tener una fecha futura."); return false }
        if value.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { value.title = String(localized: "Observación") }
        let saved = await store.update {
            switch value.context {
            case .nutrition: $0.nutrition.observations.upsert(value)
            case .general, .health: $0.health.observations.upsert(value)
            case .training:
                $0.training.observations.upsert(BehaviorObservation(id: value.id, date: value.date, title: value.title.isEmpty ? String(localized: "Observación") : value.title, observation: value.body))
            }
        }
        if !saved { error = store.message ?? String(localized: "No se ha podido guardar la observación.") }
        return saved
    }
}

struct ObservationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let record: PetObservation
    @State private var editing = false

    var body: some View {
        NavigationStack {
            CarePage {
                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    CareSymbol(systemName: "text.bubble.fill", accent: AppTheme.blue, size: 54)
                    Text(record.title).font(.title2.weight(.bold)).foregroundStyle(AppTheme.ink)
                    Text(AppFormat.date(record.date)).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Space.lg)
                .background(AppTheme.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                CareSection(title: "Observación", style: .compact) {
                    Text(record.body).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
                }
            }
            .navigationTitle("Detalle de observación")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("Editar") { editing = true } }
            }
        }
        .sheet(isPresented: $editing) { ObservationEditor(context: record.context, record: record) }
    }
}
