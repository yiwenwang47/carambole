//
//  TypeAnswerView.swift
//  carambole
//
//  Free-text typing input for `resolvedInputMode == .freeText`. The learner's
//  answer sits on the 07 baseline (one 1pt ink rule), in light Manrope. The field PREFERS the French keyboard (so accents are a long-press
//  away — é/è/ê via holding e, etc.) — the learner is expected to use the system
//  keyboard, so there is no accent shortcut bar. Answers are graded accent-strict
//  (see DrillEngine.normalize). Backed by a wrapping UITextView for caret-accurate editing.
//
//  Note: iOS cannot force-install a keyboard. The field returns the French input
//  mode when the user has a Français keyboard enabled (Settings → General →
//  Keyboard → Keyboards); otherwise it falls back to the system default.
//

import SwiftUI
import UIKit

struct TypeAnswerView: View {
    let exercise: Exercise
    /// The typed answer as a single-element array (or empty). Parent-owned, so the
    /// existing `hasAnswer` / Vérifier / banner / auto-advance plumbing is reused.
    @Binding var answer: [String]
    /// Locked after the answer is checked.
    var isLocked: Bool = false
    /// nil until checked; then whether the answer was right.
    var result: Bool? = nil

    /// Bridges `[String]` ⇄ the field's `String`. Stores the raw text (so mid-word
    /// spaces survive) but reports "no answer" when it is only whitespace.
    private var text: Binding<String> {
        Binding(
            get: { answer.first ?? "" },
            set: { newValue in
                let isBlank = newValue.trimmingCharacters(in: .whitespaces).isEmpty
                answer = isBlank ? [] : [newValue]
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TypingTextField(text: text, isLocked: isLocked,
                            placeholder: "Écris ta réponse…")
            Rectangle()
                .fill(AppColor.ink)
                .frame(height: 1)
                .padding(.top, 10)
            DrillFeedbackLine(result: result,
                              answer: Exercise.displayJoin(exercise.answerTokens))
                .padding(.top, 12)
        }
        #if DEBUG
        .task {
            // Simulator harness (DrillDemo, tools/sim): pre-fill the answer.
            if let typed = DrillDemo.typedText, answer.isEmpty { answer = [typed] }
        }
        #endif
    }
}

// MARK: - UIKit-backed field (caret-accurate editing, French-preferred keyboard)

/// A UITextView, not a UITextField: a field cuts long text with « … » when it
/// isn't focused, and dots are forbidden (user, 2026-10-24). This view wraps
/// instead and grows a line at a time; Return still dismisses (no newlines).
private struct TypingTextField: UIViewRepresentable {
    @Binding var text: String
    var isLocked: Bool
    var placeholder: String

    func makeUIView(context: Context) -> UITextView {
        let tv = FrenchPreferredTextView()
        tv.delegate = context.coordinator
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.spellCheckingType = .no
        tv.smartDashesType = .no
        tv.smartQuotesType = .no            // keep straight apostrophes
        tv.smartInsertDeleteType = .no
        tv.returnKeyType = .done
        tv.font = Self.fieldFont
        tv.textColor = UIColor(AppColor.ink)
        tv.tintColor = UIColor(AppColor.ink)
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false          // grow with the text instead of scrolling
        tv.textContainer.lineFragmentPadding = 0
        // One line sits centred in the old 40pt field height.
        let pad = max(0, (Self.minHeight - Self.fieldFont.lineHeight) / 2)
        tv.textContainerInset = UIEdgeInsets(top: pad, left: 0, bottom: pad, right: 0)
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.inputAccessoryView = context.coordinator.makeKeyboardBar()

        let ph = UILabel()
        ph.text = placeholder
        ph.font = Self.fieldFont
        ph.textColor = UIColor(AppColor.g3)
        ph.numberOfLines = 0
        ph.translatesAutoresizingMaskIntoConstraints = false
        tv.addSubview(ph)
        NSLayoutConstraint.activate([
            ph.leadingAnchor.constraint(equalTo: tv.leadingAnchor),
            ph.topAnchor.constraint(equalTo: tv.topAnchor, constant: pad),
            ph.widthAnchor.constraint(equalTo: tv.widthAnchor),
        ])
        context.coordinator.placeholder = ph
        context.coordinator.textView = tv
        // Do NOT auto-raise the keyboard. Show the question first (with its
        // translation / Indice / Écouter chrome); the learner taps the field
        // ("Écris ta réponse…") to start typing, which raises the keyboard on demand.
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        // Refresh the stored binding every update: SwiftUI does not re-inject it
        // into an existing coordinator, so a captured-once binding could write into
        // a stale drill if this view were ever reused without an `.id` change.
        context.coordinator.text = $text
        if tv.text != text { tv.text = text }
        context.coordinator.placeholder?.isHidden = !text.isEmpty
        tv.isEditable = !isLocked
        tv.isSelectable = !isLocked
        // Once the answer is checked, drop the keyboard so the result + footer are
        // clear and swiping to the previous drill doesn't fight a stale keyboard
        // (whose layout inset would otherwise scramble the neighbouring card).
        if isLocked && tv.isFirstResponder { tv.resignFirstResponder() }
        context.coordinator.textView = tv
    }

