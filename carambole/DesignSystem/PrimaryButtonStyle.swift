//
//  PrimaryButtonStyle.swift
//  carambole
//
//  "Le Cahier" primary button + tracked-uppercase section label.
//  Composes the spring press-feel of the existing `ScaleButtonStyle`.
//

import SwiftUI

// MARK: - PrimaryButtonStyle

/// Ink fill, paper text, rounded corners. Pressed state tints the fill to
/// `saffronDeep` and scales ~0.96 with the `ScaleButtonStyle` spring feel.
struct PrimaryButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appLabel)
            .fontWeight(.semibold)
            .tracking(1)
            .textCase(.uppercase)
            .foregroundColor(AppColor.paper)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(configuration.isPressed ? AppColor.saffronDeep : AppColor.ink)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// MARK: - Section Label

/// The tracked-uppercase label style used by section headers (e.g. "SEARCH").
/// Small, kerning ≈2, `graphite`.
struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.appLabel)
            .tracking(2)
            .textCase(.uppercase)
            .foregroundColor(AppColor.graphite)
    }
}

// MARK: - View Extension

extension View {
    /// Applies the tracked-uppercase label treatment (kerning ≈2, `graphite`)
    /// to any text-bearing view.
    func uppercaseLabel() -> some View {
        self
            .font(.appLabel)
            .tracking(2)
            .textCase(.uppercase)
            .foregroundColor(AppColor.graphite)
    }
}
