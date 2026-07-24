import SwiftUI

struct NutritionMacView: View {
    let plan: FoodPlan
    let onEditPlan: () -> Void
    let onShowHistory: () -> Void

    var body: some View {
        NutritionDashboardContent(
            plan: plan,
            includesTitle: true,
            compact: false,
            onEditPlan: onEditPlan,
            onShowHistory: onShowHistory
        )
    }
}

struct NutritionPhoneView: View {
    let plan: FoodPlan
    let onEditPlan: () -> Void
    let onShowHistory: () -> Void

    var body: some View {
        NutritionDashboardContent(
            plan: plan,
            includesTitle: false,
            compact: true,
            onEditPlan: onEditPlan,
            onShowHistory: onShowHistory
        )
    }
}

private struct NutritionDashboardContent: View {
    let plan: FoodPlan
    let includesTitle: Bool
    let compact: Bool
    let onEditPlan: () -> Void
    let onShowHistory: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: compact ? 16 : 20) {
                header

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        CurrentFoodCard(plan: plan, compact: false)
                        VStack(spacing: 14) {
                            planFacts
                            MealScheduleCard(meals: plan.meals)
                        }
                        .frame(minWidth: 360)
                    }
                    VStack(spacing: 14) {
                        CurrentFoodCard(plan: plan, compact: true)
                        planFacts
                        MealScheduleCard(meals: plan.meals)
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        completedTransition
                        nutritionObservation
                    }
                    VStack(spacing: 14) {
                        completedTransition
                        nutritionObservation
                    }
                }
            }
            .frame(maxWidth: 1_080, alignment: .leading)
            .padding(compact ? 18 : 28)
        }
        .appCanvas()
        .accessibilityIdentifier("nutrition.screen")
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                titleBlock
                Spacer()
                editButton
            }
            VStack(alignment: .leading, spacing: 12) {
                titleBlock
                editButton
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            if includesTitle {
                Text("Alimentación")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("El plan diario de Neo")
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private var editButton: some View {
        Button(action: onEditPlan) {
            Label("Editar plan", systemImage: "pencil")
                .frame(minHeight: 34)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("nutrition.editPlan")
    }

    private var planFacts: some View {
        HStack(spacing: 0) {
            fact("Cantidad diaria", NutritionFormatting.grams(plan.dailyAmountGrams))
            Divider().frame(height: 38)
            fact("Comidas", "\(plan.mealsPerDay) al día")
        }
        .padding(15)
        .appSurface(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }

    private func fact(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(AppTheme.secondaryInk)
            Text(value).font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }

    private var completedTransition: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Cambio de alimento completado", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.green)
            Text("Desde el 10 de mayo · anteriormente \(plan.transition.previousFood.name)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
            Button("Ver historial", action: onShowHistory)
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appSurface(cornerRadius: 16)
        .accessibilityIdentifier("nutrition.transition")
    }

    private var nutritionObservation: some View {
        let observation = DailyCarePreviewData.observations.first { $0.context == .nutrition }!
        return VStack(alignment: .leading, spacing: 7) {
            Text("Observación reciente").font(.headline)
            Text(observation.title).font(.subheadline.weight(.semibold))
            Text(observation.body)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appSurface(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Alimentación · macOS") {
    NutritionMacView(plan: NutritionPreviewData.neoPlan, onEditPlan: {}, onShowHistory: {})
        .frame(width: 1_080, height: 760)
}

#Preview("Alimentación · iPhone") {
    NavigationStack {
        NutritionPhoneView(plan: NutritionPreviewData.neoPlan, onEditPlan: {}, onShowHistory: {})
    }
    .frame(width: 393, height: 852)
}
