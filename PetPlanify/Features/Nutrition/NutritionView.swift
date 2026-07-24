import SwiftUI

struct NutritionView: View {
    private enum PresentedSheet: String, Identifiable {
        case editPlan
        case foodHistory

        var id: String { rawValue }
    }

    @State private var presentedSheet: PresentedSheet?

    private let plan = NutritionPreviewData.neoPlan

    var body: some View {
        Group {
            #if os(macOS)
            NutritionMacView(
                plan: plan,
                onEditPlan: { presentedSheet = .editPlan },
                onShowHistory: { presentedSheet = .foodHistory }
            )
            #else
            NutritionPhoneView(
                plan: plan,
                onEditPlan: { presentedSheet = .editPlan },
                onShowHistory: { presentedSheet = .foodHistory }
            )
            #endif
        }
        .environment(\.locale, NutritionFormatting.spanishLocale)
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .editPlan:
                EditPlanPreviewSheet {
                    presentedSheet = nil
                }
            case .foodHistory:
                FoodHistorySheet(plan: plan) {
                    presentedSheet = nil
                }
            }
        }
    }
}

private struct EditPlanPreviewSheet: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pencil.and.list.clipboard")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text("Editar plan")
                .font(.system(.title2, design: .serif, weight: .semibold))
            Text("La edición se añadirá más adelante. Por ahora, este panel utiliza datos de ejemplo y no guarda cambios.")
                .foregroundStyle(AppTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Cerrar", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.green)
                .controlSize(.large)
        }
        .frame(maxWidth: 420)
        .padding(32)
        .appCanvas()
        .accessibilityIdentifier("nutrition.editPlanSheet")
    }
}

private struct FoodHistorySheet: View {
    let plan: FoodPlan
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Historial de alimentos")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                    Text("Cambios recientes del plan de Neo")
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer()
                Button("Cerrar", action: onDismiss)
                    .buttonStyle(.bordered)
            }

            VStack(spacing: 0) {
                ForEach(plan.foodHistory) { entry in
                    FoodHistoryRow(entry: entry)
                    if entry.id != plan.foodHistory.last?.id {
                        Divider()
                            .overlay(AppTheme.border)
                    }
                }
            }
            .padding(.horizontal, 18)
            .appSurface()
        }
        .frame(minWidth: 320, idealWidth: 520, maxWidth: 620)
        .padding(28)
        .appCanvas()
        .accessibilityIdentifier("nutrition.foodHistorySheet")
    }
}

private struct FoodHistoryRow: View {
    let entry: FoodHistoryEntry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: entry.endDate == nil ? "checkmark.circle.fill" : "clock.arrow.circlepath")
                .foregroundStyle(entry.endDate == nil ? AppTheme.green : AppTheme.secondaryInk)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.endDate == nil ? "Plan actual" : "Plan anterior")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryInk)
                Text(entry.food.name)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(dateRange)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .accessibilityElement(children: .combine)
    }

    private var dateRange: String {
        if let endDate = entry.endDate {
            return "\(NutritionFormatting.shortDate(entry.startDate)) – \(NutritionFormatting.shortDate(endDate))"
        }
        return String(localized: "Desde \(NutritionFormatting.date(entry.startDate))")
    }
}
