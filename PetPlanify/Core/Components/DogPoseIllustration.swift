import SwiftUI

/// Original vector artwork. A static canvas keeps these small illustrations inexpensive in lists.
struct DogPoseIllustration: View {
    enum Pose {
        case sitting, lying, standing, offeringPaw, coming
    }

    let pose: Pose
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 240, size.height / 168)
            context.translateBy(x: (size.width - 240 * scale) / 2, y: (size.height - 168 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            draw(in: &context)
        }
        .accessibilityHidden(true)
    }

    private var coatLight: Color { Color(red: 0.77, green: 0.49, blue: 0.28) }
    private var coat: Color { Color(red: 0.59, green: 0.31, blue: 0.16) }
    private var coatShade: Color { Color(red: 0.38, green: 0.19, blue: 0.12) }
    private var muzzle: Color { Color(red: 0.85, green: 0.62, blue: 0.40) }
    private var nose: Color { Color(red: 0.20, green: 0.15, blue: 0.12) }

    private func draw(in context: inout GraphicsContext) {
        // Tonal ground and a precise contact shadow provide depth without blur or a 3D renderer.
        context.fill(Path(ellipseIn: CGRect(x: 24, y: 122, width: 191, height: 29)), with: .color(AppTheme.greenSoft.opacity(0.6)))
        context.fill(Path(ellipseIn: CGRect(x: 53, y: 132, width: 145, height: 10)), with: .color(AppTheme.green.opacity(colorScheme == .dark ? 0.16 : 0.09)))

        switch pose {
        case .sitting, .offeringPaw:
            drawSeated(in: &context, offersPaw: pose == .offeringPaw)
        case .lying:
            drawLying(in: &context)
        case .standing, .coming:
            drawStanding(in: &context, walking: pose == .coming)
        }
    }

    private func drawSeated(in context: inout GraphicsContext, offersPaw: Bool) {
        // Tail curls behind the haunch; short legs and a long chest retain the dachshund silhouette.
        stroke(path { p in
            p.move(to: CGPoint(x: 98, y: 128))
            p.addCurve(to: CGPoint(x: 54, y: 112), control1: CGPoint(x: 70, y: 140), control2: CGPoint(x: 52, y: 138))
        }, color: coatShade, width: 8, in: &context)
        fill(path { p in
            p.move(to: CGPoint(x: 119, y: 64))
            p.addCurve(to: CGPoint(x: 90, y: 104), control1: CGPoint(x: 101, y: 68), control2: CGPoint(x: 97, y: 93))
            p.addCurve(to: CGPoint(x: 91, y: 137), control1: CGPoint(x: 72, y: 105), control2: CGPoint(x: 75, y: 135))
            p.addLine(to: CGPoint(x: 142, y: 137))
            p.addCurve(to: CGPoint(x: 145, y: 79), control1: CGPoint(x: 151, y: 119), control2: CGPoint(x: 145, y: 96))
            p.closeSubpath()
        }, from: coatLight, to: coat, in: &context)
        fill(Path(ellipseIn: CGRect(x: 85, y: 107, width: 33, height: 31)), from: coat, to: coatShade, in: &context)
        roundedRect(CGRect(x: 101, y: 130, width: 31, height: 9), radius: 4, color: coatLight, in: &context)
        // Far front leg, followed by the brighter near leg.
        stroke(path { p in p.move(to: CGPoint(x: 133, y: 97)); p.addLine(to: CGPoint(x: 137, y: 132)); p.addLine(to: CGPoint(x: 148, y: 134)) }, color: coatShade, width: 9, in: &context)
        if offersPaw {
            stroke(path { p in
                p.move(to: CGPoint(x: 142, y: 92))
                p.addQuadCurve(to: CGPoint(x: 157, y: 107), control: CGPoint(x: 140, y: 115))
                p.addLine(to: CGPoint(x: 184, y: 95))
            }, color: coatLight, width: 10, in: &context)
            roundedRect(CGRect(x: 179, y: 90, width: 15, height: 10), radius: 5, color: muzzle, in: &context)
        } else {
            stroke(path { p in p.move(to: CGPoint(x: 143, y: 97)); p.addLine(to: CGPoint(x: 148, y: 133)); p.addLine(to: CGPoint(x: 160, y: 135)) }, color: coatLight, width: 10, in: &context)
        }
        drawHead(at: CGPoint(x: 134, y: 57), angle: offersPaw ? -0.07 : -0.13, in: &context)
    }

    private func drawStanding(in context: inout GraphicsContext, walking: Bool) {
        let lift: CGFloat = walking ? -5 : 0
        stroke(path { p in
            p.move(to: CGPoint(x: 61, y: 101 + lift))
            p.addCurve(to: CGPoint(x: 29, y: walking ? 72 : 86), control1: CGPoint(x: 35, y: 108 + lift), control2: CGPoint(x: 29, y: 91))
        }, color: coatShade, width: 7, in: &context)
        // Far legs are slightly darker and offset behind the body.
        stroke(path { p in p.move(to: CGPoint(x: 81, y: 112)); p.addLine(to: CGPoint(x: walking ? 94 : 85, y: 134)); p.addLine(to: CGPoint(x: walking ? 104 : 94, y: 135)) }, color: coatShade, width: 9, in: &context)
        stroke(path { p in p.move(to: CGPoint(x: 153, y: 112)); p.addLine(to: CGPoint(x: walking ? 143 : 155, y: 135)); p.addLine(to: CGPoint(x: walking ? 152 : 165, y: 136)) }, color: coatShade, width: 9, in: &context)
        fill(path { p in
            p.move(to: CGPoint(x: 65, y: 91 + lift))
            p.addCurve(to: CGPoint(x: 137, y: 87 + lift), control1: CGPoint(x: 88, y: 85 + lift), control2: CGPoint(x: 119, y: 94 + lift))
            p.addQuadCurve(to: CGPoint(x: 151, y: 64 + lift), control: CGPoint(x: 148, y: 85 + lift))
            p.addLine(to: CGPoint(x: 169, y: 72 + lift))
            p.addCurve(to: CGPoint(x: 159, y: 119 + lift), control1: CGPoint(x: 169, y: 87 + lift), control2: CGPoint(x: 174, y: 107 + lift))
            p.addCurve(to: CGPoint(x: 70, y: 122 + lift), control1: CGPoint(x: 137, y: 127 + lift), control2: CGPoint(x: 93, y: 122 + lift))
            p.addCurve(to: CGPoint(x: 65, y: 91 + lift), control1: CGPoint(x: 49, y: 120 + lift), control2: CGPoint(x: 47, y: 97 + lift))
            p.closeSubpath()
        }, from: coatLight, to: coat, in: &context)
        stroke(path { p in p.move(to: CGPoint(x: 69, y: 115 + lift)); p.addLine(to: CGPoint(x: walking ? 53 : 69, y: 134)); p.addLine(to: CGPoint(x: walking ? 64 : 81, y: 136)) }, color: coat, width: 10, in: &context)
        stroke(path { p in p.move(to: CGPoint(x: 163, y: 110 + lift)); p.addLine(to: CGPoint(x: walking ? 180 : 166, y: walking ? 124 : 134)); p.addLine(to: CGPoint(x: walking ? 191 : 178, y: walking ? 124 : 136)) }, color: coatLight, width: 10, in: &context)
        drawHead(at: CGPoint(x: 160, y: 63 + lift), angle: walking ? -0.03 : -0.12, in: &context)
        if walking {
            stroke(path { p in p.move(to: CGPoint(x: 30, y: 118)); p.addLine(to: CGPoint(x: 39, y: 118)) }, color: AppTheme.green.opacity(0.4), width: 2, in: &context)
            stroke(path { p in p.move(to: CGPoint(x: 24, y: 125)); p.addLine(to: CGPoint(x: 35, y: 125)) }, color: AppTheme.green.opacity(0.25), width: 2, in: &context)
        } else {
            // A subtle resting boundary distinguishes the steady, planted pose.
            stroke(path { p in p.move(to: CGPoint(x: 194, y: 111)); p.addLine(to: CGPoint(x: 194, y: 135)) }, color: AppTheme.green.opacity(0.35), width: 2, in: &context)
        }
    }

    private func drawLying(in context: inout GraphicsContext) {
        stroke(path { p in p.move(to: CGPoint(x: 66, y: 127)); p.addQuadCurve(to: CGPoint(x: 29, y: 112), control: CGPoint(x: 30, y: 134)) }, color: coatShade, width: 7, in: &context)
        roundedRect(CGRect(x: 149, y: 128, width: 51, height: 9), radius: 5, color: coatShade, in: &context)
        fill(path { p in
            p.move(to: CGPoint(x: 61, y: 108))
            p.addCurve(to: CGPoint(x: 139, y: 108), control1: CGPoint(x: 85, y: 100), control2: CGPoint(x: 121, y: 113))
            p.addQuadCurve(to: CGPoint(x: 153, y: 91), control: CGPoint(x: 146, y: 104))
            p.addLine(to: CGPoint(x: 175, y: 102))
            p.addQuadCurve(to: CGPoint(x: 165, y: 132), control: CGPoint(x: 181, y: 123))
            p.addCurve(to: CGPoint(x: 61, y: 135), control1: CGPoint(x: 132, y: 139), control2: CGPoint(x: 85, y: 138))
            p.addCurve(to: CGPoint(x: 61, y: 108), control1: CGPoint(x: 40, y: 136), control2: CGPoint(x: 40, y: 114))
            p.closeSubpath()
        }, from: coatLight, to: coat, in: &context)
        fill(Path(ellipseIn: CGRect(x: 54, y: 117, width: 34, height: 22)), from: coat, to: coatShade, in: &context)
        roundedRect(CGRect(x: 72, y: 130, width: 35, height: 9), radius: 5, color: coatLight, in: &context)
        roundedRect(CGRect(x: 152, y: 133, width: 54, height: 9), radius: 5, color: coatLight, in: &context)
        drawHead(at: CGPoint(x: 163, y: 88), angle: 0.08, in: &context)
    }

    private func drawHead(at point: CGPoint, angle: Double, in context: inout GraphicsContext) {
        var head = context
        head.translateBy(x: point.x, y: point.y)
        head.rotate(by: .radians(angle))
        roundedRect(CGRect(x: -13, y: 16, width: 29, height: 7), radius: 3, color: AppTheme.green, in: &head)
        fill(path { p in
            p.move(to: CGPoint(x: -17, y: -11))
            p.addCurve(to: CGPoint(x: 17, y: -15), control1: CGPoint(x: -12, y: -29), control2: CGPoint(x: 13, y: -28))
            p.addQuadCurve(to: CGPoint(x: 28, y: -4), control: CGPoint(x: 20, y: -6))
            p.addLine(to: CGPoint(x: 45, y: 0))
            p.addQuadCurve(to: CGPoint(x: 41, y: 13), control: CGPoint(x: 49, y: 10))
            p.addCurve(to: CGPoint(x: -10, y: 19), control1: CGPoint(x: 23, y: 23), control2: CGPoint(x: 0, y: 26))
            p.addQuadCurve(to: CGPoint(x: -17, y: -11), control: CGPoint(x: -22, y: 7))
            p.closeSubpath()
        }, from: coatLight, to: coat, in: &head)
        fill(path { p in
            p.move(to: CGPoint(x: 16, y: 4))
            p.addQuadCurve(to: CGPoint(x: 43, y: 3), control: CGPoint(x: 29, y: 4))
            p.addQuadCurve(to: CGPoint(x: 38, y: 14), control: CGPoint(x: 46, y: 12))
            p.addQuadCurve(to: CGPoint(x: 16, y: 16), control: CGPoint(x: 24, y: 20))
            p.closeSubpath()
        }, from: muzzle, to: coatLight, in: &head)
        fill(path { p in
            p.move(to: CGPoint(x: -11, y: -17))
            p.addCurve(to: CGPoint(x: 1, y: -6), control1: CGPoint(x: -2, y: -22), control2: CGPoint(x: 2, y: -15))
            p.addCurve(to: CGPoint(x: -7, y: 38), control1: CGPoint(x: 3, y: 11), control2: CGPoint(x: 7, y: 37))
            p.addCurve(to: CGPoint(x: -22, y: 19), control1: CGPoint(x: -21, y: 39), control2: CGPoint(x: -26, y: 29))
            p.addQuadCurve(to: CGPoint(x: -11, y: -17), control: CGPoint(x: -22, y: -4))
            p.closeSubpath()
        }, from: coat, to: coatShade, in: &head)
        head.fill(Path(ellipseIn: CGRect(x: 15, y: -8, width: 4.5, height: 5)), with: .color(nose))
        head.fill(Path(ellipseIn: CGRect(x: 16.2, y: -7.2, width: 1.2, height: 1.2)), with: .color(muzzle))
        head.fill(Path(ellipseIn: CGRect(x: 40, y: 0, width: 9, height: 6.5)), with: .color(nose))
        stroke(path { p in p.move(to: CGPoint(x: 29, y: 14)); p.addQuadCurve(to: CGPoint(x: 39, y: 12), control: CGPoint(x: 35, y: 16)) }, color: coatShade.opacity(0.7), width: 1.2, in: &head)
    }

    private func path(_ make: (inout Path) -> Void) -> Path {
        var result = Path()
        make(&result)
        return result
    }

    private func fill(_ path: Path, from light: Color, to shade: Color, in context: inout GraphicsContext) {
        let bounds = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: [light, shade]), startPoint: CGPoint(x: bounds.minX, y: bounds.minY), endPoint: CGPoint(x: bounds.maxX, y: bounds.maxY)))
    }

    private func stroke(_ path: Path, color: Color, width: CGFloat, in context: inout GraphicsContext) {
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func roundedRect(_ rect: CGRect, radius: CGFloat, color: Color, in context: inout GraphicsContext) {
        context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
    }
}
