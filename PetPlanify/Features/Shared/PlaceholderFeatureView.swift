import SwiftUI

struct PlaceholderFeatureView: View {
    let section: AppSection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title)
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    Text(section.explanation)
                        .font(.title3)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 20) {
                    Image(systemName: section.icon)
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(AppTheme.green)
                        .frame(width: 72, height: 72)
                        .background(AppTheme.greenSoft, in: Circle())
                        .accessibilityHidden(true)

                    Text("Estamos preparando este espacio")
                        .font(.title3.weight(.semibold))
                    Text("Pronto podrás organizar esta parte del cuidado de Neo de una forma sencilla y tranquila.")
                        .foregroundStyle(AppTheme.secondaryInk)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 56)
                .padding(.horizontal, 24)
                .appSurface()
            }
            .frame(maxWidth: 980, alignment: .leading)
            .padding(32)
        }
        .appCanvas()
        .accessibilityIdentifier("feature.\(section.rawValue)")
    }
}

