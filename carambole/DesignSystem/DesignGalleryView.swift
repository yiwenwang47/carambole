//
//  DesignGalleryView.swift
//  carambole
//
//  Visual showcase of the "objets + mouvement" tokens for review.
//  Not wired into app navigation — screenshot in isolation.
//

import SwiftUI

struct DesignGalleryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                paletteSection
                typeSection
                weightSection
                tileSection
                buttonSection
                ringSection
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, 72)
            .padding(.bottom, Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColor.paper.ignoresSafeArea())
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("Carambole · objets et mouvement")
            Text("Système")
                .font(.display(size: 40, wght: 250))
                .tracking(-0.8)
                .foregroundColor(AppColor.ink)
        }
    }

    // MARK: Palette

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Palette")
            HStack(spacing: Spacing.sm) {
                ForEach(Self.swatches, id: \.name) { swatch in
                    VStack(alignment: .leading, spacing: 6) {
                        Rectangle()
                            .fill(swatch.color)
                            .frame(height: 44)
                            .overlay(Rectangle().stroke(AppColor.hairline, lineWidth: 1))
                        Text(swatch.name).uppercaseLabel(AppColor.ink)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private static let swatches: [(name: String, color: Color)] = [
        ("paper", AppColor.paper),
        ("ink", AppColor.ink),
        ("g1", AppColor.graphite),
        ("g2", AppColor.g2),
        ("g3", AppColor.g3),
        ("g4", AppColor.hairline),
    ]

    // MARK: Type

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Typographie")
            Text("41 %").font(.display(size: 44, wght: 200)).tracking(-1.8)
            Text("« I’m going to leave tomorrow. »").font(.appPrompt).tracking(-0.7)
            Text("Les articles définis").font(.appTitle).tracking(-0.5)
            Text("Le, la, les devant un nom défini.").font(.appBody).foregroundColor(AppColor.graphite)
            Text("128 / 312 maîtrisés").uppercaseLabel()
            Text("Apprendre →").uppercaseLabel(AppColor.ink)
        }
        .foregroundColor(AppColor.ink)
    }

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("Axe wght · 200 → 800")
            HStack(spacing: 10) {
                ForEach([200, 300, 400, 500, 600, 720, 800], id: \.self) { w in
                    Text("a").font(.display(size: 30, wght: CGFloat(w)))
                }
            }
            .foregroundColor(AppColor.ink)
        }
    }

    // MARK: Tiles (07 magnets)

    private var tileSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Aimants")
            HStack(spacing: 10) {
                tile("Je", style: .bank)
                tile("vais", style: .placed)
                tile("va", style: .wrong)
            }
        }
    }

    private enum TileStyle { case bank, placed, wrong }

    private func tile(_ text: String, style: TileStyle) -> some View {
        Text(text)
            .font(.appToken)
            .foregroundColor(style == .placed ? AppColor.paper : AppColor.ink)
            .padding(.horizontal, 15)
            .frame(height: 40)
            .background(Capsule().fill(style == .placed ? AppColor.ink : AppColor.white))
            .overlay(
                Capsule().strokeBorder(
                    AppColor.ink,
                    style: StrokeStyle(lineWidth: 1, dash: style == .wrong ? [4, 3] : [])
                )
            )
    }

    // MARK: Button

    private var buttonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Bouton")
            Button("Vérifier") {}
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    // MARK: Ring

    private var ringSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Anneau")
            HStack(spacing: Spacing.lg) {
                ProgressRing(progress: 0.35)
                ProgressRing(progress: 0.6, size: 18, lineWidth: 2.5)
            }
        }
    }
}

#Preview {
    DesignGalleryView()
}
