import SwiftUI

enum AppTheme {
    static let canvas = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let sidebar = Color(red: 0.94, green: 0.91, blue: 0.85)
    static let surface = Color(red: 0.99, green: 0.98, blue: 0.96)
    static let surfaceMuted = Color(red: 0.95, green: 0.92, blue: 0.87)
    static let ink = Color(red: 0.18, green: 0.15, blue: 0.12)
    static let secondaryInk = Color(red: 0.42, green: 0.38, blue: 0.33)
    static let green = Color(red: 0.33, green: 0.45, blue: 0.27)
    static let greenSoft = Color(red: 0.85, green: 0.89, blue: 0.80)
    static let orange = Color(red: 0.82, green: 0.43, blue: 0.17)
    static let border = Color(red: 0.80, green: 0.75, blue: 0.67).opacity(0.45)
    static let cornerRadius: CGFloat = 18
}

extension View {
    func appCanvas() -> some View {
        background(AppTheme.canvas.ignoresSafeArea())
            .foregroundStyle(AppTheme.ink)
            .tint(AppTheme.green)
    }

    func appSurface(cornerRadius: CGFloat = AppTheme.cornerRadius) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppTheme.surface)
                .shadow(color: AppTheme.ink.opacity(0.055), radius: 12, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 0.75)
        )
    }
}

