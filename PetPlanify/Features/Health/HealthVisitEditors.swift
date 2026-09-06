import SwiftUI
import QuickLook
import UniformTypeIdentifiers

struct VisitEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    let record: VeterinaryVisit?
    @State private var date: Date
    @State private var reason: String
    @State private var clinic: String
    @State private var notes: String
    @State private var assessment: String
    @State private var treatment: String
    @State private var hasFollowUp: Bool
    @State private var followUp: Date
    @State private var error: String?

    init(record: VeterinaryVisit? = nil) {
        self.record = record
        _date = State(initialValue: record?.date ?? .now)
        _reason = State(initialValue: record?.reason ?? "")
        _clinic = State(initialValue: record?.clinic ?? "")
        _notes = State(initialValue: record?.notes ?? "")
        _assessment = State(initialValue: record?.assessment ?? "")
        _treatment = State(initialValue: record?.treatmentNotes ?? "")
        _hasFollowUp = State(initialValue: record?.followUpDate != nil)
        _followUp = State(initialValue: record?.followUpDate ?? record?.date ?? .now)
    }

    var body: some View {
        CareForm(title: record == nil ? "Añadir visita veterinaria" : "Editar visita", onSave: save) {
            Section("Visita veterinaria") {
                TextField("Motivo", text: $reason).accessibilityIdentifier("health.visitReason")
                DatePicker("Fecha y hora", selection: $date, displayedComponents: [.date, .hourAndMinute])
                TextField("Clínica", text: $clinic)
            }
            Section("Información de la consulta") {
                TextField("Valoración indicada por el profesional", text: $assessment, axis: .vertical).lineLimit(3...8)
                TextField("Tratamiento e indicaciones", text: $treatment, axis: .vertical).lineLimit(3...8)
            }
            Section("Notas") {
                TextField("Notas", text: $notes, axis: .vertical).lineLimit(3...8)
            }
            Section {
                Toggle("Añadir seguimiento", isOn: $hasFollowUp)
                if hasFollowUp {
                    DatePicker("Fecha y hora del seguimiento", selection: $followUp, in: date..., displayedComponents: [.date, .hourAndMinute])
                }
            } footer: { Text("Puedes adjuntar PDF e imágenes desde los detalles de la visita después de guardarla.") }
            if let error { Section { Text(error).foregroundStyle(.red) } }
            if let record {
                Section {
                    HealthDeleteButton(title: "Eliminar visita", message: "Se eliminará la visita. Sus documentos se conservarán en Documentos, sin vincular.") {
                        await store.update {
                            $0.health.visits.removeAll { $0.id == record.id }
                            for index in $0.health.documents.indices where $0.health.documents[index].linkedVisitID == record.id {
                                $0.health.documents[index].linkedVisitID = nil
                            }
                            for index in $0.health.medications.indices where $0.health.medications[index].relatedVisitID == record.id {
                                $0.health.medications[index].relatedVisitID = nil
                            }
                        }
                    }
                }
            }
        }
    }

    private func save() async -> Bool {
        guard !reason.healthTrimmed.isEmpty else { error = String(localized: "Escribe el motivo de la visita."); return false }
        guard !hasFollowUp || followUp >= date else { error = String(localized: "El seguimiento debe ser posterior a la visita."); return false }
        var value = record ?? VeterinaryVisit(reason: reason.healthTrimmed)
        value.date = date
        value.reason = reason.healthTrimmed
        value.clinic = clinic.healthTrimmed
        value.notes = notes.healthTrimmed
        value.assessment = assessment.healthOptional
        value.treatmentNotes = treatment.healthOptional
        value.followUpDate = hasFollowUp ? followUp : nil
        value.updatedAt = .now
        let success = await store.update {
            if let current = $0.health.visits.first(where: { $0.id == value.id }) { value.documentIDs = current.documentIDs }
            $0.health.visits.upsert(value)
        }
        if !success { error = String(localized: "No se pudo guardar la visita. Vuelve a intentarlo.") }
        return success
    }
}

