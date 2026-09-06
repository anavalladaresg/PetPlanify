import SwiftUI
import Observation

enum AppSection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case home, nutrition, health, training, settings
    var id: Self { self }
    var title: LocalizedStringKey {
        switch self {
        case .home: "Inicio"
        case .nutrition: "Alimentación"
        case .health: "Salud"
        case .training: "Entrenamiento"
        case .settings: "Ajustes"
        }
    }
    var icon: String {
        switch self {
        case .home: "house.fill"
        case .nutrition: "fork.knife"
        case .health: "heart.fill"
        case .training: "pawprint.fill"
        case .settings: "gearshape.fill"
        }
    }
    init(context: ObservationContext) {
        switch context {
        case .general: self = .home
        case .nutrition: self = .nutrition
        case .health: self = .health
        case .training: self = .training
        }
    }
}

@MainActor @Observable final class AppNavigation {
    var selection: AppSection = .home
}
