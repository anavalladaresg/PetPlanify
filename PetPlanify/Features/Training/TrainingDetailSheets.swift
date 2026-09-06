import SwiftUI

/// A sheet entry point shared by Entrenamiento and the Home quick action.
struct TrickLibraryView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
                CareSection(title: "Filtrar trucos", style: .compact) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: AppTheme.Space.xl) { filters }
                        VStack(alignment: .leading, spacing: AppTheme.Space.md) { filters }
                    }
                }
                CareSection(title: "Trucos disponibles", style: .plain) {
                    if filteredLibrary.isEmpty {
                        EmptyCareState(
                            title: "No hay trucos con estos filtros", symbol: "line.3.horizontal.decrease",
                            message: "Prueba otra categoría o dificultad."
                        )
                        Button("Quitar filtros") { difficulty = nil; category = nil }
                    }
                    TrainingTileLayout(singleColumn: dynamicTypeSize.isAccessibilitySize) {
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
                        }
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

    @ViewBuilder
    private var filters: some View {
        Picker("Dificultad", selection: $difficulty) {
            Text("Todas").tag(TrickDifficulty?.none)
            ForEach(TrickDifficulty.allCases) { value in
                Text(value.title).tag(Optional(value))
            }
        }
        .pickerStyle(.menu)
        .accessibilityIdentifier("training.filterDifficulty")
        Picker("Categoría", selection: $category) {
            Text("Todas").tag(TrickCategory?.none)
            ForEach(TrickCategory.allCases) { value in
                Text(value.title).tag(Optional(value))
            }
        }
        .pickerStyle(.menu)
        .accessibilityIdentifier("training.filterCategory")
    }
}

struct TrickDetailView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    if !definition.guide.objective.isEmpty {
                        CareSection(title: "Objetivo", style: .highlighted) {
                            Text(definition.guide.objective)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let selected {
                        CareSection(title: "Mi progreso", style: .compact) {
                            ViewThatFits(in: .horizontal) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(selected.status.title).font(.headline)
                                    Spacer(minLength: AppTheme.Space.sm)
                                    progressValue(selected.progress)
                                }
                                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                                    Text(selected.status.title).font(.headline)
                                    progressValue(selected.progress)
                                }
                            }
                            ProgressView(value: Double(selected.progress), total: 100)
                                .tint(AppTheme.green)
                                .accessibilityLabel("Progreso")
                                .accessibilityValue("\(selected.progress) por ciento")
                                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: selected.progress)
                            Text("Añadido el \(TrainingFormatting.date(selected.addedAt))")
                                .font(.footnote).foregroundStyle(AppTheme.secondaryInk)
                            if !selected.customNotes.isEmpty {
                                Text(selected.customNotes).font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Button("Editar progreso y nota", systemImage: "pencil") { isEditingProgress = true }
                                .frame(minHeight: 44)
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
        .navigationTitle("Guía del truco")
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
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: AppTheme.Space.md))
            : AnyLayout(HStackLayout(alignment: .center, spacing: AppTheme.Space.lg))
        return VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            layout {
                TrickIllustration(
                    definition: definition,
                    width: dynamicTypeSize.isAccessibilitySize ? 150 : 164,
                    height: dynamicTypeSize.isAccessibilitySize ? 118 : 132
                )
                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    Text(definition.name)
                        .font(.title.weight(.semibold))
                        .fontDesign(.serif)
                        .accessibilityAddTraits(.isHeader)
                    Text(customTrick == nil ? "Guía práctica para hacerlo juntos" : "Guía escrita por ti")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AppTheme.Space.sm) {
                    metadata(for: definition)
                    Spacer(minLength: AppTheme.Space.sm)
                    if let selected { TrainingProgressRing(value: Double(selected.progress) / 100, label: "Progreso") }
                }
                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    metadata(for: definition)
                    if let selected {
                        HStack(spacing: AppTheme.Space.sm) {
                            TrainingProgressRing(value: Double(selected.progress) / 100, label: "Progreso")
                            Text("\(selected.progress)% completado")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.secondaryInk)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                colors: [AppTheme.greenSoft.opacity(0.76), AppTheme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .appSurface(cornerRadius: AppTheme.heroRadius, elevated: true)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func metadata(for definition: TrickDefinition) -> some View {
        Text(definition.difficulty.title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.green)
            .padding(.horizontal, AppTheme.Space.md)
            .padding(.vertical, AppTheme.Space.xs)
            .background(AppTheme.greenSoft.opacity(0.78), in: Capsule())
        Text(definition.category.title)
            .font(.subheadline)
            .foregroundStyle(AppTheme.secondaryInk)
    }

    @ViewBuilder
    private func guide(_ definition: TrickDefinition) -> some View {
        if !definition.prerequisites.isEmpty || !definition.guide.requiredMaterials.isEmpty {
            CareSection(title: "Antes de empezar", style: .compact, symbol: "leaf") {
                if !definition.prerequisites.isEmpty {
                    Text(definition.prerequisites.joined(separator: " · "))
                        .font(.subheadline.weight(.medium))
                }
                if !definition.guide.requiredMaterials.isEmpty {
                    Text(definition.guide.requiredMaterials)
                        .font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        if !definition.guide.steps.isEmpty {
            CareSection(title: "Paso a paso", style: .plain) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(definition.guide.steps.enumerated()), id: \.offset) { index, step in
                        TrainingGuideStep(number: index + 1, text: step, isLast: index == definition.guide.steps.count - 1)
                    }
                }
            }
        }
        if !definition.guide.commonMistakes.isEmpty {
            CareSection(title: "Errores que conviene evitar", style: .compact) {
                ForEach(definition.guide.commonMistakes, id: \.self) { mistake in
                    HStack(alignment: .top, spacing: AppTheme.Space.sm) {
                        Circle().fill(AppTheme.secondaryInk.opacity(0.5))
                            .frame(width: 4, height: 4).padding(.top, AppTheme.Space.sm)
                            .accessibilityHidden(true)
                        Text(mistake).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        if !definition.guide.recommendedAttemptDuration.isEmpty || !definition.guide.rewardGuidance.isEmpty || !definition.guide.progressionCriteria.isEmpty {
            CareSection(title: "A su ritmo", style: .compact, symbol: "heart") {
                advice(title: "Intentos breves", text: definition.guide.recommendedAttemptDuration)
                advice(title: "Cómo recompensar", text: definition.guide.rewardGuidance)
                advice(title: "Cuándo avanzar", text: definition.guide.progressionCriteria)
            }
        }
        TrainingGuideSection(title: "Precauciones", text: definition.guide.precautions)
    }

    @ViewBuilder
    private func advice(title: LocalizedStringKey, text: String) -> some View {
        if !text.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func progressValue(_ value: Int) -> some View {
        Text("\(value) %")
            .font(.title3.weight(.medium).monospacedDigit())
            .foregroundStyle(AppTheme.green)
            .accessibilityHidden(true)
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
