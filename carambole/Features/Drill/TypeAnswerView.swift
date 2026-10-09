//
//  TypeAnswerView.swift
//  carambole
//
//  Free-text typing input for `resolvedInputMode == .freeText`. The learner's
//  answer sits on the 07 baseline (one 1pt ink rule), in light Manrope. The field PREFERS the French keyboard (so accents are a long-press
//  away — é/è/ê via holding e, etc.) — the learner is expected to use the system
//  keyboard, so there is no accent shortcut bar. Answers are graded accent-strict
//  (see DrillEngine.normalize). Backed by a UITextField for caret-accurate editing.
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
                .frame(height: 40)
            Rectangle()
                .fill(AppColor.ink)
                .frame(height: 1)
                .padding(.top, 10)
            DrillFeedbackLine(result: result,
                              answer: Exercise.displayJoin(exercise.answerTokens))
                .padding(.top, 12)
        }
    }
}

// MARK: - UIKit-backed field (caret-accurate editing, French-preferred keyboard)

private struct TypingTextField: UIViewRepresentable {
    @Binding var text: String
    var isLocked: Bool
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let tf = FrenchPreferredTextField()
        tf.delegate = context.coordinator
        tf.placeholder = placeholder
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.spellCheckingType = .no
        tf.smartDashesType = .no
        tf.smartQuotesType = .no            // keep straight apostrophes
        tf.smartInsertDeleteType = .no
        tf.returnKeyType = .done
        tf.clearButtonMode = .whileEditing
        tf.font = Self.fieldFont
        tf.textColor = UIColor(AppColor.ink)
        tf.tintColor = UIColor(AppColor.ink)
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(AppColor.g3), .font: Self.fieldFont])
        tf.inputAccessoryView = context.coordinator.makeKeyboardBar()
        tf.addTarget(context.coordinator,
                     action: #selector(Coordinator.editingChanged(_:)),
                     for: .editingChanged)
        context.coordinator.textField = tf
        // Do NOT auto-raise the keyboard. Show the question first (with its
        // translation / Indice / Écouter chrome); the learner taps the field
        // ("Écris ta réponse…") to start typing, which raises the keyboard on demand.
        return tf
    }

    func updateUIView(_ tf: UITextField, context: Context) {
        // Refresh the stored binding every update: SwiftUI does not re-inject it
        // into an existing coordinator, so a captured-once binding could write into
        // a stale drill if this view were ever reused without an `.id` change.
        context.coordinator.text = $text
        if tf.text != text { tf.text = text }
        tf.isEnabled = !isLocked
        // Once the answer is checked, drop the keyboard so the result + footer are
        // clear and swiping to the previous drill doesn't fight a stale keyboard
        // (whose layout inset would otherwise scramble the neighbouring card).
        if isLocked && tf.isFirstResponder { tf.resignFirstResponder() }
        context.coordinator.textField = tf
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    /// 26pt Manrope 300 — the welded-sentence face from 07.
    static var fieldFont: UIFont {
        AppFonts.uiFont(AppFonts.manrope, size: 26, wght: 300)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        /// Stored (not `@Binding`) so `updateUIView` can re-point it at the current
        /// drill's binding — see the note in `updateUIView`.
        var text: Binding<String>
        weak var textField: UITextField?

        init(text: Binding<String>) { self.text = text }

        @objc func editingChanged(_ tf: UITextField) { text.wrappedValue = tf.text ?? "" }

        func textFieldShouldReturn(_ tf: UITextField) -> Bool {
            tf.resignFirstResponder()
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

        @objc func dismiss() { textField?.resignFirstResponder() }
    }
}

/// Prefers the French keyboard when the user has one enabled. iOS cannot install
/// a keyboard the user hasn't added (Settings → General → Keyboard → Keyboards),
/// so this is a preference, not a guarantee — it falls back to the system default.
private final class FrenchPreferredTextField: UITextField {
    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if let lang = mode.primaryLanguage, lang.hasPrefix("fr") {
                return mode
            }
        }
        return super.textInputMode
    }
}
