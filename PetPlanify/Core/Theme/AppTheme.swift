import SwiftUI

/// Shared visual language for PetPlanify.
///
/// The palette intentionally uses warm, tinted neutrals instead of white/grey
/// surfaces. Semantic accents are kept here so every feature speaks the same
/// visual language on macOS and iPhone.
enum AppTheme {
    static let canvas = adaptive(light: (0.965, 0.953, 0.933), dark: (0.063, 0.165, 0.169)) // #F6F3EE / #102A2B
    static let sidebar = adaptive(light: (0.933, 0.918, 0.890), dark: (0.071, 0.180, 0.180))
    static let surface = adaptive(light: (1.0, 0.992, 0.988), dark: (0.094, 0.224, 0.227)) // #FFFDFC / #18393A
    static let surfaceMuted = adaptive(light: (0.855, 0.845, 0.825), dark: (0.14, 0.205, 0.21))
    static let surfaceElevated = adaptive(light: (0.988, 0.980, 0.965), dark: (0.129, 0.282, 0.286)) // #214849
    static let ink = adaptive(light: (0.141, 0.196, 0.224), dark: (0.949, 0.961, 0.949)) // #243239 / #F2F5F2
    static let secondaryInk = adaptive(light: (0.380, 0.439, 0.431), dark: (0.706, 0.769, 0.749)) // #61706E / #B4C4BF
    static let green = adaptive(light: (0.471, 0.663, 0.592), dark: (0.50, 0.78, 0.69)) // #78A997
    static let mint = adaptive(light: (0.335, 0.690, 0.625), dark: (0.42, 0.84, 0.75))
    static let greenSoft = adaptive(light: (0.76, 0.86, 0.79), dark: (0.13, 0.28, 0.24))
    static let orange = adaptive(light: (0.788, 0.435, 0.329), dark: (0.89, 0.52, 0.40)) // #C96F54
    static let blue = adaptive(light: (0.451, 0.545, 0.776), dark: (0.55, 0.68, 0.94)) // #738BC6
    static let health = adaptive(light: (0.788, 0.361, 0.361), dark: (0.96, 0.49, 0.48)) // #C95C5C
    static let reminder = adaptive(light: (0.851, 0.604, 0.259), dark: (0.96, 0.70, 0.35)) // #D99A42
    static let training = adaptive(light: (0.608, 0.525, 0.749), dark: (0.73, 0.64, 0.91)) // #9B86BF
    // Health calendar categories deliberately use five distinct hues. They are
    // separate from the broader app accents so a day with several records can
    // be scanned without relying on its label alone.
    static let vaccine = adaptive(light: (0.13, 0.48, 0.31), dark: (0.35, 0.84, 0.54)) // emerald
    static let deworming = adaptive(light: (0.93, 0.55, 0.08), dark: (1.0, 0.72, 0.22)) // golden orange
    static let medication = adaptive(light: (0.498, 0.407, 0.714), dark: (0.67, 0.57, 0.91)) // lavender
    static let visit = adaptive(light: (0.68, 0.16, 0.25), dark: (1.0, 0.38, 0.48)) // coral-red
    static let weight = adaptive(light: (0.05, 0.40, 0.63), dark: (0.26, 0.72, 0.92)) // blue-teal
    static let border = adaptive(light: (0.73, 0.71, 0.68), dark: (0.24, 0.34, 0.34))
    static let orangeSoft = adaptive(light: (0.961, 0.780, 0.710), dark: (0.31, 0.19, 0.16)) // #F5C7B5
    static let peachSoft = adaptive(light: (0.94, 0.82, 0.80), dark: (0.28, 0.18, 0.20))
    static let sageSurface = adaptive(light: (0.78, 0.87, 0.80), dark: (0.13, 0.25, 0.22))
    static let trainingSoft = adaptive(light: (0.84, 0.80, 0.92), dark: (0.22, 0.18, 0.32))
    static let lavenderSoft = adaptive(light: (0.84, 0.80, 0.92), dark: (0.22, 0.18, 0.32))
    static let shadow = adaptive(light: (0.34, 0.32, 0.29), dark: (0.015, 0.035, 0.04))
    static let highlight = adaptive(light: (1.0, 0.99, 0.96), dark: (0.22, 0.34, 0.34))
    static let actionSurface = adaptive(light: (0.961, 0.780, 0.710), dark: (0.35, 0.21, 0.16))
    static let scoreSurface = adaptive(light: (0.73, 0.84, 0.76), dark: (0.12, 0.27, 0.23))
    static let heroSurface = adaptive(light: (0.76, 0.85, 0.78), dark: (0.11, 0.25, 0.24))
    static let quickSurface = adaptive(light: (0.95, 0.93, 0.89), dark: (0.14, 0.20, 0.22))
    static let cornerRadius: CGFloat = 20
    static let compactRadius: CGFloat = 16
    static let heroRadius: CGFloat = 28

    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let section: CGFloat = 32
    }

    private static func adaptive(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        #if os(macOS)
        Color(nsColor: NSColor(name: nil) { appearance in
            let darkMode = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let values = darkMode ? dark : light
            return NSColor(srgbRed: values.0, green: values.1, blue: values.2, alpha: 1)
        })
        #else
        Color(uiColor: UIColor { traits in
            let values = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: values.0, green: values.1, blue: values.2, alpha: 1)
        })
        #endif
    }
}

extension View {
    func appCanvas() -> some View {
        background(AppTheme.canvas.ignoresSafeArea())
        .foregroundStyle(AppTheme.ink)
        .tint(AppTheme.green)
    }
    func appSurface(cornerRadius: CGFloat = AppTheme.cornerRadius, elevated: Bool = false) -> some View {
        modifier(NeumorphicModifier(cornerRadius: cornerRadius, elevated: elevated))
    }
}

private struct NeumorphicModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let cornerRadius: CGFloat
    let elevated: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(shape.fill(elevated ? AppTheme.surfaceElevated : AppTheme.surface))
            .overlay(shape.stroke(AppTheme.border.opacity(reduceTransparency ? 0.9 : 0.52), lineWidth: reduceTransparency ? 1 : 0.7))
            .shadow(color: AppTheme.highlight.opacity(reduceTransparency ? 0 : 0.50), radius: elevated ? 13 : 8, x: -4, y: -4)
            .shadow(color: AppTheme.shadow.opacity(elevated ? 0.25 : 0.16), radius: elevated ? 14 : 8, x: 5, y: 6)
    }
}
