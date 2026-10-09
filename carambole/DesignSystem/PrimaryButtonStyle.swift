//
//  PrimaryButtonStyle.swift
//  carambole
//
//  Primary pill button + tracked-uppercase label (motion.html 07 / 03).
//

import SwiftUI

// MARK: - PrimaryButtonStyle

/// The 07/03 fixed button: black 54pt pill, paper text, Manrope 400 16pt.
/// Pressed state dims to graphite and scales ~0.97.
struct PrimaryButtonStyle: ButtonStyle {
    var height: CGFloat = 54

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.display(size: 16, wght: 400))
            .foregroundColor(AppColor.paper)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .background(
                Capsule(style: .continuous)
                    .fill(configuration.isPressed ? AppColor.graphite : AppColor.ink)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Section Label

/// The tracked-uppercase label (motion.html `.lab`): Familjen Grotesk 11pt,
/// tracking 0.12em, `g2`.
struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text).uppercaseLabel()
    }
}

// MARK: - View Extension

extension View {
    /// Applies the tracked-uppercase label treatment (Familjen 11pt, 0.12em,
    /// `g2` by default; pass `AppColor.ink` for the `.lab.ink` variant).
    func uppercaseLabel(_ color: Color = AppColor.g2) -> some View {
        self
            .font(.appLabel)
            .tracking(labelTracking)
            .textCase(.uppercase)
            .foregroundColor(color)
    }
}
