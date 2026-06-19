//
//  ProgressRing.swift
//  carambole
//
//  Fresh circular progress view for the new drill UI: a saffron progress
//  stroke over a hairline track ring. Animatable on `progress`.
//

import SwiftUI

/// A circular progress ring — `saffron` arc over a `hairline` track.
/// `progress` is clamped to 0...1.
struct ProgressRing: View {
    /// A value between 0 and 1 representing progress.
    let progress: Double
    var size: CGFloat = 40
    var lineWidth: CGFloat = 5

    private var clamped: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            // Track ring.
            Circle()
                .stroke(AppColor.hairline, lineWidth: lineWidth)

            // Progress arc.
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AppColor.saffron,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // Start at top.
                .animation(.easeInOut(duration: 0.3), value: clamped)
        }
        .frame(width: size, height: size)
    }
}
