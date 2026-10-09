//
//  ProgressRing.swift
//  carambole
//
//  Circular progress ring: a palette-coloured arc over a g3 track (motion.html ring7).
//  Animatable on `progress`.
//

import SwiftUI

/// A circular progress ring — palette `ring` arc over a `g3` track.
/// `progress` is clamped to 0...1.
struct ProgressRing: View {
    /// A value between 0 and 1 representing progress.
    let progress: Double
    var size: CGFloat = 30
    var lineWidth: CGFloat = 3
    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue

    private var clamped: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            // Track ring.
            Circle()
                .stroke(AppColor.g3, lineWidth: lineWidth)

            // Progress arc.
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    Color(hex: AppPalette(stored: paletteID).theme.ring),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // Start at top.
                .animation(.easeInOut(duration: 0.3), value: clamped)
        }
        .frame(width: size, height: size)
    }
}