    /// Full proposed width; height = the wrapped text (or placeholder), never
    /// below one line.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView tv: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite else { return nil }
        var h = tv.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        if text.isEmpty, let ph = context.coordinator.placeholder {
            let phH = ph.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
            h = max(h, phH + tv.textContainerInset.top + tv.textContainerInset.bottom)
        }
        return CGSize(width: width, height: max(Self.minHeight, ceil(h)))
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    /// 26pt Manrope 300 — the welded-sentence face from 07.
    static var fieldFont: UIFont {
        AppFonts.uiFont(AppFonts.manrope, size: 26, wght: 300)
    }

    /// One line's height (the old fixed field height).
    static let minHeight: CGFloat = 40

    final class Coordinator: NSObject, UITextViewDelegate {
        /// Stored (not `@Binding`) so `updateUIView` can re-point it at the current
        /// drill's binding — see the note in `updateUIView`.
        var text: Binding<String>
        weak var textView: UITextView?
        weak var placeholder: UILabel?

        init(text: Binding<String>) { self.text = text }

        func textViewDidChange(_ tv: UITextView) {
            placeholder?.isHidden = !tv.text.isEmpty
            text.wrappedValue = tv.text
        }

        /// Return dismisses, as the field did; a pasted newline becomes a space.
        func textView(_ tv: UITextView, shouldChangeTextIn range: NSRange,
                      replacementText replacement: String) -> Bool {
            if replacement == "\n" {
                tv.resignFirstResponder()
                return false
            }
            if replacement.contains(where: \.isNewline) {
                let flat = replacement.map { $0.isNewline ? " " : String($0) }.joined()
                if let r = Range(range, in: tv.text) {
                    tv.text.replaceSubrange(r, with: flat)
                    textViewDidChange(tv)
                }
                return false
            }
            return true
        }

        /// A Done bar only — no accent shortcuts. The learner uses the system
        /// (ideally French) keyboard; Done dismisses so the Vérifier footer under
        /// the keyboard is reachable.
        func makeKeyboardBar() -> UIToolbar {
            let bar = UIToolbar()
            bar.sizeToFit()
            bar.items = [
                .flexibleSpace(),
                UIBarButtonItem(barButtonSystemItem: .done, target: self,
                                action: #selector(dismiss)),
            ]
            return bar
        }

        @objc func dismiss() { textView?.resignFirstResponder() }
    }
}

/// Prefers the French keyboard when the user has one enabled. iOS cannot install
/// a keyboard the user hasn't added (Settings → General → Keyboard → Keyboards),
/// so this is a preference, not a guarantee — it falls back to the system default.
private final class FrenchPreferredTextView: UITextView {
    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if let lang = mode.primaryLanguage, lang.hasPrefix("fr") {
                return mode
            }
        }
        return super.textInputMode
    }
}
