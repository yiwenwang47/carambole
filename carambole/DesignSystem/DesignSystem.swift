//
//  DesignSystem.swift
//  carambole
//
//  "Objets + mouvement" design system — neutrals, grotesk type, spacing.
//  Design source: design/motion.html; build plan:
//  docs/plans/2026-10-09-ui-redesign-implementation.md.
//
//  Light mode only, white ground, ink text. Colour comes from the learner's
//  palette (`Theme.swift`: Acide / Iris / Surimpression) and goes to objects,
//  never to running text; buttons and large fills use pale, saturation-capped
//  colour, dark buttons are grey (`buttonDark`), never black. State still also
//  reads by form: filled, outline, dashed = fragile or wrong.
//

import CoreText
import SwiftUI
import UIKit

// MARK: - Color(hex:)

extension Color {
    /// Creates a `Color` from a 6-digit hex string (e.g. "FAF7F0" or "#FAF7F0").
    /// Falls back to opaque black for malformed input.
    init(hex: String) {
        let sanitized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Palette

/// Grayscale palette (motion.html `:root`). Old "Le Cahier" names are kept
/// and remapped so untouched screens move with the redesign.
enum AppColor {
    /// App background — pure white (every palette keeps a white ground).
    static let paper = Color(hex: "FFFFFF")
    /// Pure white — tile / token faces that sit on `paper`.
    static let white = Color(hex: "FFFFFF")
    /// Primary text, borders, primary button fill.
    static let ink = Color(hex: "141414")
    /// Secondary text (g1).
    static let graphite = Color(hex: "4A4A4A")
    /// Quiet labels, placeholders (g2).
    static let g2 = Color(hex: "8D8D8A")
    /// Tracks, disabled, locked (g3).
    static let g3 = Color(hex: "C8C7C3")
    /// Fill of any dark button: a dark grey, never full black.
    static let buttonDark = Color(hex: "3A3A3A")
    /// Pressed dark button.
    static let buttonDarkPressed = Color(hex: "555555")
    /// Rules, dividers, faint tracks (g4).
    static let hairline = Color(hex: "E6E5E1")
    /// Legacy pressed accent → graphite.
    static let saffronDeep = Color(hex: "4A4A4A")
}

// MARK: - Fonts

/// Registers the bundled OFL fonts (Manrope, Familjen Grotesk) at launch and
/// builds variable-weight `UIFont`s. The project uses a generated Info.plist,
/// so fonts are registered in code instead of via `UIAppFonts`.
enum AppFonts {
    static let manrope = "Manrope-Regular"
    static let familjen = "FamiljenGrotesk-Regular"

    /// OpenType 'wght' axis tag.
    private static let wghtAxis = 0x7767_6874

    private static var registered = false
    private static var cache: [String: UIFont] = [:]
    private static let lock = NSLock()

    /// Idempotent. Call once from `caramboleApp.init()`.
    static func register() {
        lock.lock(); defer { lock.unlock() }
        guard !registered else { return }
        registered = true
        for name in ["Manrope-Variable", "FamiljenGrotesk-Variable"] {
            let url = Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf")
            guard let url else {
                assertionFailure("Missing bundled font \(name).ttf")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                // Already-registered is fine (e.g. SwiftUI previews).
                error?.release()
            }
        }
    }

    /// A variable-weight font. `wght` is clamped to the face's axis range and
    /// rounded to whole units so the cache stays small during weight waves.
    static func uiFont(_ postScript: String, size: CGFloat, wght: CGFloat) -> UIFont {
        let w = Int(wght.rounded())
        let key = "\(postScript)|\(size)|\(w)"
        lock.lock(); defer { lock.unlock() }
        if let hit = cache[key] { return hit }
        let base = UIFontDescriptor(name: postScript, size: size)
        let desc = base.addingAttributes([
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): [wghtAxis: w],
        ])
        let font = UIFont(descriptor: desc, size: size)
        cache[key] = font
        return font
    }
}

extension Font {
    /// Manrope display face on its variable `wght` axis (200–800).
    static func display(size: CGFloat, wght: CGFloat = 300) -> Font {
        Font(AppFonts.uiFont(AppFonts.manrope, size: size, wght: min(max(wght, 200), 800)))
    }

    /// Familjen Grotesk small label face. Use UPPERCASE with ~0.12em tracking
    /// (see `.uppercaseLabel()`).
    static func label(size: CGFloat = 11, wght: CGFloat = 400) -> Font {
        Font(AppFonts.uiFont(AppFonts.familjen, size: size, wght: min(max(wght, 400), 700)))
    }
}

// MARK: - Typography (legacy names → grotesk faces)

extension Font {
    /// Large display numeral / heading. Manrope 200.
    static var appDisplay: Font { .display(size: 44, wght: 200) }

    /// Drill prompt. Manrope 250 (motion.html 07 `.prompt`).
    static var appPrompt: Font { .display(size: 28, wght: 250) }

    /// Screen / section title. Manrope 300.
    static var appTitle: Font { .display(size: 26, wght: 300) }

    /// Token tile text. Manrope 400 (07 `.tile`).
    static var appToken: Font { .display(size: 19, wght: 400) }

    /// Small label — used UPPERCASE with tracking (see `SectionLabel`).
    static var appLabel: Font { .label(size: 11) }

    /// Rule / explanation body. Manrope 400, upright.
    static var appExplain: Font { .display(size: 15, wght: 400) }

    /// Body text for rows and secondary lines. Manrope 400.
    static var appBody: Font { .display(size: 15, wght: 400) }
}

/// Label tracking: 0.12em of the 11pt label face.
let labelTracking: CGFloat = 1.3

// MARK: - Spacing

enum Spacing {
    /// Horizontal screen inset (motion.html: 22px edges).
    static let screenH: CGFloat = 22
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 40
}
