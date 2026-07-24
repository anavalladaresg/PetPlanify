import SwiftUI

struct FeatureDestinationView: View {
    let section: AppSection

    @ViewBuilder
    var body: some View {
        switch section {
        case .home:
            HomeView(pet: PreviewData.neo)
        case .nutrition:
            NutritionView()
        case .health:
            HealthView()
        case .training:
            TrainingView()
        case .settings:
            SettingsView()
        }
    }
}
