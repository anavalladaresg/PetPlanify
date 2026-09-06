import SwiftUI

struct WeightEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    let record: WeightRecord?
    @State private var date: Date
    @State private var weight = ""
    @State private var note: String
    @State private var error: String?
    @State private var loaded = false
    @State private var unit: WeightUnit = .kilograms

    init(record: WeightRecord? = nil) {
        self.record = record
        _date = State(initialValue: record?.date ?? .now)
        _note = State(initialValue: record?.note ?? "")
    }

    var body: some View {
        CareForm(title: record == nil ? "Registrar peso" : "Editar peso", onSave: save) {
            Section {
                DatePicker("Fecha", selection: $date, in: ...Date.now, displayedComponents: .date)
                TextField("Peso (\(unit.symbol))", text: $weight)
                    .decimalEntry()
                    .accessibilityIdentifier("health.weightInput")
                TextField("Nota opcional", text: $note, axis: .vertical).lineLimit(3...6)
            }
            if let error { Section { Text(error).foregroundStyle(.red) } }
            if let record {
                Section {
                    HealthDeleteButton(title: "Eliminar peso") {
                        await store.update {
                            $0.health.weights.removeAll { $0.id == record.id }
                            $0.pet.currentWeight = $0.health.weights.max { $0.date < $1.date }?.weight
                            $0.pet.updatedAt = .now
                        }
                    }
                }
            }
        }
        .onAppear {
            guard !loaded else { return }
            unit = store.snapshot.preferences.weightUnit
            if let record { weight = AppFormat.number(unit.fromKilograms(record.weight)) }
            loaded = true
        }
    }

    private func save() async -> Bool {
        guard let entered = AppFormat.parseNumber(weight), AppFormat.validWeight(unit.kilograms(from: entered)) else {
            error = String(localized: "Introduce un peso válido y positivo en \(unit.symbol).")
            return false
        }
        guard date <= .now else { error = String(localized: "La fecha de un peso registrado no puede ser futura."); return false }
        let value = WeightRecord(id: record?.id ?? UUID(), date: date, weight: unit.kilograms(from: entered), note: note.healthOptional)
        let success = await store.update {
            $0.health.weights.upsert(value)
            $0.pet.currentWeight = $0.health.weights.max { $0.date < $1.date }?.weight
            $0.pet.updatedAt = .now
        }
        if !success { error = String(localized: "No se pudo guardar el peso. Vuelve a intentarlo.") }
        return success
    }
}

struct VaccinationEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    let record: VaccinationRecord?
    @State private var name: String
    @State private var date: Date
    @State private var hasNextDate: Bool
    @State private var nextDate: Date
    @State private var clinic: String
    @State private var notes: String
    @State private var error: String?

    init(record: VaccinationRecord? = nil) {
        self.record = record
        _name = State(initialValue: record?.name ?? "")
        _date = State(initialValue: record?.dateAdministered ?? .now)
        _hasNextDate = State(initialValue: record?.nextDueDate != nil)
        _nextDate = State(initialValue: record?.nextDueDate ?? .now)
        _clinic = State(initialValue: record?.clinic ?? "")
        _notes = State(initialValue: record?.notes ?? "")
    }

    var body: some View {
        CareForm(title: record == nil ? "Añadir vacuna" : "Editar vacuna", onSave: save) {
            Section {
                TextField("Nombre de la vacuna", text: $name).accessibilityIdentifier("health.vaccineName")
                DatePicker("Administrada el", selection: $date, in: ...Date.now, displayedComponents: .date)
                TextField("Clínica opcional", text: $clinic)
            }
            Section {
                HealthOptionalDate(title: "Próxima dosis", isEnabled: $hasNextDate, date: $nextDate, minimum: date)
            } footer: {
                Text("Introduce la próxima fecha indicada por tu profesional veterinario.")
            }
            Section { TextField("Notas opcionales", text: $notes, axis: .vertical).lineLimit(3...8) }
            if let error { Section { Text(error).foregroundStyle(.red) } }
            if let record {
                Section {
                    HealthDeleteButton(title: "Eliminar vacuna") {
                        await store.update { $0.health.vaccines.removeAll { $0.id == record.id } }
                    }
                }
            }
        }
    }

    private func save() async -> Bool {
        guard !name.healthTrimmed.isEmpty else { error = String(localized: "Escribe el nombre de la vacuna."); return false }
        guard !hasNextDate || nextDate >= date else { error = String(localized: "La próxima dosis debe ser posterior a la administración."); return false }
        var value = record ?? VaccinationRecord(name: name.healthTrimmed)
        value.name = name.healthTrimmed
        value.dateAdministered = date
        value.nextDueDate = hasNextDate ? nextDate : nil
        value.clinic = clinic.healthOptional
        value.notes = notes.healthOptional
        let success = await store.update { $0.health.vaccines.upsert(value) }
        if !success { error = String(localized: "No se pudo guardar la vacuna. Vuelve a intentarlo.") }
        return success
    }
}

struct DewormingEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    let record: DewormingRecord?
    @State private var kind: DewormingKind
    @State private var product: String
    @State private var date: Date
    @State private var hasNextDate: Bool
    @State private var nextDate: Date
    @State private var notes: String
    @State private var error: String?

    init(record: DewormingRecord? = nil, kind: DewormingKind = .internalDeworming) {
        self.record = record
        _kind = State(initialValue: record?.kind ?? kind)
        _product = State(initialValue: record?.productName ?? "")
        _date = State(initialValue: record?.applicationDate ?? .now)
        _hasNextDate = State(initialValue: record?.nextDueDate != nil)
        _nextDate = State(initialValue: record?.nextDueDate ?? .now)
        _notes = State(initialValue: record?.notes ?? "")
    }

    var body: some View {
        CareForm(title: record == nil ? "Añadir desparasitación" : "Editar desparasitación", onSave: save) {
            Section {
                Picker("Tipo", selection: $kind) {
                    ForEach(DewormingKind.allCases) { Text($0.shortTitle).tag($0) }
                }
                TextField("Producto opcional", text: $product)
                DatePicker("Última aplicación", selection: $date, in: ...Date.now, displayedComponents: .date)
            }
            Section {
                HealthOptionalDate(title: "Próxima aplicación", isEnabled: $hasNextDate, date: $nextDate, minimum: date)
            } footer: { Text("Indica la fecha acordada con tu profesional veterinario.") }
            Section { TextField("Notas opcionales", text: $notes, axis: .vertical).lineLimit(3...8) }
            if let error { Section { Text(error).foregroundStyle(.red) } }
            if let record {
                Section {
                    HealthDeleteButton(title: "Eliminar desparasitación") {
                        await store.update { $0.health.dewormings.removeAll { $0.id == record.id } }
                    }
                }
            }
        }
    }

    private func save() async -> Bool {
        guard !hasNextDate || nextDate >= date else { error = String(localized: "La próxima aplicación debe ser posterior a la última."); return false }
        var value = record ?? DewormingRecord(kind: kind)
        value.kind = kind
        value.productName = product.healthOptional
        value.applicationDate = date
        value.nextDueDate = hasNextDate ? nextDate : nil
        value.notes = notes.healthOptional
        let success = await store.update { $0.health.dewormings.upsert(value) }
        if !success { error = String(localized: "No se pudo guardar la desparasitación. Vuelve a intentarlo.") }
        return success
    }
}