struct VisitDetailView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let visitID: UUID
    @State private var sheet: HealthSheet?
    @State private var importing = false
    @State private var busy = false
    @State private var error: String?

    private var visit: VeterinaryVisit? { store.snapshot.health.visits.first { $0.id == visitID } }

    var body: some View {
        NavigationStack {
            CarePage {
                if let visit {
                    CareSection(title: "Visita veterinaria", style: .highlighted, symbol: "cross.case") {
                        Text(visit.reason).font(.title2.weight(.medium)).fontDesign(.serif)
                        LabeledContent("Fecha", value: AppFormat.dateTime(visit.date))
                        if !visit.clinic.isEmpty { LabeledContent("Clínica", value: visit.clinic) }
                        LabeledContent("Estado") {
                            Text(visit.status().title).foregroundStyle(visit.status().displayColor)
                        }
                        if let followUp = visit.followUpDate { LabeledContent("Seguimiento", value: AppFormat.dateTime(followUp)) }
                    }
                    if !visit.notes.isEmpty { textSection("Notas", visit.notes) }
                    if let assessment = visit.assessment { textSection("Valoración del profesional", assessment) }
                    if let treatment = visit.treatmentNotes { textSection("Tratamiento e indicaciones", treatment) }
                    if !linkedMedications.isEmpty {
                        CareSection(title: "Medicación relacionada", style: .compact, symbol: "pills") {
                            ForEach(linkedMedications) { medication in
                                HealthRecordRow(title: medication.name, subtitle: medication.status().title, symbol: "pills") { sheet = .medication(medication) }
                            }
                        }
                    }
                    CareSection(title: "Documentos", style: .compact, symbol: "paperclip") {
                        let documents = store.snapshot.health.documents.filter { $0.linkedVisitID == visitID }
                        if documents.isEmpty {
                            EmptyCareState(title: "Adjunta informes, resultados o la cartilla de vacunación.", symbol: "doc.text")
                        }
                        ForEach(documents) { document in HealthDocumentRow(document: document) }
                        Button("Adjuntar documento", systemImage: "paperclip") { importing = true }
                            .buttonStyle(.bordered)
                            .disabled(busy)
                            .accessibilityIdentifier("health.attachDocument")
                        if busy { ProgressView("Guardando documento…") }
                        Text("PDF e imágenes · hasta 50 MB por archivo").font(.caption).foregroundStyle(AppTheme.secondaryInk)
                    }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Detalle de la visita")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() }.disabled(busy) }
                ToolbarItem(placement: .primaryAction) {
                    if let visit { Button("Editar") { sheet = .visit(visit) }.disabled(busy) }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, idealWidth: 620, minHeight: 480, idealHeight: 680)
        #endif
        .interactiveDismissDisabled(busy)
        .sheet(item: $sheet) { HealthSheetContent(sheet: $0) }
        .onChange(of: visit == nil) { _, missing in if missing { dismiss() } }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf, .image], allowsMultipleSelection: false) { result in
            switch result {
            case let .success(urls):
                guard let url = urls.first else { return }
                busy = true
                Task {
                    if !(await store.importDocument(from: url, visitID: visitID)) {
                        error = String(localized: "No se pudo adjuntar el documento. Comprueba el formato y vuelve a intentarlo.")
                    } else { error = nil }
                    busy = false
                }
            case .failure:
                error = String(localized: "No se pudo abrir el documento seleccionado.")
            }
        }
    }

    private var linkedMedications: [MedicationRecord] { store.snapshot.health.medications.filter { $0.relatedVisitID == visitID } }
    private func textSection(_ title: LocalizedStringKey, _ text: String) -> some View {
        CareSection(title: title, style: .plain) {
            Text(text)
                .textSelection(.enabled)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
