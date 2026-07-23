import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 38))
                .foregroundStyle(.green)
            Text("PetPlanify")
                .font(.largeTitle.weight(.semibold))
            Text("El bienestar de Neo, en un solo lugar.")
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}

#Preview {
    ContentView()
}
