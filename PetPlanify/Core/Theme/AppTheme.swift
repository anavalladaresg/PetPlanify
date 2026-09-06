import SwiftUI

/// Warm adaptive colors preserve contrast in both native appearances.
enum AppTheme {
    static let canvas = adaptive(light: (0.973, 0.966, 0.944), dark: (0.078, 0.102, 0.087))
    static let sidebar = adaptive(light: (0.94, 0.948, 0.92), dark: (0.105, 0.14, 0.113))
    static let surface = adaptive(light: (0.995, 0.989, 0.974), dark: (0.123, 0.155, 0.132))
    static let surfaceMuted = adaptive(light: (0.943, 0.947, 0.913), dark: (0.172, 0.21, 0.175))
    static let ink = adaptive(light: (0.18, 0.15, 0.12), dark: (0.94, 0.92, 0.86))
    static let secondaryInk = adaptive(light: (0.42, 0.38, 0.33), dark: (0.72, 0.74, 0.67))
    static let green = adaptive(light: (0.30, 0.42, 0.24), dark: (0.64, 0.77, 0.52))
    static let greenSoft = adaptive(light: (0.85, 0.89, 0.80), dark: (0.23, 0.30, 0.20))
    static let orange = adaptive(light: (0.70, 0.34, 0.11), dark: (0.96, 0.65, 0.36))
    static let border = adaptive(light: (0.85, 0.844, 0.80), dark: (0.28, 0.33, 0.28))
    static let orangeSoft = adaptive(light: (0.982, 0.948, 0.89), dark: (0.225, 0.185, 0.125))
    static let peachSoft = adaptive(light: (0.985, 0.925, 0.86), dark: (0.25, 0.17, 0.13))
    static let sageSurface = adaptive(light: (0.89, 0.93, 0.85), dark: (0.16, 0.24, 0.18))
    static let trainingSoft = adaptive(light: (0.91, 0.94, 0.78), dark: (0.19, 0.27, 0.14))
    static let lavenderSoft = adaptive(light: (0.90, 0.89, 0.94), dark: (0.18, 0.18, 0.25))
    static let shadow = adaptive(light: (0.28, 0.24, 0.16), dark: (0.02, 0.025, 0.02))
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
        background(AppTheme.canvas.ignoresSafeArea()).foregroundStyle(AppTheme.ink).tint(AppTheme.green)
    }
    func appSurface(cornerRadius: CGFloat = AppTheme.cornerRadius, elevated: Bool = false) -> some View {
        background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(AppTheme.surface)
            .shadow(color: AppTheme.shadow.opacity(elevated ? 0.10 : 0.035), radius: elevated ? 14 : 5, x: 0, y: elevated ? 6 : 2))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(AppTheme.border, lineWidth: 0.75))
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.surface.opacity(0.9), lineWidth: 0.7)
                    .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
            }
    }
}
