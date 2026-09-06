import SwiftUI

@main
struct PetPlanifyApp: App {
    @State private var store = PetPlanifyStore.live()
    @State private var navigation = AppNavigation()
    var body: some Scene {
        WindowGroup {
            ContentView().environment(store).environment(navigation)
                .environment(\.locale, Locale(identifier: "es"))
        }
        #if os(macOS)
        .defaultSize(width: 1_050, height: 780)
        .windowResizability(.contentMinSize)
        #endif
    }
}
