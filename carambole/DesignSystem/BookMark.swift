//
//  BookMark.swift
//  carambole
//
//  The small fixed mark beside each book on a shelf, drawn with the language
//  marks' recipes (`LanguageMarkArt`) so the two families match:
//    - Fondations: a carambole seed. En situation: a guillemet «.
//      Monnaie courante: a bitten coin (studio round 3, 2026-10-23).
//    - Cut paper: white die-cut sheet, a soft torn face, the quiet colour
//      printed off register over one part, the book number in the deep colour.
//    - Script sticker: the face as a sticker with one thin ink line and a
//      sparkle in the quiet colour.
//  Colours are the palette's "Pale" face (design/studio round 2): the pale
//  fill moved 30 % back toward the palette colour; numbers are the deep colour
//  with 20 % grey. A book to come draws its mark in greys.
//  Geometry is a line-for-line port of design/studio/books.js.
//

import SwiftUI

enum BookMarkShape {
    case seed, guillemet, bitten

    /// The shape for a book on the shelf (placeholders reuse their twin's).
    init(bookID: String) {
        switch bookID {
        case BookCatalog.enSituation.id: self = .guillemet
        case BookCatalog.mots.id: self = .bitten
        default: self = .seed
        }
    }
}

struct BookMarkView: View {
    let shape: BookMarkShape
    /// Two-digit number printed on the cut-paper mark ("01").
    let number: String
    var available = true
    var style: LanguageMarkStyle = .cut
    let palette: AppPalette

    var body: some View {
        Canvas { ctx, size in
            let colors = available ? BookMarkArt.Colors(palette) : .soon
            switch style {
            case .cut: BookMarkArt.drawCut(shape, number: number, colors: colors, in: &ctx, size: size)
            case .script: BookMarkArt.drawScript(shape, colors: colors, in: &ctx, size: size)
            }
        }
        .accessibilityHidden(true)
    }
}

enum BookMarkArt {
    struct Colors {
        let face: Color
        let over: Color
        let number: Color

        static let soon = Colors(face: Color(hex: "E6E5E1"), over: Color(hex: "D6D5D1"), number: Color(hex: "C8C7C3"))

        /// books.js `FACES.pale`, from the same palette values the marks mock uses.
        init(_ palette: AppPalette) {
            let t = palette.theme
            // The pale fill that carries each colour's hue (Iris names them the other way round).
            let (paleLoud, paleQuiet) = palette == .iris ? (t.quietFill, t.buttonFill) : (t.buttonFill, t.quietFill)
            face = Color(hex: Self.mix(paleLoud, t.tokenNew, 0.3))
            over = Color(hex: Self.mix(paleQuiet, t.tokenReview, 0.3))
            number = Color(hex: Self.mix(t.fragile, "8D8D8A", 0.2))
        }

        init(face: Color, over: Color, number: Color) {
            self.face = face; self.over = over; self.number = number
        }

        /// marks.js `mix`: per-channel linear blend, rounded.
        static func mix(_ a: String, _ b: String, _ t: Double) -> String {
            func rgb(_ h: String) -> [Double] {
                var v: UInt64 = 0
                Scanner(string: h).scanHexInt64(&v)
                return [Double((v >> 16) & 0xFF), Double((v >> 8) & 0xFF), Double(v & 0xFF)]
            }
            let x = rgb(a), y = rgb(b)
            return (0..<3).map { String(format: "%02X", Int((x[$0] + (y[$0] - x[$0]) * t).rounded())) }.joined()
        }
    }

    private static let svg = LanguageMarkArt.svgPath
    private static let wobbly = LanguageMarkArt.wobbly

    private static let seed = svg("M50,5 C71,17 81,44 75,69 C71,86 59,95 47,94 C32,93 24,80 26,62 C28,38 36,18 50,5 Z")
    private static let seedFold = svg("M50,5 C66,20 72,44 66,66 C62,80 56,88 50,92 C58,72 58,40 50,5 Z")
    private static let seedLine = [svg("M50,10 C58,36 58,70 47,90")]
    private static let guilL = svg("M48,18 C52,22 52,27 48,31 L33,50 L48,69 C52,73 52,78 48,82 C44,86 38,85 35,81 L16,57 C13,53 13,47 16,43 L35,19 C38,15 44,14 48,18 Z")
    private static let guilR = svg("M80,18 C84,22 84,27 80,31 L65,50 L80,69 C84,73 84,78 80,82 C76,86 70,85 67,81 L48,57 C45,53 45,47 48,43 L67,19 C70,15 76,14 80,18 Z")
    private static let guilLines = [svg("M42,24 L24,50 L42,76"), svg("M74,24 L56,50 L74,76")]

