//
//  TypeAnswerView.swift
//  carambole
//
//  Free-text typing input for `resolvedInputMode == .freeText`. A "Le Cahier"
//  writing line: the learner's rounded serif-ish answer sits on a single ink
//  underline, with an accent toolbar above the keyboard so é/è/à/ç… are one tap
//  (answers are graded accent-strict — see DrillEngine.normalize). Backed by a
//  UITextField so accent taps insert at the CARET, not the end of the string.
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
        VStack(alignment: .leading, spacing: Spacing.sm) {
            AccentTextField(text: text, isLocked: isLocked,
                            placeholder: "Écris ta réponse…")
                .frame(height: 40)
            Rectangle()
                .fill(isLocked ? AppColor.hairline : AppColor.ink)
                .frame(height: 1.5)
        }
    }
}

// MARK: - UIKit-backed field (caret-accurate accent insertion)

private struct AccentTextField: UIViewRepresentable {
    @Binding var text: String
    var isLocked: Bool
    var placeholder: String

    /// Common French accented letters, in roughly descending frequency.
    static let accents = ["é", "è", "ê", "à", "â", "ç", "ù", "û", "î", "ô"]

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
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
        tf.font = Self.roundedFont
        tf.textColor = UIColor(AppColor.ink)
        tf.tintColor = UIColor(AppColor.saffronDeep)
        tf.inputAccessoryView = context.coordinator.makeAccentBar()
        tf.addTarget(context.coordinator,
                     action: #selector(Coordinator.editingChanged(_:)),
                     for: .editingChanged)
        context.coordinator.textField = tf
        // A typing drill should be immediately writable — raise the keyboard (and
        // the accent bar) on appear, exactly like tapping a token/choice is instant.
        if !isLocked {
            DispatchQueue.main.async { tf.becomeFirstResponder() }
        }
        return tf
    }

    func updateUIView(_ tf: UITextField, context: Context) {
        // Refresh the stored binding every update: SwiftUI does not re-inject it
        // into an existing coordinator, so a captured-once binding could write into
        // a stale drill if this view were ever reused without an `.id` change.
        context.coordinator.text = $text
        if tf.text != text { tf.text = text }
        tf.isEnabled = !isLocked
        context.coordinator.textField = tf
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    /// ≈24pt rounded — matches the token / choice input family (`.appToken`).
    static var roundedFont: UIFont {
        let base = UIFont.systemFont(ofSize: 24, weight: .medium)
        guard let d = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: d, size: 24)
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

        func makeAccentBar() -> UIToolbar {
            let bar = UIToolbar()
            bar.sizeToFit()
            let letterFont = UIFont(descriptor:
                UIFont.systemFont(ofSize: 20, weight: .medium).fontDescriptor,
                size: 20)
            var items: [UIBarButtonItem] = []
            for a in AccentTextField.accents {
                let b = UIBarButtonItem(title: a, style: .plain, target: self,
                                        action: #selector(insertAccent(_:)))
                b.setTitleTextAttributes([.font: letterFont], for: .normal)
                items.append(b)
            }
            items.append(.flexibleSpace())
            items.append(UIBarButtonItem(barButtonSystemItem: .done, target: self,
                                         action: #selector(dismiss)))
            bar.items = items
            return bar
        }

        @objc func insertAccent(_ sender: UIBarButtonItem) {
            guard let tf = textField, let ch = sender.title else { return }
            tf.insertText(ch)               // inserts at the caret (UIKeyInput)
            text.wrappedValue = tf.text ?? ""
        }

        @objc func dismiss() { textField?.resignFirstResponder() }
    }
}
