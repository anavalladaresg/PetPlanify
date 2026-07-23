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
        case .gallery:
            GalleryView()
        case .evolution:
            EvolutionView()
        case .reminders:
            RemindersView()
        case .notes:
            NotesView()
        case .settings:
            SettingsView()
        }
    }
}
