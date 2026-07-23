import SwiftUI

struct NutritionMacView: View {
    let plan: FoodPlan
    @Binding var selectedRange: NutritionChartRange
    let onEditPlan: () -> Void
    let onShowHistory: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                NutritionHeader(
                    includesTitle: true,
                    onEditPlan: onEditPlan
                )

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        CurrentFoodCard(plan: plan, compact: false)
                            .frame(minWidth: 360)
                        NutritionMetricsGrid(plan: plan, compact: false)
                            .frame(minWidth: 430)
                    }
                    VStack(spacing: 14) {
                        CurrentFoodCard(plan: plan, compact: false)
                        NutritionMetricsGrid(plan: plan, compact: false)
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        MealScheduleCard(meals: plan.meals)
                            .frame(minWidth: 360)
                        FoodTransitionCard(
                            transition: plan.transition,
                            onShowHistory: onShowHistory
                        )
                        .frame(minWidth: 420)
                    }
                    VStack(spacing: 14) {
                        MealScheduleCard(meals: plan.meals)
                        FoodTransitionCard(
                            transition: plan.transition,
                            onShowHistory: onShowHistory
                        )
                    }
                }

                NutritionChartCard(
                    plan: plan,
                    selectedRange: $selectedRange,
                    compact: false
                )
            }
            .frame(maxWidth: 1_180, alignment: .leading)
            .padding(32)
        }
        .appCanvas()
        .accessibilityIdentifier("nutrition.screen")
    }
}
struct NutritionPhoneView: View {
    let plan: FoodPlan
    @Binding var selectedRange: NutritionChartRange
    let onEditPlan: () -> Void
    let onShowHistory: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                NutritionHeader(
                    includesTitle: false,
                    onEditPlan: onEditPlan
                )
                CurrentFoodCard(plan: plan, compact: true)
                NutritionMetricsGrid(plan: plan, compact: true)
                MealScheduleCard(meals: plan.meals)
                FoodTransitionCard(
                    transition: plan.transition,
                    onShowHistory: onShowHistory
                )
                NutritionChartCard(
                    plan: plan,
                    selectedRange: $selectedRange,
                    compact: true
                )

                Button(action: onShowHistory) {
                    Label("Ver historial de alimentos", systemImage: "clock.arrow.circlepath")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                .foregroundStyle(AppTheme.green)
                .accessibilityIdentifier("nutrition.showHistoryFooter")
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .appCanvas()
        .accessibilityIdentifier("nutrition.screen")
    }
}

private struct NutritionHeader: View {
    let includesTitle: Bool
    let onEditPlan: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 20) {
                titleBlock
                Spacer(minLength: 12)
                editButton
            }
            VStack(alignment: .leading, spacing: 14) {
                titleBlock
                editButton
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            if includesTitle {
                Text("Alimentación")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            Text("El plan diario de Neo, organizado con calma.")
                .font(includesTitle ? .title3 : .subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var editButton: some View {
        Button(action: onEditPlan) {
            Label("Editar plan", systemImage: "pencil")
                .frame(minHeight: 32)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityIdentifier("nutrition.editPlan")
    }
}

#Preview("Alimentación · macOS") {
    NutritionMacView(
        plan: NutritionPreviewData.neoPlan,
        selectedRange: .constant(.threeMonths),
        onEditPlan: {},
        onShowHistory: {}
    )
    .frame(width: 1_080, height: 820)
}

#Preview("Alimentación · iPhone") {
    NavigationStack {
        NutritionPhoneView(
            plan: NutritionPreviewData.neoPlan,
            selectedRange: .constant(.threeMonths),
            onEditPlan: {},
            onShowHistory: {}
        )
        .navigationTitle("Alimentación")
    }
    .frame(width: 393, height: 852)
}
