import SwiftUI

struct CurrentFoodCard: View {
    let plan: FoodPlan
    let compact: Bool

    var body: some View {
        Group {
            if compact {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) {
                        packagePlaceholder
                            .frame(width: 92)
                        foodDetails
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        packagePlaceholder
                            .frame(maxWidth: .infinity)
                        foodDetails
                    }
                }
            } else {
                HStack(spacing: 22) {
                    packagePlaceholder
                        .frame(width: 132)
                    foodDetails
                }
            }
        }
        .padding(compact ? 16 : 20)
        .appSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Alimento actual, \(plan.currentFood.name), marca \(plan.currentFood.brand), \(plan.currentFood.type.localizedName), desde \(NutritionFormatting.date(plan.startDate))"
        )
        .accessibilityIdentifier("nutrition.currentFood")
    }

    private var packagePlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                .font(.system(size: compact ? 34 : 42, weight: .light))
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text(plan.currentFood.brand)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.orange)
        }
        .frame(maxWidth: compact ? .infinity : 132, minHeight: compact ? 104 : 146)
        .background(AppTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 0.75)
        )
    }

    private var foodDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Alimento actual")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryInk)
            Text(plan.currentFood.name)
                .font(.system(.title3, design: .serif, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 5) {
                Label(plan.currentFood.brand, systemImage: "building.2")
                Label(plan.currentFood.type.localizedName, systemImage: "leaf")
                Label(
                    String(localized: "Desde \(NutritionFormatting.date(plan.startDate))"),
                    systemImage: "calendar"
                )
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.secondaryInk)
            .labelStyle(NutritionDetailLabelStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NutritionDetailLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .foregroundStyle(AppTheme.green)
                .frame(width: 16)
            configuration.title
        }
    }
}

struct NutritionMetricsGrid: View {
    let plan: FoodPlan
    let compact: Bool

    private var columns: [GridItem] {
        if compact {
            [GridItem(.adaptive(minimum: 128), spacing: 12)]
        } else {
            Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            NutritionMetricCard(
                title: "Cantidad diaria",
                value: NutritionFormatting.grams(plan.dailyAmountGrams),
                symbol: "scalemass",
                accent: AppTheme.orange
            )
            NutritionMetricCard(
                title: "Comidas",
                value: String(localized: "\(plan.mealsPerDay) al día"),
                symbol: "fork.knife",
                accent: AppTheme.green
            )
        }
    }
}

struct NutritionMetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let symbol: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 32, height: 32)
                .background(accent.opacity(0.11), in: Circle())
                .accessibilityHidden(true)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
            Text(value)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(16)
        .appSurface(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }
}

struct MealScheduleCard: View {
    let meals: [ScheduledMeal]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Horario de comidas", systemImage: "clock")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
                .padding(.bottom, 10)

            ForEach(meals) { meal in
                MealRow(meal: meal)
                if meal.id != meals.last?.id {
                    Divider()
                        .overlay(AppTheme.border)
                }
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("nutrition.mealSchedule")
    }
}

private struct MealRow: View {
    let meal: ScheduledMeal

    var body: some View {
        HStack(spacing: 14) {
            Text(meal.time)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(AppTheme.orange)
            Text(meal.kind.localizedName)
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 8)
            Text(NutritionFormatting.grams(meal.amountGrams))
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .padding(.vertical, 11)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(meal.kind.localizedName), \(meal.time), \(NutritionFormatting.grams(meal.amountGrams))"
        )
    }
}

struct FoodTransitionCard: View {
    let transition: FoodTransition
    let onShowHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Label("Transición de alimento", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.headline)
                Spacer(minLength: 8)
                Text(transition.progress, format: .percent.precision(.fractionLength(0)))
                    .font(.headline)
                    .foregroundStyle(AppTheme.green)
            }

            ProgressView(value: transition.progress)
                .tint(AppTheme.green)
                .accessibilityLabel("Progreso de la transición")
                .accessibilityValue(Text(
                    transition.progress,
                    format: .percent.precision(.fractionLength(0))
                ))

            VStack(alignment: .leading, spacing: 10) {
                FoodTransitionRow(
                    title: "Alimento actual",
                    name: transition.currentFood.name,
                    symbol: "checkmark.circle.fill",
                    accent: AppTheme.green
                )
                FoodTransitionRow(
                    title: "Alimento anterior",
                    name: transition.previousFood.name,
                    symbol: "clock.arrow.circlepath",
                    accent: AppTheme.secondaryInk
                )
            }

            ViewThatFits(in: .horizontal) {
                HStack {
                    completionStatus
                    Spacer(minLength: 8)
                    historyButton
                }
                VStack(alignment: .leading, spacing: 12) {
                    completionStatus
                    historyButton
                }
            }
        }
        .padding(20)
        .appSurface()
        .accessibilityIdentifier("nutrition.transition")
    }

    private var completionStatus: some View {
        Label(
            String(localized: "Completada el \(NutritionFormatting.date(transition.completionDate))"),
            systemImage: "checkmark.seal.fill"
        )
        .font(.caption)
        .foregroundStyle(AppTheme.green)
    }

    private var historyButton: some View {
        Button("Ver historial", action: onShowHistory)
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.green)
            .frame(minHeight: 44)
            .accessibilityIdentifier("nutrition.showHistory")
    }
}

private struct FoodTransitionRow: View {
    let title: LocalizedStringKey
    let name: String
    let symbol: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Tarjeta de alimento") {
    CurrentFoodCard(plan: NutritionPreviewData.neoPlan, compact: false)
        .frame(width: 540)
        .padding()
        .appCanvas()
}