    /// books.js `radial`: a closed outline from a polar radius r(θ) around
    /// (cx, cy), smoothed with quadratic curves through midpoints.
    private static func radial(_ cx: CGFloat, _ cy: CGFloat, n: Int = 96, _ r: (Double) -> Double) -> Path {
        let pts = (0..<n).map { i -> CGPoint in
            let a = Double(i) / Double(n) * 2 * .pi, rad = r(a)
            return CGPoint(x: cx + rad * cos(a), y: cy + rad * sin(a))
        }
        func mid(_ p: CGPoint, _ q: CGPoint) -> CGPoint { CGPoint(x: (p.x + q.x) / 2, y: (p.y + q.y) / 2) }
        var p = Path()
        p.move(to: mid(pts[n - 1], pts[0]))
        for i in 0..<n { p.addQuadCurve(to: mid(pts[i], pts[(i + 1) % n]), control: pts[i]) }
        p.closeSubpath()
        return p
    }
    /// books.js `bitten`: one soft bite out of the top right rim, two shallow
    /// tooth marks in it.
    private static func bitten(_ R: Double) -> (Double) -> Double {
        { t in
            let c = -Double.pi / 4, w = 0.5
            let u = (((t - c).truncatingRemainder(dividingBy: 2 * .pi)) + 3 * .pi).truncatingRemainder(dividingBy: 2 * .pi) - .pi
            if abs(u) > w { return R }
            let s = (u + w) / (2 * w)
            return R - 12 * pow(sin(.pi * s), 1.4) * (1 - 0.22 * pow(sin(2 * .pi * s), 2))
        }
    }
    /// books.js `crescent`: the part of disc A outside disc B, a sheen along
    /// one rim (each disc = centre + polar radius).
    private static func crescent(_ a: (CGFloat, CGFloat, (Double) -> Double),
                                 _ b: (CGFloat, CGFloat, (Double) -> Double), n: Int = 240) -> Path {
        typealias Disc = (CGFloat, CGFloat, (Double) -> Double)
        func at(_ d: Disc, _ t: Double) -> CGPoint { let r = d.2(t); return CGPoint(x: d.0 + r * cos(t), y: d.1 + r * sin(t)) }
        func inside(_ d: Disc, _ p: CGPoint) -> Bool {
            hypot(p.x - d.0, p.y - d.1) < d.2(atan2(Double(p.y - d.1), Double(p.x - d.0)))
        }
        func run(_ d: Disc, _ other: Disc, keep: Bool) -> [CGPoint] {
            let pts = (0..<n).map { at(d, Double($0) / Double(n) * 2 * .pi) }
            let ok = pts.map { inside(other, $0) == keep }
            guard let k = ok.indices.first(where: { ok[$0] && !ok[($0 + n - 1) % n] }) else { return [] }
            var out: [CGPoint] = []
            var i = 0
            while i < n && ok[(k + i) % n] { out.append(pts[(k + i) % n]); i += 1 }
            return out
        }
        let outer = run(a, b, keep: false)
        var inner = run(b, a, keep: true)
        guard let end = outer.last, let first = inner.first, let last = inner.last else { return Path() }
        func d2(_ p: CGPoint) -> CGFloat { (p.x - end.x) * (p.x - end.x) + (p.y - end.y) * (p.y - end.y) }
        if d2(first) > d2(last) { inner.reverse() }
        var p = Path()
        p.addLines(outer + inner)
        p.closeSubpath()
        return p
    }

    private static let coin = radial(48, 52, bitten(42))
    private static let coinSheen = crescent((48, 52, bitten(42)), (58, 42, { _ in 40 }))
    private static let coinLine = [svg("M16,50 C17,70 30,86 48,90")]

