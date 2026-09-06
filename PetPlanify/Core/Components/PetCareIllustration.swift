import SwiftUI

/// Small, static dimensional motifs used to give intentional empty states a visual anchor.
/// They are drawn in-app so the app stays lightweight and remains crisp at any scale.
struct PetCareIllustration: View {
    enum Kind { case bowl, scale, calendar, clicker, medicine }

    let kind: Kind
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 120, size.height / 92)
            context.translateBy(x: (size.width - 120 * scale) / 2, y: (size.height - 92 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            let shadow = Path(ellipseIn: CGRect(x: 18, y: 72, width: 84, height: 11))
            context.fill(shadow, with: .color(AppTheme.shadow.opacity(colorScheme == .dark ? 0.28 : 0.12)))
            draw(in: &context)
        }
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext) {
        switch kind {
        case .bowl:
            let body = Path { p in
                p.move(to: CGPoint(x: 24, y: 40)); p.addCurve(to: CGPoint(x: 96, y: 40), control1: CGPoint(x: 77, y: 52), control2: CGPoint(x: 43, y: 52)); p.addLine(to: CGPoint(x: 88, y: 67)); p.addCurve(to: CGPoint(x: 32, y: 67), control1: CGPoint(x: 77, y: 82), control2: CGPoint(x: 43, y: 82)); p.closeSubpath()
            }
            context.fill(body, with: .color(AppTheme.orange))
            context.stroke(body, with: .color(AppTheme.ink.opacity(0.18)), lineWidth: 1)
            context.fill(Path(ellipseIn: CGRect(x: 25, y: 32, width: 70, height: 20)), with: .color(AppTheme.peachSoft))
            context.fill(Path(ellipseIn: CGRect(x: 39, y: 35, width: 42, height: 10)), with: .color(AppTheme.ink.opacity(0.16)))
        case .scale:
            let base = RoundedRectangle(cornerRadius: 13).path(in: CGRect(x: 25, y: 37, width: 70, height: 34))
            context.fill(base, with: .color(AppTheme.sageSurface))
            context.stroke(base, with: .color(AppTheme.green.opacity(0.5)), lineWidth: 1)
            context.fill(Path(ellipseIn: CGRect(x: 40, y: 26, width: 40, height: 22)), with: .color(AppTheme.surface))
            context.stroke(Path(ellipseIn: CGRect(x: 40, y: 26, width: 40, height: 22)), with: .color(AppTheme.green), lineWidth: 2)
            context.stroke(Path { p in p.move(to: CGPoint(x: 60, y: 37)); p.addLine(to: CGPoint(x: 69, y: 31)) }, with: .color(AppTheme.orange), lineWidth: 2)
        case .calendar:
            let page = RoundedRectangle(cornerRadius: 12).path(in: CGRect(x: 29, y: 21, width: 62, height: 54))
            context.fill(page, with: .color(AppTheme.orangeSoft))
            context.stroke(page, with: .color(AppTheme.orange.opacity(0.55)), lineWidth: 1)
            context.fill(Path(CGRect(x: 29, y: 21, width: 62, height: 17)), with: .color(AppTheme.orange.opacity(0.78)))
            for x in [43, 60, 77] { context.fill(Path(ellipseIn: CGRect(x: CGFloat(x), y: 48, width: 6, height: 6)), with: .color(AppTheme.green)) }
            for x in [43, 60, 77] { context.fill(Path(ellipseIn: CGRect(x: CGFloat(x), y: 61, width: 6, height: 6)), with: .color(AppTheme.greenSoft)) }
        case .clicker:
            let ball = Path(ellipseIn: CGRect(x: 31, y: 25, width: 45, height: 45))
            context.fill(ball, with: .color(AppTheme.trainingSoft))
            context.stroke(ball, with: .color(AppTheme.green), lineWidth: 1)
            context.fill(Path(ellipseIn: CGRect(x: 76, y: 39, width: 18, height: 18)), with: .color(AppTheme.orange))
            context.stroke(Path { p in p.move(to: CGPoint(x: 70, y: 48)); p.addLine(to: CGPoint(x: 84, y: 48)) }, with: .color(AppTheme.ink.opacity(0.45)), lineWidth: 3)
        case .medicine:
            let casePath = RoundedRectangle(cornerRadius: 12).path(in: CGRect(x: 25, y: 30, width: 70, height: 44))
            context.fill(casePath, with: .color(AppTheme.sageSurface))
            context.stroke(casePath, with: .color(AppTheme.green.opacity(0.55)), lineWidth: 1)
            context.fill(Path(roundedRect: CGRect(x: 46, y: 21, width: 28, height: 16), cornerRadius: 6), with: .color(AppTheme.green))
            context.fill(Path(CGRect(x: 56, y: 40, width: 8, height: 24)), with: .color(AppTheme.orange))
            context.fill(Path(CGRect(x: 48, y: 48, width: 24, height: 8)), with: .color(AppTheme.orange))
        }
    }
}
