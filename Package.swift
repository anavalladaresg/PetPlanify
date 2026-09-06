// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PetPlanifyCore",
    platforms: [.macOS("27.0")],
    products: [.library(name: "PetPlanifyCore", targets: ["PetPlanifyCore"])],
    targets: [
        .target(name: "PetPlanifyCore", path: "PetPlanify", exclude: ["App/FeatureDestinationView.swift", "App/MacAppShell.swift", "App/MobileAppShell.swift", "App/PetPlanifyApp.swift", "ContentView.swift", "Core/Components", "Core/Models/AppSection.swift", "Core/PreviewData", "Core/Theme", "Features/Home", "Features/Onboarding", "Features/Settings", "Resources", "Features/Health/HealthComponents.swift", "Features/Health/HealthDashboardView.swift", "Features/Health/HealthWeightChart.swift", "Features/Health/HealthMedicationEditor.swift", "Features/Health/HealthDetailSheets.swift", "Features/Health/HealthDocumentsView.swift", "Features/Health/HealthPreviewData.swift", "Features/Health/HealthView.swift", "Features/Health/HealthVisitEditors.swift", "Features/Nutrition/NutritionView.swift", "Features/Nutrition/NutritionEditors.swift", "Features/Training/TrainingDetailSheets.swift", "Features/Training/TrainingView.swift", "Features/Training/TrainingEditors.swift", "Features/Training/TrainingComponents.swift"], sources: [
            "App/PetPlanifyStore.swift", "Core/Notifications/LocalNotificationService.swift", "Core/Models/PetProfile.swift", "Core/Models/DailyCare.swift",
            "Core/Models/AppPreferences.swift", "Core/Models/PetPlanifySnapshot.swift",
            "Core/Persistence", "Core/Storage", "Core/Formatting", "Core/Notifications/ReminderEngine.swift",
            "Features/Nutrition/NutritionModels.swift", "Features/Health/HealthModels.swift",
            "Features/Training/TrainingModels.swift", "Features/Training/BuiltInTrickLibrary.swift"
        ]),
        .testTarget(name: "PetPlanifyCoreTests", dependencies: ["PetPlanifyCore"], path: "Tests/PetPlanifyCoreTests")
    ],
    swiftLanguageModes: [.v6]
)
