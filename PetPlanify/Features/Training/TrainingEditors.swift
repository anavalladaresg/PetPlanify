import SwiftUI

struct SelectedTrickEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    @State private var draft: SelectedTrick

    init(record: SelectedTrick) {
        _draft = State(initialValue: record)
    }

    var body: some View {
        CareForm(title: "Editar progreso", onSave: save) {
            Section("Aprendizaje") {
                Picker("Estado", selection: $draft.status) {
                    ForEach(TrickStatus.allCases) { status in
                        Text(status.title).tag(status)
                    }
                }
                .accessibilityIdentifier("training.progressStatus")
                Stepper(value: $draft.progress, in: 0...100, step: 5) {
                    Text("Progreso: \(draft.progress) %")
                }
                .accessibilityIdentifier("training.progressValue")
                Text("Una referencia personal, sin objetivos ni plazos.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Nota personal") {
                TextField("Qué le ayuda, qué quieres practicar…", text: $draft.customNotes, axis: .vertical)
                    .lineLimit(3...8)
                    .accessibilityIdentifier("training.progressNote")
            }
        }
    }

    private func save() async -> Bool {
        let record = draft
        return await store.update { snapshot in
            if let index = snapshot.training.selectedTricks.firstIndex(where: { $0.id == record.id }) {
                snapshot.training.selectedTricks[index] = record
            }
        }
    }
}

struct CustomTrickEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CustomTrick
    @State private var stepsText: String
    @State private var validationMessage: String?
    @State private var confirmDeletion = false
    @State private var isDeleting = false
    @State private var deletionFailed = false
    private let isNew: Bool

    init(record: CustomTrick? = nil) {
        let initial = record ?? CustomTrick()
        _draft = State(initialValue: initial)
        _stepsText = State(initialValue: initial.steps.joined(separator: "\n"))
        isNew = record == nil
    }

    var body: some View {
        CareForm(title: isNew ? "Crear truco" : "Editar truco", onSave: save) {
            if let validationMessage {
                Section {
                    Text(validationMessage).foregroundStyle(AppTheme.orange)
                        .accessibilityIdentifier("training.customValidation")
                }
            }
            Section("Tu truco") {
                TextField("Nombre", text: $draft.name)
                    .accessibilityIdentifier("training.customName")
                Picker("Categoría", selection: $draft.category) {
                    ForEach(TrickCategory.allCases) { value in Text(value.title).tag(value) }
                }
                Picker("Dificultad", selection: $draft.difficulty) {
                    ForEach(TrickDifficulty.allCases) { value in Text(value.title).tag(value) }
                }
            }
            Section("Guía propia") {
                TextField("Objetivo (opcional)", text: $draft.objective, axis: .vertical)
                    .lineLimit(2...5)
                    .accessibilityIdentifier("training.customObjective")
                TextField("Pasos (uno por línea, opcional)", text: $stepsText, axis: .vertical)
                    .lineLimit(4...10)
                    .accessibilityIdentifier("training.customSteps")
                TextField("Notas (opcional)", text: $draft.notes, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityIdentifier("training.customNotes")
            }
            if !isNew {
                Section {
                    Button("Eliminar truco personalizado", role: .destructive) { confirmDeletion = true }
                        .disabled(isDeleting)
                        .accessibilityIdentifier("training.deleteCustom")
                }
            }
        }
        .disabled(isDeleting)
        .confirmationDialog("¿Eliminar este truco personalizado?", isPresented: $confirmDeletion, titleVisibility: .visible) {
            Button("Eliminar truco", role: .destructive) { Task { await delete() } }
        } message: {
            Text("Se eliminarán la guía, el progreso y la nota personal de este truco.")
        }
        .alert("No se ha podido eliminar", isPresented: $deletionFailed) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text("El truco sigue guardado. Puedes volver a intentarlo.")
        }
    }

    private func save() async -> Bool {
        var record = draft
        record.name = record.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !record.name.isEmpty else {
            validationMessage = "Escribe un nombre para el truco."
            return false
        }
        record.objective = record.objective.trimmingCharacters(in: .whitespacesAndNewlines)
        record.notes = record.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        record.steps = stepsText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        validationMessage = nil
        let savedRecord = record
        return await store.update { snapshot in
            if let index = snapshot.training.customTricks.firstIndex(where: { $0.id == savedRecord.id }) {
                snapshot.training.customTricks[index] = savedRecord
            } else if isNew {
                snapshot.training.customTricks.append(savedRecord)
                snapshot.training.addTrick(savedRecord.trickID)
            }
        }
    }

    private func delete() async {
        guard !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }
        let id = draft.id
        if await store.update({ $0.training.removeCustomTrick(id) }) {
            dismiss()
        } else {
            deletionFailed = true
        }
    }
}

