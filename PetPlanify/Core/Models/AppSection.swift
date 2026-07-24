import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case home
    case nutrition
    case health
    case training
    case evolution
    case settings

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .home: "Inicio"
        case .nutrition: "Alimentación"
        case .health: "Salud"
        case .training: "Entrenamiento"
        case .evolution: "Evolución"
        case .settings: "Ajustes"
        }
    }

    var icon: String {
        switch self {
        case .home: "house"
        case .nutrition: "takeoutbag.and.cup.and.straw"
        case .health: "heart"
        case .training: "figure.walk"
        case .evolution: "chart.line.uptrend.xyaxis"
        case .settings: "gearshape"
        }
    }

    var explanation: LocalizedStringKey {
        switch self {
        case .home: "Todo lo importante sobre Neo, de un vistazo."
        case .nutrition: "Organiza sus comidas, cantidades y hábitos de alimentación."
        case .health: "Reúne el seguimiento de salud y las próximas visitas veterinarias."
        case .training: "Acompaña sus rutinas y celebra cada nuevo aprendizaje."
        case .evolution: "Observa cómo cambian su peso, actividad y bienestar."
        case .settings: "Personaliza PetPlanify y la información de Neo."
        }
    }
}
