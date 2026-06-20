//
//  SwipeBackModifier.swift
//  carambole
//
//  A horizontal "swipe to go back" gesture for the pushed full-screens whose
//  native back button is hidden (BookView, HistoryView). Direction matches the
//  iOS system back-swipe: a RIGHTWARD drag (finger moves right, content slides
//  back) invokes the action. Attached via `simultaneousGesture` so vertical
//  scrolling still works; only a horizontally-dominant drag past the threshold
//  counts, so it never fires on a normal scroll.
//

import SwiftUI

struct SwipeToGoBack: ViewModifier {
    /// When false the modifier is a no-op (e.g. BookView shown as a root).
    var enabled: Bool = true
    /// Minimum horizontal travel before the swipe counts.
    var threshold: CGFloat = 60
    let action: () -> Void

    func body(content: Content) -> some View {
        if enabled {
            content.simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        let h = value.translation.width
                        let v = value.translation.height
                        // Horizontally dominant, rightward, past the threshold.
                        guard abs(h) > abs(v), h > threshold else { return }
                        action()
                    }
            )
        } else {
            content
        }
    }
}

extension View {
    /// Rightward swipe (the iOS back-swipe direction) invokes `action`. Use on the
    /// pushed full-screens whose native back button is hidden.
    func swipeToGoBack(enabled: Bool = true,
                       perform action: @escaping () -> Void) -> some View {
        modifier(SwipeToGoBack(enabled: enabled, action: action))
    }
}
