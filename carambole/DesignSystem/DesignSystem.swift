//
//  DesignSystem.swift
//  carambole
//
//  "Le Cahier" design system foundation — palette, typography, spacing.
//  See docs/plans/2026-06-18-design-system.md for the full spec.
//
//  Light mode only. Serif is the signature for display type.
//

import SwiftUI

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

/// The "Le Cahier" palette. Single accent discipline: saffron only.
/// Sage/terracotta appear ONLY on answer result state.
enum AppColor {
    /// App background — warm cream, NOT pure white.
    static let paper = Color(hex: "FAF7F0")
    /// Primary text, borders, primary button fill.
    static let ink = Color(hex: "14110E")
    /// Secondary text, uppercase labels.
    static let graphite = Color(hex: "6B655C")
    /// THE accent — progress, current marker, sweep.
    static let saffron = Color(hex: "FFB879")
    /// Pressed/active accent.
    static let saffronDeep = Color(hex: "E8915C")
    /// Correct-answer state (muted sage).
    static let success = Color(hex: "5B8C5A")
    /// Wrong-answer state (terracotta).
    static let error = Color(hex: "C0563F")
    /// Rules, dividers, progress track, tile border.
    static let hairline = Color(hex: "E2DBCD")
}

// MARK: - Typography

extension Font {
    /// Large display heading. Serif — the signature. ≈44, semibold.
    static var appDisplay: Font {
        .system(size: 44, weight: .semibold, design: .serif)
    }

    /// Display / drill prompt. Serif — the signature. ≈32, semibold.
    static var appPrompt: Font {
        .system(size: 32, weight: .semibold, design: .serif)
    }

    /// Topic / section title. Serif. ≈26, semibold.
    static var appTitle: Font {
        .system(size: 26, weight: .semibold, design: .serif)
    }

    /// Token tile text. Rounded, tactile. ≈20, medium.
    static var appToken: Font {
        .system(size: 20, weight: .medium, design: .rounded)
    }

    /// Small label — used UPPERCASE with tracking (see `SectionLabel`). ≈13.
    static var appLabel: Font {
        .system(size: 13, weight: .regular, design: .default)
    }

    /// Rule / explanation body. Serif italic. ≈16.
    static var appExplain: Font {
        .system(size: 16, weight: .regular, design: .serif).italic()
    }
}

// MARK: - Spacing

enum Spacing {
    /// Horizontal screen inset — matches the current home's left padding.
    static let screenH: CGFloat = 40
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 40
}
