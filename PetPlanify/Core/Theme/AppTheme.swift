import SwiftUI

/// Warm adaptive colors preserve contrast in both native appearances.
enum AppTheme {
    static let canvas = adaptive(light: (0.97, 0.95, 0.91), dark: (0.10, 0.115, 0.10))
    static let sidebar = adaptive(light: (0.94, 0.91, 0.85), dark: (0.12, 0.14, 0.12))
    static let surface = adaptive(light: (0.99, 0.98, 0.96), dark: (0.155, 0.17, 0.15))
    static let surfaceMuted = adaptive(light: (0.95, 0.92, 0.87), dark: (0.20, 0.22, 0.19))
    static let ink = adaptive(light: (0.18, 0.15, 0.12), dark: (0.94, 0.92, 0.86))
    static let secondaryInk = adaptive(light: (0.42, 0.38, 0.33), dark: (0.72, 0.74, 0.67))
    static let green = adaptive(light: (0.30, 0.42, 0.24), dark: (0.64, 0.77, 0.52))
    static let greenSoft = adaptive(light: (0.85, 0.89, 0.80), dark: (0.23, 0.30, 0.20))
    static let orange = adaptive(light: (0.70, 0.34, 0.11), dark: (0.96, 0.65, 0.36))
    static let border = adaptive(light: (0.83, 0.79, 0.72), dark: (0.31, 0.35, 0.29))
    static let cornerRadius: CGFloat = 18

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
    func appSurface(cornerRadius: CGFloat = AppTheme.cornerRadius) -> some View {
        background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(AppTheme.surface))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(AppTheme.border, lineWidth: 0.75))
    }
}
