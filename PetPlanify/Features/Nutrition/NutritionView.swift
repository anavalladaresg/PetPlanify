import SwiftUI

struct NutritionView: View {
    @Environment(PetPlanifyStore.self) private var store
    @State private var editingPlan = false
    @State private var addingTransition = false
    @State private var editingTransition: FoodTransition?
    @State private var addingObservation = false
    @State private var observationToDelete: PetObservation?
    var body: some View {
        CarePage {
            CareSection(title: "Plan de alimentación", style: .highlighted, symbol: "fork.knife") {
                if let plan = store.snapshot.nutrition.plan {
                    VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                        Text(plan.product.name).font(.title2.weight(.semibold)).fontDesign(.serif)
                        if !plan.product.brand.isEmpty {
                            Text(plan.product.brand).font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.green)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(AppTheme.greenSoft, in: Capsule())
                        }
                        Text(plan.product.type.title).font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                    }
                    HStack(spacing: AppTheme.Space.sm) {
                        nutritionMetric("Cantidad diaria", AppFormat.grams(plan.dailyAmountGrams))
                        nutritionMetric("Comidas", "\(plan.meals.count)")
                        Spacer(minLength: 0)
                    }
                    .padding(.top, AppTheme.Space.sm)
                    Text("Desde \(AppFormat.date(plan.startDate))").font(.caption).foregroundStyle(AppTheme.secondaryInk)
                    Divider().padding(.vertical, AppTheme.Space.xs)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Horario").font(.subheadline.weight(.medium)).padding(.bottom, AppTheme.Space.xs)
                        ForEach(plan.meals.sorted { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }) { meal in
                            HStack {
                                Image(systemName: "clock").foregroundStyle(AppTheme.green).accessibilityHidden(true)
                                Text(meal.time.formatted(date: .omitted, time: .shortened))
                                Spacer()
                                Text(AppFormat.grams(meal.amountGrams)).foregroundStyle(AppTheme.secondaryInk)
                            }.padding(.vertical, AppTheme.Space.sm)
                        }
                    }
                    if !plan.notes.isEmpty { Text(plan.notes).foregroundStyle(AppTheme.secondaryInk) }
                } else {
                    EmptyCareState(title: "Su alimentación, a su manera", symbol: "fork.knife", message: "Guarda el alimento, la cantidad y los horarios que ya sigues.", illustration: .bowl)
                }
                Button(store.snapshot.nutrition.plan == nil ? "Configurar alimentación" : "Editar plan") { editingPlan = true }
                    .buttonStyle(.borderedProminent).accessibilityIdentifier("foodPlan.edit")
            }
            if let transition = store.snapshot.nutrition.transitions.first(where: { !$0.isComplete }) {
                CareSection(title: "Cambio de alimento", style: .compact, symbol: "arrow.triangle.swap") {
                    Text("\(transition.previousFood) → \(transition.newFood)").font(.headline)
                    ProgressView(value: transition.progress).tint(AppTheme.orange).accessibilityValue(transition.progress.formatted(.percent))
                    Text("Hasta el \(AppFormat.date(transition.endDate))").foregroundStyle(AppTheme.secondaryInk)
                    Button("Actualizar transición") { editingTransition = transition }
                }
            }
            CareSection(title: "Observaciones", style: .plain, symbol: "square.and.pencil") {
                if store.snapshot.nutrition.observations.isEmpty {
                    Text("Anota cambios de apetito o tolerancia que quieras recordar.").font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                }
                ForEach(store.snapshot.nutrition.observations.sorted { $0.date > $1.date }) { item in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            if !item.title.isEmpty { Text(item.title).font(.headline) }
                            Text(item.body)
                            Text(AppFormat.date(item.date)).font(.caption).foregroundStyle(AppTheme.secondaryInk)
                        }
                        Spacer()
                        Button("Eliminar", systemImage: "trash", role: .destructive) { observationToDelete = item }.labelStyle(.iconOnly)
                    }
                }
                Button("Añadir observación", systemImage: "plus") { addingObservation = true }
            }
            CareSection(title: "Historial de alimentación", style: .plain, symbol: "clock.arrow.circlepath") {
                if store.snapshot.nutrition.history.isEmpty && store.snapshot.nutrition.transitions.isEmpty {
                    Text("Los cambios de plan se guardarán aquí.").foregroundStyle(AppTheme.secondaryInk)
                }
                ForEach(store.snapshot.nutrition.history.sorted { $0.endDate > $1.endDate }) { item in
                    VStack(alignment: .leading) {
                        Text(item.plan.product.name).font(.headline)
                        Text("\(AppFormat.date(item.plan.startDate)) – \(AppFormat.date(item.endDate))").font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                    }
                }
                ForEach(store.snapshot.nutrition.transitions.sorted { $0.startDate > $1.startDate }) { item in
                    Button { editingTransition = item } label: {
                        LabeledContent("\(item.previousFood) → \(item.newFood)", value: item.isComplete ? String(localized: "Completada") : item.progress.formatted(.percent))
                    }.buttonStyle(.plain)
                }
                Button("Añadir transición", systemImage: "arrow.triangle.swap") { addingTransition = true }
            }
        }
        .accessibilityIdentifier("nutrition.screen")
        .sheet(isPresented: $editingPlan) { FoodPlanEditor() }
        .sheet(isPresented: $addingTransition) { FoodTransitionEditor() }
        .sheet(item: $editingTransition) { FoodTransitionEditor(record: $0) }
        .sheet(isPresented: $addingObservation) { ObservationEditor(context: .nutrition) }
        .confirmationDialog("¿Eliminar esta observación?", isPresented: Binding(get: { observationToDelete != nil }, set: { if !$0 { observationToDelete = nil } })) {
            Button("Eliminar observación", role: .destructive) {
                guard let item = observationToDelete else { return }
                Task { _ = await store.update { $0.nutrition.observations.removeAll { $0.id == item.id } } }
            }
        }
    }

    private func nutritionMetric(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.headline).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(AppTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview { NavigationStack { NutritionView() }.environment(PetPlanifyStore.preview()) }
