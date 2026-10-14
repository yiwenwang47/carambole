//
//  LanguageMark.swift
//  carambole
//
//  The small fixed mark for each language on the home page: Français is a
//  ribbon link with a half twist (two lobes whose edges cross at the waist),
//  English a petal with its tip folded over. Two drawing styles, picked under
//  Colors (`LanguageMarkStyle`, default Cut paper):
//    - Cut paper: black shapes with a soft torn edge, the palette's quiet colour
//      printed over them, the book count in the palette's deep colour.
//    - Script sticker: a black die-cut drawn with one thin cream line, the
//      sparkle in the palette's loud colour.
//  Geometry is a line-for-line port of design/studio/marks.js (same SVG path
//  data, same view boxes, same seeded torn edge), so the app matches the mock.
//

import SwiftUI

enum LanguageMarkStyle: String, CaseIterable, Identifiable {
    case cut, script

    static let storageKey = "carambole.languageMark"
    static let fallback: LanguageMarkStyle = .cut

    var id: String { rawValue }

    init(stored: String) {
        self = LanguageMarkStyle(rawValue: stored) ?? Self.fallback
    }

    var name: String {
        switch self {
        case .cut: return "Cut paper"
        case .script: return "Script sticker"
        }
    }

    var blurb: String {
        switch self {
        case .cut: return "Black cut-outs with a torn edge, your palette printed over them."
        case .script: return "A black sticker drawn with one thin cream line."
        }
    }
}

// MARK: - View

struct LanguageMarkView: View {
    let language: ShelfLanguage
    var style: LanguageMarkStyle = .cut
    let theme: AppTheme

