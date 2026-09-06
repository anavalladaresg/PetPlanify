import SwiftUI

struct FoodPlanEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    @State private var plan = FoodPlan()
    @State private var amount = ""
    @State private var mealAmounts: [UUID: String] = [:]
    @State private var error: String?
    @State private var loaded = false
    var body: some View {
        CareForm(title: "Plan de alimentación", onSave: save) {
            Section("Alimento") {
                TextField("Producto", text: $plan.product.name)
                TextField("Marca", text: $plan.product.brand)
                Picker("Tipo", selection: $plan.product.type) { ForEach(FoodType.allCases) { Text($0.title).tag($0) } }
                DatePicker("Fecha de inicio", selection: $plan.startDate, in: ...Date.now, displayedComponents: .date)
            }
            Section("Cantidades y horarios") {
                TextField("Cantidad diaria (g)", text: $amount).decimalEntry()
                Stepper("\(plan.meals.count) comidas", value: Binding(get: { plan.meals.count }, set: resizeMeals), in: 1...8)
                Button("Repartir la cantidad por igual") { distribute() }
                ForEach($plan.meals) { $meal in
                    let mealNumber = (plan.meals.firstIndex { $0.id == meal.id } ?? 0) + 1
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Comida \(mealNumber)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.green)
                            .accessibilityAddTraits(.isHeader)
                        DatePicker("Hora", selection: $meal.time, displayedComponents: .hourAndMinute)
                            .accessibilityLabel("Hora de la comida \(mealNumber)")
                        TextField("Gramos", text: Binding(get: { mealAmounts[meal.id] ?? "" }, set: { mealAmounts[meal.id] = $0 }))
                            .decimalEntry().accessibilityLabel("Gramos de la comida \(mealNumber)")
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .contain)
                }
            }
            Section("Notas") { TextField("Notas opcionales", text: $plan.notes, axis: .vertical).lineLimit(3...6) }
            if let error { Section { Text(error).foregroundStyle(.red) } }
        }.onAppear {
            guard !loaded else { return }; loaded = true
            plan = store.snapshot.nutrition.plan ?? FoodPlan(meals: [MealScheduleEntry(hour: 9), MealScheduleEntry(hour: 20)])
            amount = plan.dailyAmountGrams > 0 ? AppFormat.number(plan.dailyAmountGrams) : ""
            mealAmounts = Dictionary(uniqueKeysWithValues: plan.meals.map { ($0.id, $0.amountGrams > 0 ? AppFormat.number($0.amountGrams) : "") })
        }
    }
    private func resizeMeals(_ count: Int) {
        while plan.meals.count < count { plan.meals.append(MealScheduleEntry(hour: 12)) }
        if plan.meals.count > count { plan.meals.removeLast(plan.meals.count - count) }
    }
    private func distribute() {
        guard let total = AppFormat.parseNumber(amount), !plan.meals.isEmpty else { return }
        let part = (total / Double(plan.meals.count) * 100).rounded(.down) / 100
        for (index, meal) in plan.meals.enumerated() {
            mealAmounts[meal.id] = AppFormat.number(index == plan.meals.count - 1 ? total - part * Double(index) : part)
        }
    }
    private func save() async -> Bool {
        guard let total = AppFormat.parseNumber(amount) else { error = String(localized: "Revisa la cantidad diaria."); return false }
        var value = plan
        value.product.name = value.product.name.trimmingCharacters(in: .whitespacesAndNewlines)
        value.dailyAmountGrams = total
        for index in value.meals.indices {
            guard let grams = AppFormat.parseNumber(mealAmounts[value.meals[index].id] ?? "") else { error = String(localized: "Revisa las cantidades de las comidas."); return false }
            value.meals[index].amountGrams = grams
        }
        if let validation = value.validationError { error = validation; return false }
        return await store.update {
            if let previous = $0.nutrition.plan, previous != value {
                $0.nutrition.history.append(FoodHistoryEntry(plan: previous, endDate: .now))
            }
            $0.nutrition.plan = value
        }
    }
}

struct FoodTransitionEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    var record: FoodTransition?
    @State private var value = FoodTransition()
    @State private var error: String?
    @State private var loaded = false
    var body: some View {
        CareForm(title: "Transición de alimento", onSave: save) {
            Section("Alimentos") {
                TextField("Alimento anterior", text: $value.previousFood)
                TextField("Nuevo alimento", text: $value.newFood)
            }
            Section("Transición") {
                DatePicker("Inicio", selection: $value.startDate, displayedComponents: .date)
                DatePicker("Final previsto", selection: $value.endDate, in: value.startDate..., displayedComponents: .date)
                Slider(value: $value.progress, in: 0...1, step: 0.05) { Text("Progreso") }
                LabeledContent("Progreso", value: value.progress.formatted(.percent))
                Button("Marcar como completada") { value.progress = 1 }
            }
            if let error { Text(error).foregroundStyle(.red) }
        }.onAppear {
            guard !loaded else { return }; loaded = true
            value = record ?? FoodTransition(newFood: store.snapshot.nutrition.plan?.product.name ?? "")
        }
    }
    private func save() async -> Bool {
        guard !value.previousFood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !value.newFood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, value.endDate >= value.startDate else {
            error = String(localized: "Indica ambos alimentos y revisa las fechas."); return false
        }
        return await store.update { $0.nutrition.transitions.upsert(value) }
    }
}
