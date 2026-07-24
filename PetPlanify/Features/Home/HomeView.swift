import SwiftUI

struct HomeView: View {
    enum QuickAction: String, Identifiable {
        case meal, weight, observation, session
        var id: String { rawValue }

        var title: String {
            switch self {
            case .meal: "Registrar comida"
            case .weight: "Registrar peso"
            case .observation: "Añadir observación"
            case .session: "Registrar sesión"
            }
        }

        var symbol: String {
            switch self {
            case .meal: "fork.knife"
            case .weight: "scalemass"
            case .observation: "square.and.pencil"
            case .session: "stopwatch"
            }
        }
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var presentedAction: QuickAction?

    let pet: PetProfile

    private var isCompact: Bool { horizontalSizeClass == .compact }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isCompact ? 18 : 22) {
                header
                identity
                dailySummary
                quickActions
                upcoming
            }
            .frame(maxWidth: 1_080, alignment: .leading)
            .padding(isCompact ? 18 : 28)
        }
        .appCanvas()
        .accessibilityIdentifier("home.screen")
        .sheet(item: $presentedAction) { action in
            HomeFutureActionSheet(action: action) {
                presentedAction = nil
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("¡Buenos días!")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
            Text("¿Qué necesita Neo hoy?")
                .font(.title3)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.greeting")
    }

    private var identity: some View {
        HStack(spacing: 13) {
            PetAvatarView(size: isCompact ? 48 : 54)
            VStack(alignment: .leading, spacing: 3) {
                Text("Neo")
                    .font(.title3.weight(.semibold))
                Text("\(pet.breed) · \(pet.age)")
                    .foregroundStyle(AppTheme.secondaryInk)
            }
            Spacer()
            Text(pet.currentWeight)
                .font(.title3.weight(.semibold))
                .accessibilityLabel("Peso actual, \(pet.currentWeight)")
        }
        .padding(15)
        .appSurface(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }

    private var dailySummary: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: isCompact ? 145 : 210), spacing: 12)],
            spacing: 12
        ) {
            SummaryCard(title: "Próxima comida", value: "\(pet.nextMealTime) · Cena", symbol: "fork.knife", identifier: "home.nextMeal")
            SummaryCard(title: "Actividad hoy", value: pet.activityToday, symbol: "figure.walk", identifier: "home.activity")
            SummaryCard(title: "Peso actual", value: pet.currentWeight, symbol: "scalemass", identifier: "home.currentWeight")
            SummaryCard(title: "Próxima atención", value: "Hoy · 10:30", symbol: "cross.case", identifier: "home.nextCare")
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Acciones rápidas")
                .font(.system(.title3, design: .serif, weight: .semibold))
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: isCompact ? 145 : 190), spacing: 10)],
                spacing: 10
            ) {
                ForEach([QuickAction.meal, .weight, .observation, .session]) { action in
                    Button {
                        presentedAction = action
                    } label: {
                        Label(action.title, systemImage: action.symbol)
                            .frame(maxWidth: .infinity, minHeight: 42)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier(action == .observation ? "home.addObservation" : "home.action.\(action.rawValue)")
                }
            }
        }
        .accessibilityIdentifier("home.quickActions")
    }

    private var upcoming: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Próximamente")
                .font(.system(.title3, design: .serif, weight: .semibold))
            VStack(spacing: 0) {
                upcomingRow("Revisión veterinaria anual", detail: "Hoy, 10:30", symbol: "cross.case")
                Divider().overlay(AppTheme.border)
                upcomingRow("Comprar comida", detail: "18 de junio, 19:00", symbol: "takeoutbag.and.cup.and.straw")
                Divider().overlay(AppTheme.border)
                upcomingRow("Practicar «quieto»", detail: "20 de junio, 18:00", symbol: "figure.walk")
            }
            .padding(.horizontal, 15)
            .appSurface(cornerRadius: 16)
        }
        .accessibilityIdentifier("home.upcoming")
    }

    private func upcomingRow(_ title: String, detail: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(AppTheme.green)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(AppTheme.secondaryInk)
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

private struct HomeFutureActionSheet: View {
    let action: HomeView.QuickAction
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: action.symbol)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(AppTheme.green)
                .accessibilityHidden(true)
            Text(action.title)
                .font(.system(.title2, design: .serif, weight: .semibold))
            Text("Esta acción estará disponible cuando se añada el almacenamiento de PetPlanify.")
                .foregroundStyle(AppTheme.secondaryInk)
                .multilineTextAlignment(.center)
            Button("Cerrar", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.green)
        }
        .frame(maxWidth: 400)
        .padding(30)
        .appCanvas()
    }
}

#Preview("Inicio") {
    HomeView(pet: PreviewData.neo)
        .frame(width: 1_000, height: 760)
}
