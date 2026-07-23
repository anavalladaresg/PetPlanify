import SwiftUI

struct NeoProfileCard: View {
    let pet: PetProfile

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.greenSoft, AppTheme.surfaceMuted],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(spacing: 12) {
                    PetAvatarView(size: 94)
                    Image(systemName: "pawprint.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.orange)
                }
            }
            .frame(height: 170)
            .accessibilityLabel("Imagen de perfil de Neo")

            VStack(spacing: 4) {
                Text(pet.name)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                Text("\(pet.breed) · \(pet.age)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .appSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Neo, teckel, 3 años")
        .accessibilityIdentifier("home.neoProfile")
    }
}

