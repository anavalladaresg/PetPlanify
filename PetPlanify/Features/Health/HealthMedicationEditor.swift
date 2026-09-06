import SwiftUI

struct MedicationEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let record: MedicationRecord?
    @State private var name: String
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var notes: String
    @State private var visitID: UUID?
    @State private var error: String?
    @State private var confirmsFinish = false

    init(record: MedicationRecord? = nil) {
        self.record = record
        _name = State(initialValue: record?.name ?? "")
        _startDate = State(initialValue: record?.startDate ?? .now)
        _hasEndDate = State(initialValue: record?.endDate != nil)
        _endDate = State(initialValue: record?.endDate ?? .now)
        _notes = State(initialValue: record?.notes ?? "")
        _visitID = State(initialValue: record?.relatedVisitID)
    }

    var body: some View {
        CareForm(title: record == nil ? "Añadir medicación" : "Editar medicación", onSave: save) {
            Section {
                TextField("Nombre", text: $name).accessibilityIdentifier("health.medicationName")
                DatePicker("Inicio", selection: $startDate, displayedComponents: .date)
                HealthOptionalDate(title: "Fecha de finalización", isEnabled: $hasEndDate, date: $endDate, minimum: startDate)
            }
            Section {
                TextField("Indicaciones y notas", text: $notes, axis: .vertical).lineLimit(3...8)
                Picker("Visita relacionada", selection: $visitID) {
                    Text("Sin vincular").tag(nil as UUID?)
                    ForEach(store.snapshot.health.visits.sorted { $0.date > $1.date }) { visit in
                        Text("\(visit.reason) · \(AppFormat.date(visit.date))").tag(Optional(visit.id))
                    }
                }
            } footer: { Text("Registra únicamente las indicaciones recibidas de tu profesional veterinario.") }
            if let error { Section { Text(error).foregroundStyle(.red) } }
            if let record {
                Section {
                    if record.isActive() {
                        Button("Finalizar medicación") { confirmsFinish = true }
                    }
                    HealthDeleteButton(title: "Eliminar medicación") {
                        await store.update { $0.health.medications.removeAll { $0.id == record.id } }
                    }
                }
            }
        }
        .confirmationDialog("¿Finalizar esta medicación?", isPresented: $confirmsFinish, titleVisibility: .visible) {
            Button("Finalizar hoy") {
                Task {
                    guard var value = record else { return }
                    value.endDate = .now
                    if await store.update({ $0.health.medications.upsert(value) }) { dismiss() }
                    else { error = String(localized: "No se pudo finalizar la medicación. Vuelve a intentarlo.") }
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("El registro se conservará en el historial.")
        }
    }

    private func save() async -> Bool {
        guard !name.healthTrimmed.isEmpty else { error = String(localized: "Escribe el nombre del medicamento."); return false }
        guard !hasEndDate || endDate >= startDate else { error = String(localized: "La fecha final debe ser posterior al inicio."); return false }
        var value = record ?? MedicationRecord(name: name.healthTrimmed)
        value.name = name.healthTrimmed
        value.startDate = startDate
        value.endDate = hasEndDate ? endDate : nil
        value.notes = notes.healthTrimmed
        value.relatedVisitID = visitID
        let success = await store.update { $0.health.medications.upsert(value) }
        if !success { error = String(localized: "No se pudo guardar la medicación. Vuelve a intentarlo.") }
        return success
    }
}
