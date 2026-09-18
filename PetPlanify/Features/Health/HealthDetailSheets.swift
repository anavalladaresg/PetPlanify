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
        CareForm(title: record == nil ? "Registrar peso" : "Editar peso", onSave: save, symbol: "scalemass") {
            Section {
                DatePicker("Fecha", selection: $date, displayedComponents: .date)
                TextField("Peso (\(unit.symbol))", text: $weight)
                    .decimalEntry()
                    .accessibilityIdentifier("health.weightInput")
                TextField("Nota opcional", text: $note, axis: .vertical).lineLimit(3...6)
            }
            if let error { Section { Text(error).foregroundStyle(.red) } }
            if let record {
                Section {
                    HealthDeleteButton(title: "Eliminar peso") {
                        await store.softDeleteWeight(record.id)
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
        guard !AppInputValidation.isFutureDay(date) else { error = String(localized: "No se puede registrar un peso en una fecha futura."); return false }
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
    @State private var durationValue: String
    @State private var durationUnit: DurationUnit
    @State private var notes: String
    @State private var error: String?

    init(record: VaccinationRecord? = nil) {
        self.record = record
        _name = State(initialValue: record?.name ?? "")
        _date = State(initialValue: record?.dateAdministered ?? .now)
        let months = record?.protectionDurationMonths ?? record.flatMap { nextDurationMonths(from: $0.dateAdministered, to: $0.nextDueDate) }
        _durationValue = State(initialValue: months.map(String.init) ?? "")
        _durationUnit = State(initialValue: .months)
        _notes = State(initialValue: record?.notes ?? "")
    }

    var body: some View {
        CareForm(title: record == nil ? "Añadir vacuna" : "Editar vacuna", onSave: save, symbol: "syringe") {
            Section {
                TextField("Nombre de la vacuna", text: $name).accessibilityIdentifier("health.vaccineName")
                DatePicker("Administrada el", selection: $date, displayedComponents: .date)
            }
            Section {
                HStack {
                    TextField("Duración", text: $durationValue).decimalEntry()
                    Picker("Unidad", selection: $durationUnit) { ForEach(DurationUnit.allCases) { Text($0.title).tag($0) } }
                        .labelsHidden()
                }
            } footer: {
                Text("Indica cuánto tiempo protege para calcular la próxima vacuna automáticamente.")
            }
            Section { TextField("Notas opcionales", text: $notes, axis: .vertical).lineLimit(3...8) }
            if let error { Section { Text(error).foregroundStyle(.red) } }
            if let record {
                Section {
                    HealthDeleteButton(title: "Eliminar vacuna") {
                        await store.softDeleteVaccine(record.id)
                    }
                }
            }
        }
    }

    private func save() async -> Bool {
        guard !name.healthTrimmed.isEmpty else { error = String(localized: "Escribe el nombre de la vacuna."); return false }
        guard !AppInputValidation.isFutureDay(date) else { error = String(localized: "No se puede registrar una vacuna antes de administrarla. Elige hoy o una fecha anterior."); return false }
        var value = record ?? VaccinationRecord(name: name.healthTrimmed)
        value.name = name.healthTrimmed
        value.dateAdministered = date
        if let months = durationMonths {
            value.protectionDurationMonths = months
            value.nextDueDate = Calendar.current.date(byAdding: .month, value: months, to: date)
        } else if record == nil {
            value.protectionDurationMonths = nil
            value.nextDueDate = nil
        }
        value.notes = notes.healthOptional
        let success = await store.update { $0.health.vaccines.upsert(value) }
        if !success { error = String(localized: "No se pudo guardar la vacuna. Vuelve a intentarlo.") }
        else {
            await exportCareToAppleCalendarIfNeeded(
                store.snapshot.preferences.appleCalendarLinked,
                petName: store.snapshot.pet.name,
                title: "Vacuna de \(value.name)",
                date: value.nextDueDate ?? value.dateAdministered,
                notes: value.notes,
                alertAdvance: store.snapshot.preferences.appleCalendarAlertAdvance,
                store: store
            )
        }
        return success
    }

    private var durationMonths: Int? {
        guard let value = Int(durationValue), value > 0 else { return nil }
        return value * durationUnit.multiplier
    }
}

struct DewormingEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    let record: DewormingRecord?
    @State private var kind: DewormingKind
    @State private var category: DewormingCategory?
    @State private var product: String
    @State private var date: Date
    @State private var durationMonths: Int?
    @State private var notes: String
    @State private var error: String?

    init(record: DewormingRecord? = nil, kind: DewormingKind = .internalDeworming) {
        self.record = record
        _kind = State(initialValue: record?.kind ?? kind)
        _category = State(initialValue: record?.category)
        _product = State(initialValue: record?.productName ?? "")
        _date = State(initialValue: record?.applicationDate ?? .now)
        _durationMonths = State(initialValue: record?.protectionDurationMonths ?? record.flatMap { nextDurationMonths(from: $0.applicationDate, to: $0.nextDueDate) })
        _notes = State(initialValue: record?.notes ?? "")
    }

    var body: some View {
        CareForm(title: record == nil ? "Añadir desparasitación" : "Editar desparasitación", onSave: save, symbol: "pills") {
            Section {
                Picker("Tipo", selection: $kind) {
                    ForEach(DewormingKind.allCases) { Text($0.shortTitle).tag($0) }
                }
                Picker("Categoría", selection: $category) {
                    Text("Sin indicar").tag(nil as DewormingCategory?)
                    ForEach(DewormingCategory.allCases) { Text($0.title).tag(Optional($0)) }
                }
                TextField("Producto opcional", text: $product)
                DatePicker("Última aplicación", selection: $date, displayedComponents: .date)
            }
            Section {
                Picker("Duración", selection: $durationMonths) {
                    Text("Sin indicar").tag(nil as Int?)
                    Text("3 meses").tag(Optional(3))
                    Text("6 meses").tag(Optional(6))
                    Text("8 meses").tag(Optional(8))
                }
            } header: { Text("Duración de la protección") } footer: { Text("La próxima aplicación se calculará automáticamente.") }
            Section { TextField("Notas opcionales", text: $notes, axis: .vertical).lineLimit(3...8) }
            if let error { Section { Text(error).foregroundStyle(.red) } }
            if let record {
                Section {
                    HealthDeleteButton(title: "Eliminar desparasitación") {
                        await store.softDeleteDeworming(record.id)
                    }
                }
            }
        }
    }

    private func save() async -> Bool {
        guard category != nil || !product.healthTrimmed.isEmpty else {
            error = String(localized: "Indica la categoría o el producto de la desparasitación.")
            return false
        }
        guard !AppInputValidation.isFutureDay(date) else { error = String(localized: "No se puede registrar una desparasitación antes de aplicarla. Elige hoy o una fecha anterior."); return false }
        var value = record ?? DewormingRecord(kind: kind)
        value.kind = kind
        value.category = category
        value.productName = product.healthOptional
        value.applicationDate = date
        value.protectionDurationMonths = durationMonths
        value.nextDueDate = durationMonths.flatMap { Calendar.current.date(byAdding: .month, value: $0, to: date) }
        value.notes = notes.healthOptional
        let success = await store.update { $0.health.dewormings.upsert(value) }
        if !success { error = String(localized: "No se pudo guardar la desparasitación. Vuelve a intentarlo.") }
        else {
            await exportCareToAppleCalendarIfNeeded(
                store.snapshot.preferences.appleCalendarLinked,
                petName: store.snapshot.pet.name,
                title: value.kind.title,
                date: value.nextDueDate ?? value.applicationDate,
                notes: [value.category?.title, value.productName, value.notes].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n"),
                alertAdvance: store.snapshot.preferences.appleCalendarAlertAdvance,
                store: store
            )
        }
        return success
    }
}

enum DurationUnit: String, CaseIterable, Identifiable {
    case months, years
    var id: Self { self }
    var multiplier: Int { self == .months ? 1 : 12 }
    var title: String { self == .months ? String(localized: "Meses") : String(localized: "Años") }
}

private func nextDurationMonths(from start: Date, to end: Date?) -> Int? {
    guard let end else { return nil }
    return max(1, Calendar.current.dateComponents([.month], from: start, to: end).month ?? 0)
}
