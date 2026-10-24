//
//  TooEasy.swift
//  carambole
//
//  "Trop facile" — shared by every book (HARD RULE: every book offers it, with
//  this one learning logic). The learner arms the gate on a card, then must
//  still answer it: a clean answer grades the element .easy and suspends it
//  (instant maîtrisé, gone for good, with an undo pill); anything else cleans
//  the element's records (back to fresh, re-markable). Either way the session
//  moves on to the next element. Book 1: `DrillView` / `DrillSessionView`.
//  Book 2: `SituationCardView` / `SituationSessionView` — armed on one drill,
//  resolved by that drill; the card's other drills grade normally.
//  *Mots*: `VocabSessionView` — no `TooEasyControl`; swipe up (or a clean right
//  swipe on a word armed on the Leçon page) resolves the gate.
//

import SwiftUI

// MARK: - Learning logic

enum TooEasyGate {
    /// Resolve an armed gate for `elementID`. `removed` = answered cleanly
    /// (Book 1: right first time with no missed tap; Book 2: the armed drill
    /// right first time). Correct → grade .easy so S/D advance, THEN
    /// suspend (`setSuspended` stamps the sticky graduation). Wrong → delete the
    /// element's review row (fresh/unseen again).
    static func resolve(elementID: String, exampleID: String, removed: Bool, now: Date = Date(),
                        graduationGate: ((ReviewStatus) -> Bool)? = nil) {
        if removed {
            ElementGrader.grade(elementID: elementID, exampleID: exampleID, rating: .easy, now: now,
                                graduationGate: graduationGate)
            DataManager.shared.setSuspended(elementID: elementID)
        } else {
            DataManager.shared.clearReviewStatus(elementID: elementID)
        }
    }
}

// MARK: - Arm control

/// Sits just above the footer button before the card is answered. Tapping
/// "Trop facile" arms the answer-once gate; while armed it shows a reminder +
/// an Annuler escape. The remove/clean happens when the card is answered.
struct TooEasyControl: View {
    @Binding var pending: Bool
    /// False once an armed card has a miss: it can no longer remove, and its
    /// clean is due, so the line turns read-only (no Annuler escape).
    var canCancel = true

    var body: some View {
        if pending && !canCancel {
            Text("Raté — remis à zéro")
                .uppercaseLabel(AppColor.ink)
                .lineLimit(1)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
        } else if pending {
            HStack(spacing: Spacing.sm) {
                Text("Réponds correctement pour le retirer")
                    .uppercaseLabel(AppColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: Spacing.sm)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        pending = false
                    }
                } label: {
                    Text("Annuler").uppercaseLabel(AppColor.ink).underline()
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity)
        } else {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    pending = true
                }
            } label: {
                Text("Trop facile — retirer")
                    .uppercaseLabel()
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Undo pill

extension View {
    /// Passive undo pill after a too-easy removal: "Marqué trop facile" +
    /// "Annuler" (demotes `elementID` back to en-cours). Floats at the top, just
    /// under the session's ✕ row, so it never covers the card's footer. Swipe up
    /// or wait ~4.5 s to dismiss. Bump `token` on each removal to restart the timer.
    /// `onUndo` runs after « Annuler » demotes the element (*Mots* moves the
    /// word from its trop facile count to known); Books 1 and 2 pass nothing.
    /// `edge: .bottom` floats it 40 pt above the bottom instead (*Mots*: its
    /// top holds the big count and its bottom is empty; mock `.pill`).
    func tooEasyUndo(elementID: Binding<String?>, token: Int, edge: VerticalEdge = .top,
                     onUndo: (() -> Void)? = nil) -> some View {
        modifier(TooEasyUndoModifier(elementID: elementID, token: token, edge: edge, onUndo: onUndo))
    }
}

private struct TooEasyUndoModifier: ViewModifier {
    @Binding var elementID: String?
    let token: Int
    var edge: VerticalEdge = .top
    var onUndo: (() -> Void)?
    /// Upward drag on the pill; it follows the finger until it dismisses.
    @State private var drag: CGFloat = 0

    func body(content: Content) -> some View {
        ZStack {
            content
            // The surrounding VStack/Spacer is hit-transparent (only the pill
            // takes touches) so the live card underneath stays interactive.
            if elementID != nil, edge == .top {
                VStack {
                    pill
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.top, 48)   // clear the exit-bar (✕) row above
                    Spacer().allowsHitTesting(false)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if elementID != nil {
                VStack {
                    Spacer().allowsHitTesting(false)
                    pill
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .transition(.offset(y: 20).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: elementID)
        // Keyed on the token so a fresh removal restarts the timer (and cancels
        // the prior one); cancellation silently aborts the sleep.
        .task(id: token) {
            guard elementID != nil else { return }
            try? await Task.sleep(nanoseconds: 4_500_000_000)
            if !Task.isCancelled { elementID = nil }
        }
        .onChange(of: token) { _, _ in drag = 0 }
    }

    private var pill: some View {
        HStack(spacing: Spacing.md) {
            Text("Marqué trop facile")
                .font(.display(size: 15, wght: 400))
                .foregroundColor(AppColor.paper)
                .lineLimit(1)

            Rectangle()
                .fill(AppColor.paper.opacity(0.25))
                .frame(width: 1, height: 16)

            Button(action: undo) {
                Text("Annuler")
                    .uppercaseLabel(AppColor.paper)
                    .underline()
                    .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Annuler · remettre en cours")
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: edge == .bottom ? .infinity : nil)
        .frame(height: 48)
        .background(Capsule().fill(AppColor.buttonDark))
        .offset(y: drag)
        // Swipe up dismisses the moment the drag passes a short threshold,
        // without waiting for the finger to lift. A tap still reaches Annuler.
        .gesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    guard elementID != nil else { return }
                    drag = min(0, value.translation.height)
                    if value.translation.height < -24 { elementID = nil }
                }
                .onEnded { _ in
                    // Kept as-is once dismissed, so the pill leaves from where it is.
                    guard elementID != nil else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { drag = 0 }
                }
        )
        .accessibilityAction(named: "Fermer") { elementID = nil }
    }

    /// Demote the just-removed element back to en-cours, then hide the pill.
    /// The session has already moved past it; the demote is a pure data op.
    private func undo() {
        if let id = elementID {
            DataManager.shared.demote(elementID: id)
            onUndo?()
        }
        elementID = nil
    }
}
