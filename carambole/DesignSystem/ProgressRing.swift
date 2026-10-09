//
//  ProgressRing.swift
//  carambole
//
//  Circular progress ring: an ink arc over a g3 track (motion.html ring7).
//  Animatable on `progress`.
//

import SwiftUI

/// A circular progress ring — `ink` arc over a `g3` track.
/// `progress` is clamped to 0...1.
struct ProgressRing: View {
    /// A value between 0 and 1 representing progress.
    let progress: Double
    var size: CGFloat = 30
    var lineWidth: CGFloat = 3

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
                    AppColor.ink,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // Start at top.
                .animation(.easeInOut(duration: 0.3), value: clamped)
        }
        .frame(width: size, height: size)
    }
}
