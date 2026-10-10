//
//  DrillDemo.swift
//  carambole
//
//  DEBUG-only simulator harness for checking a single drill card by eye.
//  Nothing here compiles into Release. See tools/sim/README.md.
//
//  Launch environment (simulator: prefix each with SIMCTL_CHILD_):
//  - CB_TEST_BOOK=1          root becomes a one-page "Test book" whose button
//                            opens a session of the CB_DRILL_DEMO drill (default
//                            el_si_synthese_01): its own hint, then the same
//                            card with CB_DRILL_HINT (if set). For hand testing.
//  - CB_DRILL_DEMO=<id>      without CB_TEST_BOOK: open straight into that drill.
//  - CB_DRILL_HINT=<text>    override hint (on the 2nd card in the test book).
//  - CB_DRILL_PLACE=<n>      pre-place the first n answer tokens on the line.
//  - CB_DRILL_HINT_OPEN=1    start with the hint revealed.
//  - CB_DRILL_HINT_CYCLE=1   toggle the hint every 1.6 s (animation recording).
//

#if DEBUG
import Foundation
import SwiftUI

enum DrillDemo {
    private static var env: [String: String] { ProcessInfo.processInfo.environment }

    static var placeCount: Int { Int(env["CB_DRILL_PLACE"] ?? "") ?? 0 }
    static var hintOpen: Bool { env["CB_DRILL_HINT_OPEN"] == "1" }
    static var hintCycle: Bool { env["CB_DRILL_HINT_CYCLE"] == "1" }

    /// The root replacement requested by the environment, or nil for the
    /// normal library.
    @MainActor
    static func rootView() -> AnyView? {
        if env["CB_TEST_BOOK"] == "1" { return AnyView(TestBookView()) }
        guard env["CB_DRILL_DEMO"] != nil, let session = makeSession(testBook: false) else { return nil }
        return AnyView(session)
    }

    @MainActor
    static func makeSession(testBook: Bool) -> DrillSessionView? {
        let id = env["CB_DRILL_DEMO"] ?? "el_si_synthese_01"
        let book = ContentLoader.loadBook()
        guard var element = book.allElements.first(where: { el in el.examples.contains { $0.id == id } }),
              let ex = element.examples.first(where: { $0.id == id }) else { return nil }
        func copy(_ suffix: String, hint: String?) -> Exercise {
            Exercise(id: ex.id + suffix, elementID: ex.elementID, type: ex.type, prompt: ex.prompt,
                     cue: ex.cue, answerTokens: ex.answerTokens, tokenBank: ex.tokenBank,
                     inputMode: ex.inputMode, explanation: ex.explanation,
                     translation: ex.translation, hint: hint, explanationEN: ex.explanationEN)
        }
        let override = env["CB_DRILL_HINT"].map { $0.replacingOccurrences(of: "\\n", with: "\n") }
        if testBook {
            element.examples = [copy("", hint: ex.hint)] + (override.map { [copy("_alt", hint: $0)] } ?? [])
        } else {
            element.examples = [copy("", hint: override ?? ex.hint)]
        }
        // Review mode, no rule note → no Leçon card; straight into the drill.
        return DrillSessionView(title: element.label, ruleNote: "", elements: [element], mode: .review)
    }
}

/// One page, one button: relaunch the demo drill as often as wanted.
private struct TestBookView: View {
    @State private var running = false
    @State private var runID = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Test book").font(.appPrompt).foregroundColor(AppColor.ink)
            Text("Tap Indice, place words, scroll the word tray, check.")
                .font(.appBody).foregroundColor(AppColor.g2)
            Button { runID += 1; running = true } label: {
                Text("Lancer le drill").font(.appBody).foregroundColor(AppColor.ink)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Capsule().fill(AppColor.hairline))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColor.paper.ignoresSafeArea())
        .fullScreenCover(isPresented: $running) {
            DrillDemo.makeSession(testBook: true).id(runID)
        }
    }
}
#endif
