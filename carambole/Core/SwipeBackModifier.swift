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
//  A sideways drag never starts the ScrollView's scroll, so a row `Button`
//  under the finger is not cancelled and fires on lift-off. Rows check
//  a `SwipeBackGuard` and ignore the tap while a drag is (or just was) live.
//

import SwiftUI

/// Set while a horizontal drag is in flight on a `swipeToGoBack` screen.
/// The screen owns it (`@State`), passes it to `swipeToGoBack(guard:)`, and
/// its row buttons skip their action while `dragging`.
final class SwipeBackGuard {
    fileprivate(set) var dragging = false
    fileprivate var resetToken = 0
}

struct SwipeToGoBack: ViewModifier {
    /// When false the modifier is a no-op (e.g. BookView shown as a root).
    var enabled: Bool = true
    /// Minimum horizontal travel before the swipe counts.
    var threshold: CGFloat = 60
    var swipeGuard: SwipeBackGuard?
    let action: () -> Void

    func body(content: Content) -> some View {
        if enabled {
            content.simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            swipeGuard?.dragging = true
                        }
                    }
                    .onEnded { value in
                        if let swipeGuard {
                            // Cleared a beat later: the row Button's action
                            // runs on the same lift-off, before or after this.
                            swipeGuard.resetToken += 1
                            let token = swipeGuard.resetToken
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if swipeGuard.resetToken == token { swipeGuard.dragging = false }
                            }
                        }
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
    /// Pass `guard` when the screen has tappable rows: they should ignore the
    /// lift-off of a sideways drag (see `SwipeBackGuard`).
    func swipeToGoBack(enabled: Bool = true, guard swipeGuard: SwipeBackGuard? = nil,
                       perform action: @escaping () -> Void) -> some View {
        modifier(SwipeToGoBack(enabled: enabled, swipeGuard: swipeGuard, action: action))
    }
}
