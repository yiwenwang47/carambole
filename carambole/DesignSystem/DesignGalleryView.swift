//
//  DesignGalleryView.swift
//  carambole
//
//  Visual showcase of the "Le Cahier" design system for review.
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
                labelSection
                buttonSection
                chipSection
                ringSection
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, 72) // Generous top whitespace.
            .padding(.bottom, Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColor.paper.ignoresSafeArea())
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("Le Cahier")
            Text("Design System")
                .font(.appPrompt)
                .foregroundColor(AppColor.ink)
        }
    }

    // MARK: Palette

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Palette")
            VStack(spacing: Spacing.sm) {
                ForEach(Self.swatches, id: \.name) { swatch in
                    HStack(spacing: Spacing.md) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(swatch.color)
                            .frame(width: 44, height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(AppColor.hairline, lineWidth: 1)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(swatch.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppColor.ink)
                            Text(swatch.hex)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(AppColor.graphite)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private static let swatches: [(name: String, hex: String, color: Color)] = [
        ("paper", "#FAF7F0", AppColor.paper),
        ("ink", "#14110E", AppColor.ink),
        ("graphite", "#6B655C", AppColor.graphite),
        ("saffron", "#FFB879", AppColor.saffron),
        ("saffronDeep", "#E8915C", AppColor.saffronDeep),
        ("success", "#5B8C5A", AppColor.success),
        ("error", "#C0563F", AppColor.error),
        ("hairline", "#E2DBCD", AppColor.hairline),
    ]

    // MARK: Typography

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionLabel("Typography")

            typeSample("appPrompt", font: .appPrompt) {
                Text("Elle est arrivée")
                    .font(.appPrompt)
                    .foregroundColor(AppColor.ink)
            }
            typeSample("appTitle", font: .appTitle) {
                Text("Le passé composé")
                    .font(.appTitle)
                    .foregroundColor(AppColor.ink)
            }
            typeSample("appToken", font: .appToken) {
                Text("arrivée")
                    .font(.appToken)
                    .foregroundColor(AppColor.ink)
            }
            typeSample("appLabel", font: .appLabel) {
                Text("conjugaison")
                    .uppercaseLabel()
            }
            typeSample("appExplain", font: .appExplain) {
                Text("Avec être, le participe s'accorde avec le sujet.")
                    .font(.appExplain)
                    .foregroundColor(AppColor.ink)
            }
        }
    }

    @ViewBuilder
    private func typeSample<Content: View>(
        _ name: String,
        font: Font,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(AppColor.graphite)
            content()
        }
    }

    // MARK: Section Label

    private var labelSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Section Label")
            SectionLabel("Search")
        }
    }

    // MARK: Buttons

    private var buttonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Primary Button")
            Button("Commencer") {}
                .buttonStyle(PrimaryButtonStyle())
            // Second button forced into its pressed appearance for review.
            Button("Pressed") {}
                .buttonStyle(PressedPreviewButtonStyle())
        }
    }

    // MARK: Chips (gallery-local only — real TokenTile is built later)

    private var chipSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Tokens")
            HStack(spacing: Spacing.sm) {
                GalleryChip(text: "est")
                GalleryChip(text: "arrivée")
                GalleryChip(text: "hier")
            }
        }
    }

    // MARK: Progress Ring

    private var ringSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Progress Ring")
            ProgressRing(progress: 0.6)
        }
    }
}

// MARK: - Gallery-local helpers

/// A simple rounded chip — LOCAL to the gallery only. The reusable `TokenTile`
/// is built in a later task; this is just for visual review here.
private struct GalleryChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.appToken)
            .foregroundColor(AppColor.ink)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColor.paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppColor.ink, lineWidth: 1)
                    )
            )
    }
}

/// Renders `PrimaryButtonStyle` permanently in its pressed look so the gallery
/// can show both states side by side. Gallery-local only.
private struct PressedPreviewButtonStyle: ButtonStyle {
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
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColor.saffronDeep)
            )
            .scaleEffect(0.96)
    }
}

#Preview {
    DesignGalleryView()
}
