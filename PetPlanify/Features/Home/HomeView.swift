import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let pet: PetProfile

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isCompact ? 22 : 30) {
                header
                overview

                VStack(alignment: .leading, spacing: 14) {
                    Text("Resumen rápido")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                    quickSummary
                }

                WeightTrendCard(entries: pet.weightHistory)
            }
            .frame(maxWidth: 1_180, alignment: .leading)
            .padding(isCompact ? 18 : 32)
        }
        .appCanvas()
        .accessibilityIdentifier("home.dashboard")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 9) {
                Text("¡Buenos días!")
                    .font(.system(isCompact ? .largeTitle : .largeTitle, design: .serif, weight: .semibold))
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(AppTheme.orange)
                    .accessibilityHidden(true)
            }
            Text("Así va el día de Neo")
                .font(.title3)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.greeting")
    }

    @ViewBuilder
    private var overview: some View {
        if isCompact {
            VStack(spacing: 14) {
                NeoProfileCard(pet: pet)
                metricGrid
            }
        } else {
            HStack(alignment: .top, spacing: 18) {
                NeoProfileCard(pet: pet)
                    .frame(width: 260)
                metricGrid
            }
        }
    }

    private var metricGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: isCompact ? 145 : 195), spacing: 14)],
            spacing: 14
        ) {
            DashboardCard(
                title: "Peso actual",
                value: pet.currentWeight,
                detail: "Rango saludable: 6,5–7,5 kg",
                symbol: "scalemass",
                identifier: "home.currentWeight"
            )
            DashboardCard(
                title: "Próxima comida",
                value: pet.nextMealTime,
                detail: "Cena",
                symbol: "fork.knife",
                accent: AppTheme.orange,
                identifier: "home.nextMeal"
            )
            DashboardCard(
                title: "Última comida",
                value: pet.lastMealTime,
                detail: "Desayuno completado",
                symbol: "checkmark.circle",
                identifier: "home.lastMeal"
            )
            DashboardCard(
                title: "Actividad hoy",
                value: pet.activityToday,
                detail: "Paseo y juego",
                symbol: "figure.walk",
                identifier: "home.activity"
            )
            DashboardCard(
                title: "Próxima cita veterinaria",
                value: pet.nextVeterinaryAppointment,
                detail: "Revisión general",
                symbol: "cross.case",
                accent: AppTheme.orange,
                identifier: "home.veterinaryAppointment"
            )
        }
    }

    private var quickSummary: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: isCompact ? 145 : 200), spacing: 14)],
            spacing: 14
        ) {
            SummaryCard(
                title: "Pasos hoy",
                value: pet.stepsToday,
                symbol: "shoeprints.fill",
                identifier: "home.steps"
            )
            SummaryCard(
                title: "Descanso",
                value: pet.restToday,
                symbol: "moon.zzz",
                identifier: "home.rest"
            )
            SummaryCard(
                title: "Hidratación",
                value: pet.hydration,
                symbol: "drop.fill",
                identifier: "home.hydration"
            )
            SummaryCard(
                title: "Estado de ánimo",
                value: pet.mood,
                symbol: "face.smiling",
                identifier: "home.mood"
            )
        }
    }
}

#Preview("Inicio") {
    HomeView(pet: PreviewData.neo)
        .frame(width: 1_000, height: 780)
}

