import SwiftUI

/// A sheet entry point shared by Entrenamiento and the Home quick action.
struct TrickLibraryView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var difficulty: TrickDifficulty?
    @State private var category: TrickCategory?
    @State private var isCreatingCustom = false

    private var filteredLibrary: [TrickDefinition] {
        store.snapshot.training.library.filter {
            (difficulty == nil || $0.difficulty == difficulty) &&
            (category == nil || $0.category == category)
        }
    }

    var body: some View {
        NavigationStack {
            CarePage {
                CareSection(title: "Filtrar trucos") {
                    Picker("Dificultad", selection: $difficulty) {
                        Text("Todas").tag(TrickDifficulty?.none)
                        ForEach(TrickDifficulty.allCases) { value in
                            Text(value.title).tag(Optional(value))
                        }
                    }
                    .accessibilityIdentifier("training.filterDifficulty")
                    Picker("Categoría", selection: $category) {
                        Text("Todas").tag(TrickCategory?.none)
                        ForEach(TrickCategory.allCases) { value in
                            Text(value.title).tag(Optional(value))
                        }
                    }
                    .accessibilityIdentifier("training.filterCategory")
                }
                CareSection(title: "Trucos disponibles") {
                    if filteredLibrary.isEmpty {
                        EmptyCareState(
                            title: "No hay trucos con estos filtros", symbol: "line.3.horizontal.decrease",
                            message: "Prueba otra categoría o dificultad."
                        )
                        Button("Quitar filtros") { difficulty = nil; category = nil }
                    }
                    ForEach(filteredLibrary) { definition in
                        NavigationLink {
                            TrickDetailView(trickID: definition.id)
                        } label: {
                            TrainingTrickRow(
                                definition: definition,
                                selected: store.snapshot.training.selectedTricks.first { $0.trickID == definition.id },
                                isCustom: definition.id.hasPrefix("custom-")
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("training.library.\(definition.id)")
                        if definition.id != filteredLibrary.last?.id { Divider() }
                    }
                }
            }
            .navigationTitle("Explorar trucos")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Crear truco", systemImage: "plus") { isCreatingCustom = true }
                }
            }
            .sheet(isPresented: $isCreatingCustom) { CustomTrickEditor() }
        }
        .trainingSheetSize()
    }
}

struct TrickDetailView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let trickID: String
    @State private var isEditingProgress = false
    @State private var isEditingCustom = false
    @State private var confirmRemoval = false
    @State private var isSaving = false
    @State private var saveFailed = false

    private var definition: TrickDefinition? { store.snapshot.training.definition(for: trickID) }
    private var selected: SelectedTrick? {
        store.snapshot.training.selectedTricks.first { $0.trickID == trickID }
    }
    private var customTrick: CustomTrick? {
        store.snapshot.training.customTricks.first { $0.trickID == trickID }
    }

    var body: some View {
        Group {
            if let definition {
                CarePage {
                    intro(definition)
                    if let selected {
                        CareSection(title: "Mi progreso") {
                            Text("\(selected.status.title) · \(selected.progress) %").font(.headline)
                            ProgressView(value: Double(selected.progress), total: 100)
                                .tint(AppTheme.green)
                                .accessibilityLabel("Progreso")
                                .accessibilityValue("\(selected.progress) por ciento")
                            Text("Añadido el \(TrainingFormatting.date(selected.addedAt))")
                                .font(.footnote).foregroundStyle(AppTheme.secondaryInk)
                            if !selected.customNotes.isEmpty { Text(selected.customNotes) }
                            Button("Editar progreso y nota", systemImage: "pencil") { isEditingProgress = true }
                                .accessibilityIdentifier("training.editProgress")
                        }
                    } else {
                        Button {
                            Task { await addTrick() }
                        } label: {
                            Label("Añadir a Mis trucos", systemImage: "plus")
                                .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaving)
                        .accessibilityIdentifier("training.addToMyTricks")
                    }
                    guide(definition)
                    if let customTrick, !customTrick.notes.isEmpty {
                        TrainingGuideSection(title: "Notas de la guía", text: customTrick.notes)
                    }
                    if selected != nil {
                        Button("Quitar de Mis trucos", role: .destructive) { confirmRemoval = true }
                            .disabled(isSaving)
                            .accessibilityIdentifier("training.removeSelected")
                    }
                }
            } else {
                ContentUnavailableView("Este truco ya no está disponible", systemImage: "pawprint")
            }
        }
        .navigationTitle(definition?.name ?? "Truco")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Cerrar") { dismiss() }
            }
            if customTrick != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button("Editar guía", systemImage: "pencil") { isEditingCustom = true }
                        .accessibilityIdentifier("training.editCustom")
                }
            }
        }
        .sheet(isPresented: $isEditingProgress) {
            if let selected { SelectedTrickEditor(record: selected) }
        }
        .sheet(isPresented: $isEditingCustom) {
            if let customTrick { CustomTrickEditor(record: customTrick) }
        }
        .confirmationDialog("¿Quitar este truco de Mis trucos?", isPresented: $confirmRemoval, titleVisibility: .visible) {
            Button("Quitar truco", role: .destructive) { Task { await removeTrick() } }
        } message: {
            Text("Se eliminarán su progreso y su nota personal. La guía seguirá en la biblioteca.")
        }
        .alert("No se ha podido guardar", isPresented: $saveFailed) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text("El cambio no se ha guardado. Puedes volver a intentarlo.")
        }
        .trainingSheetSize()
    }

    private func intro(_ definition: TrickDefinition) -> some View {
        HStack(alignment: .top, spacing: 14) {
            TrickIllustration(definition: definition)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(definition.difficulty.title) · \(definition.category.title)")
                    .font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                if !definition.guide.objective.isEmpty { Text(definition.guide.objective) }
                if customTrick != nil {
                    Text("Guía escrita por ti").font(.footnote).foregroundStyle(AppTheme.secondaryInk)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func guide(_ definition: TrickDefinition) -> some View {
        if !definition.prerequisites.isEmpty {
            TrainingGuideSection(title: "Antes de empezar", text: definition.prerequisites.joined(separator: " · "))
        }
        TrainingGuideSection(title: "Qué necesitas", text: definition.guide.requiredMaterials)
        if !definition.guide.steps.isEmpty {
            CareSection(title: "Paso a paso") {
                ForEach(Array(definition.guide.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.body.weight(.semibold)).foregroundStyle(AppTheme.green)
                        Text(step).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        if !definition.guide.commonMistakes.isEmpty {
            CareSection(title: "Errores que conviene evitar") {
                ForEach(definition.guide.commonMistakes, id: \.self) { mistake in
                    Text(mistake).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        TrainingGuideSection(title: "Intentos breves", text: definition.guide.recommendedAttemptDuration)
        TrainingGuideSection(title: "Cómo recompensar", text: definition.guide.rewardGuidance)
        TrainingGuideSection(title: "Cuándo avanzar", text: definition.guide.progressionCriteria)
        TrainingGuideSection(title: "Precauciones", text: definition.guide.precautions)
    }

    private func addTrick() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        saveFailed = !(await store.update { $0.training.addTrick(trickID) })
    }

    private func removeTrick() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        saveFailed = !(await store.update { $0.training.selectedTricks.removeAll { $0.trickID == trickID } })
    }
}
