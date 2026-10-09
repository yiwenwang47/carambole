//
//  PrimaryButtonStyle.swift
//  carambole
//
//  Primary pill button + tracked-uppercase label (motion.html 07 / 03).
//

import SwiftUI

// MARK: - PrimaryButtonStyle

/// The 07/03 fixed button: dark grey 54pt pill (never full black), white
/// text, Manrope 400 16pt. Pressed state lightens and scales ~0.97.
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
                    .fill(configuration.isPressed ? AppColor.buttonDarkPressed : AppColor.buttonDark)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - DrillButtonStyle

/// Lesson card + drill footer buttons (Commencer, Vérifier, Suivant, Terminer),
/// following the learner's `DrillStyle`:
/// - Plateau: a pale palette fill (capped saturation), ink text.
/// - Cadres: the dark grey pill with a pale palette disc holding `→`.
struct DrillButtonStyle: ButtonStyle {
    var height: CGFloat = 54

    func makeBody(configuration: Configuration) -> some View {
        DrillButtonBody(configuration: configuration, height: height)
    }
}

private struct DrillButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let height: CGFloat
    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    @AppStorage(DrillStyle.storageKey) private var styleID = DrillStyle.fallback.rawValue

    var body: some View {
        let theme = AppPalette(stored: paletteID).theme
        let pressed = configuration.isPressed
        Group {
            switch DrillStyle(stored: styleID) {
            case .plateau:
                configuration.label
                    .foregroundColor(AppColor.ink)
                    .padding(.horizontal, 22)
                    .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
                    .background(Capsule(style: .continuous).fill(Color(hex: theme.buttonFill)))
                    .overlay(Capsule(style: .continuous).fill(Color.black.opacity(pressed ? 0.06 : 0)))
            case .cadres:
                HStack {
                    configuration.label
                    Spacer(minLength: 8)
                    Text("→")
                        .font(.display(size: 17, wght: 400))
                        .foregroundColor(AppColor.ink)
                        .frame(width: height - 14, height: height - 14)
                        .background(Circle().fill(Color(hex: theme.buttonFill)))
                }
                .foregroundColor(AppColor.paper)
                .padding(.leading, 24)
                .padding(.trailing, 7)
                .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
                .background(Capsule(style: .continuous)
                    .fill(pressed ? AppColor.buttonDarkPressed : AppColor.buttonDark))
            }
        }
        .font(.display(size: 16, wght: 400))
        .scaleEffect(pressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: pressed)
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
