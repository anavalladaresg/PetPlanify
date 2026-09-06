import SwiftUI

struct FeatureDestinationView: View {
    let section: AppSection
    var body: some View {
        switch section {
        case .home: HomeView()
        case .nutrition: NutritionView()
        case .health: HealthView()
        case .training: TrainingView()
        case .settings: SettingsView()
        }
    }
}
