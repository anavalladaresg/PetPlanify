import SwiftUI

struct FoodPlanEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    @State private var plan = FoodPlan()
    @State private var amount = ""
    @State private var mealAmounts: [UUID: String] = [:]
    @State private var usesAutomaticDistribution = true
    @State private var error: String?
    @State private var loaded = false
    var body: some View {
        CareForm(title: "Plan de alimentación", onSave: save, error: $error, symbol: "fork.knife") {
            Section("Alimento") {
                TextField("Marca", text: $plan.product.brand)
                Picker("Tipo", selection: $plan.product.type) { ForEach(FoodType.allCases) { Text($0.title).tag($0) } }
                if plan.product.type == .other {
                    TextField(
                        "Describe el tipo de alimento",
                        text: Binding(
                            get: { plan.product.customTypeDescription ?? "" },
                            set: { plan.product.customTypeDescription = $0.isEmpty ? nil : $0 }
                        )
                    )
                    Text("Por ejemplo: dieta veterinaria, liofilizado o preparado personalizado.")
                        .font(.caption).foregroundStyle(AppTheme.secondaryInk)
                }
                DatePicker("Fecha de inicio", selection: $plan.startDate, displayedComponents: .date)
            }
            Section("Cantidades y horarios") {
                TextField("Cantidad diaria (g)", text: $amount).decimalEntry()
                Stepper("\(plan.meals.count) comidas", value: Binding(get: { plan.meals.count }, set: resizeMeals), in: 1...8)
                if usesAutomaticDistribution {
                    Text("Repartimos la cantidad diaria por igual. Puedes ajustar cada comida si lo necesitas.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                } else {
                    Button("Repartir la cantidad por igual") {
                        usesAutomaticDistribution = true
                        distribute()
                    }
                }
                ForEach($plan.meals) { $meal in
                    let mealNumber = (plan.meals.firstIndex { $0.id == meal.id } ?? 0) + 1
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Comida \(mealNumber)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.green)
                        HStack(alignment: .bottom, spacing: 16) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Horario").font(.caption.weight(.medium)).foregroundStyle(AppTheme.secondaryInk)
                                DatePicker("Hora", selection: $meal.time, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .accessibilityLabel("Horario de la comida \(mealNumber)")
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Cantidad").font(.caption.weight(.medium)).foregroundStyle(AppTheme.secondaryInk)
                                HStack(spacing: 6) {
                                    TextField("0", text: Binding(
                                        get: { mealAmounts[meal.id] ?? "" },
                                        set: {
                                            mealAmounts[meal.id] = $0
                                            usesAutomaticDistribution = false
                                        }
                                    ))
                                    .decimalEntry()
                                    .multilineTextAlignment(.trailing)
                                    .frame(minWidth: 64, idealWidth: 76)
                                    Text("g").foregroundStyle(AppTheme.secondaryInk)
                                }
                                .padding(.horizontal, 10)
                                .frame(minHeight: 36)
                                .background(AppTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Cantidad de la comida \(mealNumber), en gramos")
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .contain)
                }
            }
            Section("Notas") { TextField("Notas opcionales", text: $plan.notes, axis: .vertical).lineLimit(3...6) }
        }.onAppear {
            guard !loaded else { return }; loaded = true
            plan = store.snapshot.nutrition.plan ?? FoodPlan(meals: [MealScheduleEntry(hour: 9), MealScheduleEntry(hour: 20)])
            usesAutomaticDistribution = isEvenlyDistributed(plan.meals, total: plan.dailyAmountGrams)
            amount = plan.dailyAmountGrams > 0 ? AppFormat.number(plan.dailyAmountGrams) : ""
            mealAmounts = Dictionary(uniqueKeysWithValues: plan.meals.map { ($0.id, $0.amountGrams > 0 ? AppFormat.number($0.amountGrams) : "") })
            if usesAutomaticDistribution { distribute() }
        }
        .onChange(of: amount) { _, _ in
            if usesAutomaticDistribution { distribute() }
        }
    }
    private func resizeMeals(_ count: Int) {
        while plan.meals.count < count { plan.meals.append(MealScheduleEntry(hour: 12)) }
        if plan.meals.count > count { plan.meals.removeLast(plan.meals.count - count) }
        if usesAutomaticDistribution { distribute() }
    }
    private func distribute() {
        guard let total = AppFormat.parseNumber(amount), !plan.meals.isEmpty else { return }
        let part = (total / Double(plan.meals.count) * 100).rounded(.down) / 100
        for (index, meal) in plan.meals.enumerated() {
            mealAmounts[meal.id] = AppFormat.number(index == plan.meals.count - 1 ? total - part * Double(index) : part)
        }
    }

    private func isEvenlyDistributed(_ meals: [MealScheduleEntry], total: Double) -> Bool {
        guard total > 0, !meals.isEmpty else { return true }
        let expected = total / Double(meals.count)
        return meals.allSatisfy { abs($0.amountGrams - expected) < 0.02 }
    }

    private func save() async -> Bool {
        guard let total = AppFormat.parseNumber(amount) else { error = String(localized: "Revisa la cantidad diaria."); return false }
        if usesAutomaticDistribution { distribute() }
        var value = plan
        value.product.brand = value.product.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        value.product.name = value.product.brand
        value.dailyAmountGrams = total
        for index in value.meals.indices {
            guard let grams = AppFormat.parseNumber(mealAmounts[value.meals[index].id] ?? "") else { error = String(localized: "Revisa las cantidades de las comidas."); return false }
            value.meals[index].amountGrams = grams
        }
        if let validation = value.validationError { error = validation; return false }
        let saved = await store.update {
            if let previous = $0.nutrition.plan, previous != value {
                $0.nutrition.history.append(FoodHistoryEntry(plan: previous, endDate: .now))
            }
            $0.nutrition.plan = value
        }
        if !saved { error = store.message ?? String(localized: "No se ha podido guardar el plan de alimentación.") }
        return saved
    }
}

struct FoodTransitionEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    var record: FoodTransition?
    @State private var value = FoodTransition()
    @State private var error: String?
    @State private var loaded = false
    var body: some View {
        CareForm(title: "Transición de alimento", onSave: save, symbol: "arrow.triangle.2.circlepath") {
            Section("Alimentos") {
                TextField("Alimento anterior", text: $value.previousFood)
                TextField("Nuevo alimento", text: $value.newFood)
            }
            Section("Transición") {
                DatePicker("Inicio", selection: $value.startDate, displayedComponents: .date)
                DatePicker("Final previsto", selection: $value.endDate, displayedComponents: .date)
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
        let saved = await store.update { $0.nutrition.transitions.upsert(value) }
        if !saved { error = store.message ?? String(localized: "No se ha podido guardar la transición.") }
        return saved
    }
}