struct BehaviorObservationEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: BehaviorObservation
    @State private var validationMessage: String?
    @State private var confirmDeletion = false
    @State private var isDeleting = false
    @State private var deletionFailed = false
    private let isNew: Bool

    init(record: BehaviorObservation? = nil) {
        _draft = State(initialValue: record ?? BehaviorObservation())
        isNew = record == nil
    }

    var body: some View {
        CareForm(title: isNew ? "Añadir observación" : "Editar observación", onSave: save) {
            if let validationMessage {
                Section {
                    Text(validationMessage).foregroundStyle(AppTheme.orange)
                        .accessibilityIdentifier("training.observationValidation")
                }
            }
            Section("Comportamiento") {
                DatePicker("Fecha", selection: $draft.date, in: ...Date(), displayedComponents: .date)
                TextField("Título", text: $draft.title)
                    .accessibilityIdentifier("training.observationTitle")
                TextField("Qué has observado", text: $draft.observation, axis: .vertical)
                    .lineLimit(4...10)
                    .accessibilityIdentifier("training.observationBody")
            }
            Section("Detalles opcionales") {
                TextField("Contexto o qué le ha ayudado", text: $draft.context, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityIdentifier("training.observationContext")
                TextField("Estado, por ejemplo «En seguimiento»", text: $draft.status)
                    .accessibilityIdentifier("training.observationStatus")
            }
            Section {
                Text("Estas observaciones no sustituyen la valoración de un educador canino o profesional veterinario.")
                    .font(.footnote).foregroundStyle(.secondary)
                if !isNew {
                    Button("Eliminar observación", role: .destructive) { confirmDeletion = true }
                        .accessibilityIdentifier("training.deleteObservation")
                }
            }
        }
        .disabled(isDeleting)
        .confirmationDialog("¿Eliminar esta observación?", isPresented: $confirmDeletion, titleVisibility: .visible) {
            Button("Eliminar observación", role: .destructive) { Task { await delete() } }
        } message: {
            Text("La observación se eliminará del historial de comportamiento.")
        }
        .alert("No se ha podido eliminar", isPresented: $deletionFailed) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text("La observación sigue guardada. Puedes volver a intentarlo.")
        }
    }

    private func save() async -> Bool {
        var record = draft
        record.title = record.title.trimmingCharacters(in: .whitespacesAndNewlines)
        record.observation = record.observation.trimmingCharacters(in: .whitespacesAndNewlines)
        record.context = record.context.trimmingCharacters(in: .whitespacesAndNewlines)
        record.status = record.status.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !record.title.isEmpty, !record.observation.isEmpty else {
            validationMessage = "Escribe un título y lo que has observado."
            return false
        }
        validationMessage = nil
        let savedRecord = record
        return await store.update { snapshot in
            if let index = snapshot.training.observations.firstIndex(where: { $0.id == savedRecord.id }) {
                snapshot.training.observations[index] = savedRecord
            } else if isNew {
                snapshot.training.observations.append(savedRecord)
            }
        }
    }

    private func delete() async {
        guard !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }
        let id = draft.id
        if await store.update({ $0.training.observations.removeAll { $0.id == id } }) {
            dismiss()
        } else {
            deletionFailed = true
        }
    }
}

struct BehaviorHistoryView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editingRecord: BehaviorObservation?
    @State private var isAdding = false

    private var observations: [BehaviorObservation] {
        store.snapshot.training.observations.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            CarePage {
                if observations.isEmpty {
                    EmptyCareState(
                        title: "Todavía no hay observaciones", symbol: "pawprint",
                        message: "Aquí podrás volver a consultar lo que anotes sobre su comportamiento."
                    )
                } else {
                    CareSection(title: "Observaciones") {
                        ForEach(observations) { record in
                            Button { editingRecord = record } label: {
                                BehaviorObservationRow(record: record)
                            }
                            .buttonStyle(.plain)
                            if record.id != observations.last?.id { Divider() }
                        }
                    }
                }
            }
            .navigationTitle("Historial de comportamiento")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Añadir observación", systemImage: "plus") { isAdding = true }
                }
            }
            .sheet(item: $editingRecord) { BehaviorObservationEditor(record: $0) }
            .sheet(isPresented: $isAdding) { BehaviorObservationEditor() }
        }
        .trainingSheetSize()
    }
}
