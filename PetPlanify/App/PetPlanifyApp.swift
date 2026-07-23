import SwiftUI

@main
struct PetPlanifyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1_180, height: 780)
        .windowResizability(.contentMinSize)
        #endif
    }
}

