import SwiftUI

struct ObservationEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    var context: ObservationContext = .general
    var record: PetObservation?
    @State private var value = PetObservation()
    @State private var error: String?
    var body: some View {
        CareForm(title: "Observación", onSave: save) {
            Section {
                Picker("Dónde guardarla", selection: $value.context) {
                    ForEach(ObservationContext.allCases) { Text($0.title).tag($0) }
                }.disabled(record != nil)
                TextField("Título", text: $value.title)
                DatePicker("Fecha", selection: $value.date, in: ...Date.now, displayedComponents: .date)
                TextField("Qué quieres recordar", text: $value.body, axis: .vertical).lineLimit(4...10)
                if value.context == .general { Text("Se guardará con las observaciones de Salud.").foregroundStyle(AppTheme.secondaryInk).font(.caption) }
            }
            if let error { Text(error).foregroundStyle(.red) }
        }.onAppear { value = record ?? PetObservation(context: context) }
    }
    private func save() async -> Bool {
        guard !value.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { error = String(localized: "Escribe la observación."); return false }
        if value.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { value.title = String(localized: "Observación") }
        return await store.update {
            switch value.context {
            case .nutrition: $0.nutrition.observations.upsert(value)
            case .general, .health: $0.health.observations.upsert(value)
            case .training:
                $0.training.observations.upsert(BehaviorObservation(id: value.id, date: value.date, title: value.title.isEmpty ? String(localized: "Observación") : value.title, observation: value.body))
            }
        }
    }
}
