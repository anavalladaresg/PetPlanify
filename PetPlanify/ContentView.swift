import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        MacAppShell()
        #else
        MobileAppShell()
        #endif
    }
}

#Preview {
    ContentView()
        .frame(width: 1_180, height: 780)
}
