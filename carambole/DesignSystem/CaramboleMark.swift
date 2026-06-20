//
//  CaramboleMark.swift
//  carambole
//
//  The brand mark: the carambole (starfruit) cross-section — a 5-point star whose
//  signature is SMOOTH CONCAVE VALLEYS between sharp rib tips (one quadratic curve
//  per lobe), distinguishing it from a generic star. Pure vector; same geometry as
//  the app icon (design/logo/gen_final.py). Dials: r/R ≈ 0.40, soft tips.
//

import SwiftUI

/// The carambole star as a `Shape` — point-up, centred in, and scaled to, `rect`.
struct CaramboleMark: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let outerR = radius * 0.84   // rib tips  (icon R 42 / half 50)
        let innerR = radius * 0.34   // valleys   (icon r 17 / half 50)
        let rot = -90.0              // one point straight up

        func point(_ angleDeg: Double, _ rad: CGFloat) -> CGPoint {
            let a = angleDeg * .pi / 180
            return CGPoint(x: center.x + rad * CGFloat(cos(a)),
                           y: center.y + rad * CGFloat(sin(a)))
        }

        var tips: [CGPoint] = []
        var valleys: [CGPoint] = []
        for k in 0..<5 {
            tips.append(point(rot + 72 * Double(k), outerR))
            valleys.append(point(rot + 36 + 72 * Double(k), innerR))
        }

        p.move(to: tips[0])
        for k in 0..<5 {
            p.addQuadCurve(to: tips[(k + 1) % 5], control: valleys[k])
        }
        p.closeSubpath()
        return p
    }
}

/// The carambole logo — filled mark with softened tips (fill + round-join stroke,
/// matching the icon's soft-3 detail). Decorative; hidden from accessibility.
struct CaramboleLogo: View {
    var color: Color = AppColor.ink
    var size: CGFloat = 28

    var body: some View {
        let lineWidth = size * 0.03
        CaramboleMark()
            .fill(color)
            .overlay(
                CaramboleMark()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
            )
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 24) {
        CaramboleLogo(color: AppColor.ink, size: 64)
        CaramboleLogo(color: AppColor.saffronDeep, size: 40)
        CaramboleLogo(color: AppColor.ink, size: 24)
    }
    .padding()
    .background(AppColor.paper)
}
#endif
