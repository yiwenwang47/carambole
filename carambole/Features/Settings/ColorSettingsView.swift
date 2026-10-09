//
//  ColorSettingsView.swift
//  carambole
//
//  "Couleurs" — pick one of the three palettes (design/palettes.html v4) and
//  how colour reaches the drills (Plateau or Cadres, design/drill-colour.html).
//  Opened from the library's `Couleurs →` label. The live 3D star at the top
//  takes the chosen palette's material and ring at once; each row shows the
//  palette's name, one line, and its three token states (new / review /
//  fragile) as real pills. The choice persists (`AppPalette.storageKey`) and
//  every screen follows it.
//

import SwiftUI

struct ColorSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    @AppStorage(DrillStyle.storageKey) private var drillStyleID = DrillStyle.fallback.rawValue
    @State private var star = ObjetStarController()

    private var selected: AppPalette { AppPalette(stored: paletteID) }

    var body: some View {
        ZStack(alignment: .top) {
            AppColor.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    Text("Couleurs")
                        .font(.display(size: 40, wght: 250))
                        .tracking(-1.2)
                        .foregroundColor(AppColor.ink)
                        .padding(.top, 30)
                        .accessibilityAddTraits(.isHeader)

                    // Preview: a sample ring (41 % maîtrisé, 12 % en cours).
                    ObjetStarView(mastered: 0.41, inProgress: 0.12, controller: star, palette: selected)
                        .frame(height: 300)
                        .padding(.horizontal, -Spacing.screenH)
                        .accessibilityHidden(true)

                    SectionLabel("Palette").padding(.bottom, 10)
                    Rectangle().fill(AppColor.ink).frame(height: 1)
                    ForEach(AppPalette.allCases) { palette in
                        row(palette)
                    }

                    SectionLabel("Exercices").padding(.top, 34).padding(.bottom, 10)
                    Rectangle().fill(AppColor.ink).frame(height: 1)
                    ForEach(DrillStyle.allCases) { style in
                        styleRow(style)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .swipeToGoBack { dismiss() }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Text("‹ Bibliothèque")
                    .uppercaseLabel(AppColor.ink)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -8)
            .accessibilityLabel("Retour")
            Spacer()
            Text("Réglages").uppercaseLabel()
        }
    }

    /// Name + line on the left, token pills under them; `Choisie` (ink pill) or
    /// `Choisir` on the right.
    private func row(_ palette: AppPalette) -> some View {
        let isOn = palette == selected
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            paletteID = palette.rawValue
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(palette.name)
                        .font(.display(size: 26, wght: isOn ? 400 : 250))
                        .tracking(-0.6)
                        .foregroundColor(AppColor.ink)
                    Spacer()
                    choiceTag(isOn)
                }
                Text(palette.blurb)
                    .font(.label(size: 13, wght: 400))
                    .foregroundColor(AppColor.graphite)
                TokenSample(theme: palette.theme)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle().fill(AppColor.hairline).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(palette.name). \(palette.blurb)")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

extension ColorSettingsView {
    /// `Choisie` (dark grey pill) or `Choisir` (outline).
    fileprivate func choiceTag(_ isOn: Bool) -> some View {
        Text(isOn ? "Choisie" : "Choisir")
            .uppercaseLabel(isOn ? AppColor.paper : AppColor.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(isOn ? AppColor.buttonDark : Color.clear))
            .overlay(Capsule().strokeBorder(isOn ? AppColor.buttonDark : AppColor.ink, lineWidth: 1))
    }

    /// One drill style: name, line, and a tiny sample in the current palette.
    fileprivate func styleRow(_ style: DrillStyle) -> some View {
        let isOn = style == DrillStyle(stored: drillStyleID)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            drillStyleID = style.rawValue
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(style.name)
                        .font(.display(size: 26, wght: isOn ? 400 : 250))
                        .tracking(-0.6)
                        .foregroundColor(AppColor.ink)
                    Spacer()
                    choiceTag(isOn)
                }
                Text(style.blurb)
                    .font(.label(size: 13, wght: 400))
                    .foregroundColor(AppColor.graphite)
                StyleSample(style: style, theme: AppPalette(stored: paletteID).theme)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle().fill(AppColor.hairline).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(style.name). \(style.blurb)")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Plateau: two words on a pale tray + a pale button. Cadres: a framed
/// `Indice` chip + a dark button with its pale disc.
private struct StyleSample: View {
    let style: DrillStyle
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 8) {
            switch style {
            case .plateau:
                HStack(spacing: 6) { word("demain"); word("partir") }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: theme.tint)))
                Text("Vérifier")
                    .font(.display(size: 12, wght: 400))
                    .foregroundColor(AppColor.ink)
                    .padding(.horizontal, 14).frame(height: 28)
                    .background(Capsule().fill(Color(hex: theme.buttonFill)))
            case .cadres:
                Text("INDICE")
                    .font(.label(size: 10, wght: 500)).tracking(1)
                    .foregroundColor(AppColor.ink)
                    .padding(.horizontal, 10).frame(height: 26)
                    .overlay(Capsule().strokeBorder(Color(hex: theme.fragile), lineWidth: 1.5))
                HStack(spacing: 8) {
                    Text("Vérifier").font(.display(size: 12, wght: 400)).foregroundColor(AppColor.paper)
                    Text("→").font(.display(size: 11, wght: 400)).foregroundColor(AppColor.ink)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color(hex: theme.buttonFill)))
                }
                .padding(.leading, 14).padding(.trailing, 4).frame(height: 28)
                .background(Capsule().fill(AppColor.buttonDark))
            }
        }
        .accessibilityHidden(true)
    }

    private func word(_ t: String) -> some View {
        Text(t)
            .font(.display(size: 12, wght: 400))
            .foregroundColor(AppColor.ink)
            .padding(.horizontal, 9).frame(height: 24)
            .background(Capsule().fill(AppColor.white))
            .overlay(Capsule().strokeBorder(AppColor.ink, lineWidth: 1))
    }
}

/// The three Today token states as small pills: new, review, fragile.
private struct TokenSample: View {
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 6) {
            pill("nouveau", fill: Color(hex: theme.tokenNew))
            pill("à réviser", fill: Color(hex: theme.tokenReview))
            Text("fragile")
                .font(.display(size: 12, wght: 400))
                .foregroundColor(AppColor.ink)
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(Capsule().fill(AppColor.white))
                .overlay(Capsule().strokeBorder(Color(hex: theme.fragile),
                                                style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])))
        }
        .accessibilityHidden(true)
    }

    private func pill(_ text: String, fill: Color) -> some View {
        Text(text)
            .font(.display(size: 12, wght: 400))
            .foregroundColor(AppColor.ink)
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(Capsule().fill(fill))
    }
}

/// Two short bars of a palette's loud and quiet colours (the library's
/// `Couleurs →` label).
struct PaletteStrip: View {
    let palette: AppPalette

    var body: some View {
        let t = palette.theme
        HStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: t.tokenNew))
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: t.tokenReview))
        }
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    NavigationStack { ColorSettingsView() }
}
#endif
