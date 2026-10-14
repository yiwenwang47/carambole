//
//  Theme.swift
//  carambole
//
//  The three colour palettes the learner can pick (design/palettes.html v4):
//  Acide (lime + sky), Iris (lilac + pistachio) and
//  Surimpression (soft riso pink + blue that overprint). The ground stays white
//  and running text stays ink; colour goes to the objects — the star and its
//  ring, the Today tokens, the drill magnets, the library ribbon, button counts.
//
//  The choice persists in UserDefaults under `AppPalette.storageKey`. SwiftUI
//  views read it with `@AppStorage(AppPalette.storageKey)` so they redraw on
//  change; SpriteKit / RealityKit code reads `AppPalette.current`.
//

import SwiftUI
import UIKit

enum AppPalette: String, CaseIterable, Identifiable {
    case acide, iris, surimpression

    static let storageKey = "carambole.palette"
    static let fallback: AppPalette = .acide

    var id: String { rawValue }

    /// The stored choice (Acide until the learner picks another).
    static var current: AppPalette {
        UserDefaults.standard.string(forKey: storageKey).flatMap(AppPalette.init(rawValue:)) ?? fallback
    }

    init(stored: String) {
        self = AppPalette(rawValue: stored) ?? Self.fallback
    }

    var name: String {
        switch self {
        case .acide: return "Acide"
        case .iris: return "Iris"
        case .surimpression: return "Surimpression"
        }
    }

    /// One plain line for the colour page.
    var blurb: String {
        switch self {
        case .acide: return "Lime star, sky blue."
        case .iris: return "Lilac star, pistachio."
        case .surimpression: return "Soft blue and pink that overprint."
        }
    }

    var theme: AppTheme {
        switch self {
        case .acide:
            return AppTheme(
                tokenNew: "C6EE34", tokenReview: "9CC2EF", fragile: "4F8DD6",
                tileOn: "E5F2BC", buttonCount: "9CC2EF", ring: "5E9BE0",
                star: .acrylic(color: "C6EE34"), starArc: "5E9BE0", starArcSoft: "B9D3F3",
                starBead: "5E9BE0", starTrack: "C9DCF5",
                ribbonFront: "D3F45A", ribbonBack: "7FAFE8",
                soonFront: "BED6F4", soonBack: "9FC3EE",
                buttonFill: "DDE6BC", quietFill: "BCCFE6", tint: "E9F2FD",
                overprint: false)
        case .iris:
            return AppTheme(
                tokenNew: "CFC3FF", tokenReview: "D7EBA8", fragile: "6E56E8",
                tileOn: "EAF2D6", buttonCount: "D7EBA8", ring: "9CC94A",
                star: .iris, starArc: "141414", starArcSoft: "CFC3FF",
                starBead: "141414", starTrack: "D7EBA8",
                ribbonFront: "ECE8FB", ribbonBack: "C9E39A",
                soonFront: "E1F0BE", soonBack: "DBD2FF",
                buttonFill: "D9E6BC", quietFill: "D9D3EE", tint: "F2EFFF",
                overprint: false)
        case .surimpression:
            // Blue is the loud ink (star, new work, placed magnets); pink the quiet one.
            return AppTheme(
                tokenNew: "7E98D8", tokenReview: "EC93B5", fragile: "D0668F",
                tileOn: "D3DCF0", buttonCount: "9EB2E4", ring: "D0668F",
                star: .acrylic(color: "7E98D8"), starArc: "EC93B5", starArcSoft: "B9C7EC",
                starBead: "EC93B5", starTrack: "DCE3F5",
                ribbonFront: "8CA4DE", ribbonBack: "EC93B5",
                soonFront: "C3D0F0", soonBack: "F3C7D8",
                buttonFill: "BCC8E6", quietFill: "E6BCCC", tint: "FBE7EF",
                overprint: true)
        }
    }
}

/// Colours of one palette, as hex strings (no #). Text on every fill is ink.
struct AppTheme: Equatable {
    enum StarFinish: Equatable {
        /// Tinted acrylic: glossy, lit a little from inside.
        case acrylic(color: String)
        /// Pearly metal whose sheen shifts violet / green / gold with the angle.
        case iris
    }

    /// Today tokens + drill magnets.
    let tokenNew: String
    let tokenReview: String
    /// Dashed outline: fragile tokens, wrong magnets.
    let fragile: String
    /// A magnet placed on the answer line: a much paler version of the loud colour.
    let tileOn: String
    /// The count inside a black start pill.
    let buttonCount: String
    /// 2D progress ring arc.
    let ring: String

    /// 01 Objet: the die-cut card prints this colour (Iris: `tokenNew`); the
    /// finish itself is used only by the `objet` trial look (`StarCard`).
    let star: StarFinish
    let starArc: String
    let starArcSoft: String
    let starBead: String
    let starTrack: String

    /// 08 library ribbon: started book, then books to come.
    let ribbonFront: String
    let ribbonBack: String
    let soonFront: String
    let soonBack: String

    /// Pale, saturation-capped fills (HSL S ≤ 45 %, L ≥ 82 %) for buttons and
    /// any large area: the loud colour, the quiet colour, and a near-white tint.
    /// Full-strength colour is for lines, outlines, small marks and 3D objects.
    let buttonFill: String
    let quietFill: String
    let tint: String

    /// Coloured tokens multiply where they overlap (Surimpression).
    let overprint: Bool
}

/// How colour reaches the lesson card and drills (design/drill-colour.html).
enum DrillStyle: String, CaseIterable, Identifiable {
    /// One big pale object per page: a slab on the lesson card, a tray under
    /// the word bank, round Indice / Écouter buttons, pale filled buttons.
    case plateau
    /// Outlines only: framed Indice / Écouter and answer well, dark buttons
    /// carrying a pale disc with the arrow.
    case cadres

    static let storageKey = "carambole.drillStyle"
    static let fallback: DrillStyle = .plateau

    var id: String { rawValue }

    init(stored: String) {
        self = DrillStyle(rawValue: stored) ?? Self.fallback
    }

    var name: String {
        switch self {
        case .plateau: return "Plateau"
        case .cadres: return "Cadres"
        }
    }

    var blurb: String {
        switch self {
        case .plateau: return "A pale tray under the words, filled buttons."
        case .cadres: return "Coloured frames, dark buttons."
        }
    }
}

extension UIColor {
    /// Opaque colour from a 6-digit hex string.
    convenience init(hex: String) {
        var rgb: UInt64 = 0
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&rgb)
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
    }
}