    var body: some View {
        Canvas { ctx, size in
            switch style {
            case .cut: LanguageMarkArt.drawCut(language, theme: theme, in: &ctx, size: size)
            case .script: LanguageMarkArt.drawScript(language, theme: theme, in: &ctx, size: size)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Drawing

enum LanguageMarkArt {
    /// marks.js `G`, in a 100 × 100 design box.
    private static let top = svgPath("M54,4 C36,10 28,32 50,50 C62,40 68,18 54,4 Z")
    private static let bot = svgPath("M50,50 C32,60 30,84 46,96 C62,88 72,64 50,50 Z")
    private static let edgeL = svgPath("M54,4 C36,10 28,32 50,50 C72,64 62,88 46,96")
    private static let edgeR = svgPath("M54,4 C68,18 62,40 50,50 C32,60 30,84 46,96")
    private static let petal = svgPath("M50,95 C30,82 16,56 22,34 C26,18 40,8 56,10 C72,13 82,28 78,48 C74,68 64,84 50,95 Z")
    private static let fold = svgPath("M56,10 C70,12 81,26 79,42 C72,34 62,28 52,24 C52,18 54,13 56,10 Z")
    private static let vein = svgPath("M50,90 C46,70 47,48 54,30")

    // Cut paper: torn copies (seeded exactly as in marks.js).
    private static let cutTop = wobbly(top, amp: 0.8, waves: 6, seed: 3)
    private static let cutBot = wobbly(bot, amp: 0.8, waves: 6, seed: 5)
    private static let cutPetal = wobbly(petal, amp: 0.9, waves: 7, seed: 7)
    private static let overFr: Path = {
        let about = CGAffineTransform(translationX: -50, y: -70)
            .concatenating(CGAffineTransform(rotationAngle: 8 * .pi / 180))
            .concatenating(CGAffineTransform(translationX: 50, y: 70))
        return wobbly(bot, amp: 0.8, waves: 6, seed: 9)
            .applying(about.concatenating(CGAffineTransform(translationX: 9, y: -7)))
    }()
    private static let overEn: Path = {
        let t = CGAffineTransform(translationX: -14, y: -2)
            .concatenating(CGAffineTransform(scaleX: 1.3, y: 1.3))
            .concatenating(CGAffineTransform(translationX: 18, y: -4))
        return wobbly(fold, amp: 1, waves: 8, seed: 2).applying(t)
    }()

    // Script sticker: loops and the sparkle.
    private static let curlsFr = [svgPath("M52,5 C46,-6 32,-4 35,5 C38,13 51,9 52,5"),
                                  svgPath("M48,95 C40,106 24,101 28,92 C31,85 42,89 40,97")]
    private static let curlsEn = [svgPath("M50,95 C52,106 66,108 68,99 C69,92 59,92 61,99"),
                                  svgPath("M22,34 C10,30 6,18 14,14 C20,11 24,20 18,24")]
    private static let starFr = sparkle(86, 22, 6)
    private static let starEn = sparkle(86, 80, 6)

    /// SVG `viewBox` → canvas (xMidYMid meet).
    private static func fit(_ box: CGRect, _ size: CGSize) -> (CGAffineTransform, CGFloat) {
        let s = min(size.width / box.width, size.height / box.height)
        let tx = (size.width - box.width * s) / 2 - box.minX * s
        let ty = (size.height - box.height * s) / 2 - box.minY * s
        return (CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: tx, ty: ty), s)
    }

    static func drawCut(_ language: ShelfLanguage, theme: AppTheme, in ctx: inout GraphicsContext, size: CGSize) {
        let (t, s) = fit(CGRect(x: -22, y: -18, width: 140, height: 136), size)
        let shapes = (language == .french ? [cutTop, cutBot] : [cutPetal]).map { $0.applying(t) }
        let round = StrokeStyle(lineWidth: 10 * s, lineCap: .round, lineJoin: .round)
        for p in shapes { ctx.fill(p, with: .color(.white)); ctx.stroke(p, with: .color(.white), style: round) }
        for p in shapes { ctx.fill(p, with: .color(Color(hex: "0F0F0F"))) }

        var over = ctx
        over.blendMode = .multiply
        over.opacity = 0.9
        over.fill((language == .french ? overFr : overEn).applying(t), with: .color(Color(hex: theme.tokenReview)))

        // Book count, Manrope 300 / 34, tracking −1.8, baseline at (66, 70) or (70, 84).
        let fontSize = 34 * s
        let ui = AppFonts.uiFont(AppFonts.manrope, size: fontSize, wght: 300)
        let base = (language == .french ? CGPoint(x: 66, y: 70) : CGPoint(x: 70, y: 84)).applying(t)
        let count = String(format: "%02d", language.books.count)
        ctx.draw(Text(count).font(.display(size: fontSize, wght: 300)).tracking(-1.8 * s)
                    .foregroundColor(Color(hex: theme.fragile)),
                 at: CGPoint(x: base.x, y: base.y - ui.ascender), anchor: .topLeading)
    }

    static func drawScript(_ language: ShelfLanguage, theme: AppTheme, in ctx: inout GraphicsContext, size: CGSize) {
        let (t, s) = fit(CGRect(x: -20, y: -20, width: 140, height: 140), size)
        let fr = language == .french
        let curls = (fr ? curlsFr : curlsEn).map { $0.applying(t) }
        let star = (fr ? starFr : starEn).applying(t)
        let fills = (fr ? [top, bot] : [petal]).map { $0.applying(t) } + [star]
        let black = Color(hex: "171313")
        let thick = StrokeStyle(lineWidth: 18 * s, lineCap: .round, lineJoin: .round)
        for p in fills { ctx.fill(p, with: .color(black)); ctx.stroke(p, with: .color(black), style: thick) }
        for p in curls { ctx.stroke(p, with: .color(black), style: thick) }

        let line = StrokeStyle(lineWidth: 1.7 * s, lineCap: .round, lineJoin: .round)
        let cream = Color(hex: "F1EBDF")
        for p in (fr ? [edgeL, edgeR] : [petal, fold, vein]).map({ $0.applying(t) }) + curls {
            ctx.stroke(p, with: .color(cream), style: line)
        }
        ctx.fill(star, with: .color(Color(hex: theme.tokenNew)))
    }

    // MARK: Geometry helpers

    /// Four-point star with concave sides (marks.js `sparkle`).
    static func sparkle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
        var p = Path()
        let c = CGPoint(x: x, y: y)
        p.move(to: CGPoint(x: x, y: y - r))
        p.addQuadCurve(to: CGPoint(x: x + r, y: y), control: c)
        p.addQuadCurve(to: CGPoint(x: x, y: y + r), control: c)
        p.addQuadCurve(to: CGPoint(x: x - r, y: y), control: c)
        p.addQuadCurve(to: CGPoint(x: x, y: y - r), control: c)
        p.closeSubpath()
        return p
    }

    /// Parses the absolute SVG commands used by the mock (M, L, C, Q, Z).
    static func svgPath(_ d: String) -> Path {
        var p = Path()
        var tokens: [String] = []
        var num = ""
        func flush() { if !num.isEmpty { tokens.append(num); num = "" } }
        for ch in d {
            if "MLCQZ".contains(ch) { flush(); tokens.append(String(ch)) }
            else if ch == "," || ch == " " { flush() }
            else if ch == "-" && !num.isEmpty && !num.hasSuffix("e") { flush(); num = "-" }
            else { num.append(ch) }
        }
        flush()
        var i = 0, cmd = "M"
        func n() -> CGFloat { defer { i += 1 }; return CGFloat(Double(tokens[i]) ?? 0) }
        func pt() -> CGPoint { let x = n(); return CGPoint(x: x, y: n()) }
        while i < tokens.count {
            if "MLCQZ".contains(tokens[i]) { cmd = tokens[i]; i += 1 }
            switch cmd {
            case "M": p.move(to: pt()); cmd = "L"
            case "L": p.addLine(to: pt())
            case "C": let a = pt(), b = pt(); p.addCurve(to: pt(), control1: a, control2: b)
            case "Q": let a = pt(); p.addQuadCurve(to: pt(), control: a)
            case "Z": p.closeSubpath()
            default: i += 1
            }
        }
        return p
    }

    /// marks.js `wobbly`: resample a closed outline evenly by length (180
    /// points) and push each point along its normal by a seeded two-sine wave.
    static func wobbly(_ path: Path, amp: CGFloat, waves: CGFloat, seed: Double) -> Path {
        // Flatten.
        var poly: [CGPoint] = []
        var cur = CGPoint.zero, start = CGPoint.zero
        path.forEach { el in
            switch el {
            case .move(let to): cur = to; start = to; poly.append(to)
            case .line(let to): poly.append(to); cur = to
            case .quadCurve(let to, let c):
                for k in 1...24 { let t = CGFloat(k) / 24, u = 1 - t
                    poly.append(CGPoint(x: u * u * cur.x + 2 * u * t * c.x + t * t * to.x,
                                        y: u * u * cur.y + 2 * u * t * c.y + t * t * to.y)) }
                cur = to
            case .curve(let to, let c1, let c2):
                for k in 1...32 { let t = CGFloat(k) / 32, u = 1 - t
                    let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, e = t * t * t
                    poly.append(CGPoint(x: a * cur.x + b * c1.x + c * c2.x + e * to.x,
                                        y: a * cur.y + b * c1.y + c * c2.y + e * to.y)) }
                cur = to
            case .closeSubpath: poly.append(start); cur = start
            }
        }
        guard poly.count > 2 else { return path }
        var cum: [CGFloat] = [0]
        for k in 1..<poly.count { cum.append(cum[k - 1] + hypot(poly[k].x - poly[k - 1].x, poly[k].y - poly[k - 1].y)) }
        let total = cum.last ?? 1
        func at(_ len: CGFloat) -> CGPoint {
            let l = len.truncatingRemainder(dividingBy: total)
            var j = 1
            while j < cum.count - 1 && cum[j] < l { j += 1 }
            let span = max(cum[j] - cum[j - 1], 1e-6), f = (l - cum[j - 1]) / span
            return CGPoint(x: poly[j - 1].x + (poly[j].x - poly[j - 1].x) * f,
                           y: poly[j - 1].y + (poly[j].y - poly[j - 1].y) * f)
        }
        let r = { (k: Double) -> Double in (sin(seed * 12.9898 + k * 78.233) * 43758.5453).truncatingRemainder(dividingBy: 1) }
        let n = 180
        var out = Path()
        for i in 0..<n {
            let a = at(total * CGFloat(i) / CGFloat(n)), b = at(total * CGFloat((i + 1) % n) / CGFloat(n))
            let tx = b.x - a.x, ty = b.y - a.y, m = max(hypot(tx, ty), 1e-6), t = Double(i) / Double(n)
            let off = amp * CGFloat(sin(2 * .pi * Double(waves) * t + r(1) * 6) * 0.7
                                    + sin(2 * .pi * Double(waves) * 2.3 * t + r(2) * 6) * 0.3)
            let q = CGPoint(x: a.x - ty / m * off, y: a.y + tx / m * off)
            if i == 0 { out.move(to: q) } else { out.addLine(to: q) }
        }
        out.closeSubpath()
        return out
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 24) {
        ForEach(LanguageMarkStyle.allCases) { style in
            VStack(spacing: 16) {
                LanguageMarkView(language: .english, style: style, theme: AppPalette.acide.theme).frame(width: 96, height: 96)
                LanguageMarkView(language: .french, style: style, theme: AppPalette.acide.theme).frame(width: 96, height: 96)
            }
        }
    }
}
#endif