    // Cut paper: torn copies, seeded as in books.js (part i → seed 3 + 2i, overprint → 9).
    private static let cutSeed = [wobbly(seed, 0.8, 6, 3)]
    private static let cutGuil = [wobbly(guilL, 0.8, 6, 3), wobbly(guilR, 0.8, 6, 5)]
    /// Coins ask for a truer edge (books.js `wob: [.35, 3]`).
    private static let cutCoin = [wobbly(coin, 0.35, 3, 3)]
    /// `translate(12 -3) rotate(6 60 50)`.
    private static let overSeed: Path = {
        let about = CGAffineTransform(translationX: -60, y: -50)
            .concatenating(CGAffineTransform(rotationAngle: 6 * .pi / 180))
            .concatenating(CGAffineTransform(translationX: 60, y: 50))
        return wobbly(seedFold, 0.8, 6, 9).applying(about.concatenating(CGAffineTransform(translationX: 12, y: -3)))
    }()
    /// `translate(8 -6)`.
    private static let overGuil = wobbly(guilR, 0.8, 6, 9).applying(CGAffineTransform(translationX: 8, y: -6))
    /// `translate(-4 3)`.
    private static let overCoin = wobbly(coinSheen, 0.35, 3, 9).applying(CGAffineTransform(translationX: -4, y: 3))

    /// SVG `viewBox` → canvas (xMidYMid meet).
    private static func fit(_ box: CGRect, _ size: CGSize) -> (CGAffineTransform, CGFloat) {
        let s = min(size.width / box.width, size.height / box.height)
        let tx = (size.width - box.width * s) / 2 - box.minX * s
        let ty = (size.height - box.height * s) / 2 - box.minY * s
        return (CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: tx, ty: ty), s)
    }

    static func drawCut(_ shape: BookMarkShape, number: String, colors: Colors, in ctx: inout GraphicsContext, size: CGSize) {
        let (t, s) = fit(CGRect(x: -22, y: -18, width: 140, height: 136), size)
        let parts = (shape == .seed ? cutSeed : shape == .guillemet ? cutGuil : cutCoin).map { $0.applying(t) }
        let round = StrokeStyle(lineWidth: 10 * s, lineCap: .round, lineJoin: .round)
        for p in parts { ctx.fill(p, with: .color(.white)); ctx.stroke(p, with: .color(.white), style: round) }
        for p in parts { ctx.fill(p, with: .color(colors.face)) }

        var over = ctx
        over.blendMode = .multiply
        over.opacity = 0.9
        over.fill((shape == .seed ? overSeed : shape == .guillemet ? overGuil : overCoin).applying(t), with: .color(colors.over))

        // Book number, Manrope 300 / 34, tracking −1.8, baseline at (70, 86) or (72, 98).
        let fontSize = 34 * s
        let ui = AppFonts.uiFont(AppFonts.manrope, size: fontSize, wght: 300)
        let base = (shape == .seed ? CGPoint(x: 70, y: 86) : CGPoint(x: 72, y: 98)).applying(t)
        ctx.draw(Text(number).font(.display(size: fontSize, wght: 300)).tracking(-1.8 * s)
                    .foregroundColor(colors.number),
                 at: CGPoint(x: base.x, y: base.y - ui.ascender), anchor: .topLeading)
    }

    static func drawScript(_ shape: BookMarkShape, colors: Colors, in ctx: inout GraphicsContext, size: CGSize) {
        let (t, s) = fit(CGRect(x: -20, y: -20, width: 140, height: 140), size)
        // Coins move the sparkle clear of the round edge (books.js `spark`).
        let star = (shape == .bitten ? LanguageMarkArt.sparkle(0, 100, 6) : LanguageMarkArt.sparkle(90, 14, 6)).applying(t)
        let fills = (shape == .seed ? [seed] : shape == .guillemet ? [guilL, guilR] : [coin]).map { $0.applying(t) } + [star]
        let thick = StrokeStyle(lineWidth: 18 * s, lineCap: .round, lineJoin: .round)
        for p in fills { ctx.fill(p, with: .color(colors.face)); ctx.stroke(p, with: .color(colors.face), style: thick) }
        let line = StrokeStyle(lineWidth: 1.7 * s, lineCap: .round, lineJoin: .round)
        for p in (shape == .seed ? seedLine : shape == .guillemet ? guilLines : coinLine).map({ $0.applying(t) }) {
            ctx.stroke(p, with: .color(Color(hex: "141414")), style: line)
        }
        ctx.fill(star, with: .color(colors.over))
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 24) {
        ForEach(LanguageMarkStyle.allCases) { style in
            VStack(spacing: 16) {
                BookMarkView(shape: .seed, number: "01", style: style, palette: .acide).frame(width: 124, height: 124)
                BookMarkView(shape: .guillemet, number: "02", style: style, palette: .acide).frame(width: 124, height: 124)
                BookMarkView(shape: .bitten, number: "03", style: style, palette: .acide).frame(width: 124, height: 124)
            }
        }
    }
}
#endif
