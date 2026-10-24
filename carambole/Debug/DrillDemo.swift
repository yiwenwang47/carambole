//
//  DrillDemo.swift
//  carambole
//
//  DEBUG-only simulator harness for checking a single drill card by eye.
//  Nothing here compiles into Release. See tools/sim/README.md.
//
//  Launch environment (simulator: prefix each with SIMCTL_CHILD_):
//  - CB_TEST_BOOK=1          root becomes a one-page "Test book" (also automatic
//                            in a build with bundle id wen.carambole.testbook, so
//                            it opens from the icon on the phone). Sessions:
//                            spot-the-error items (testbook_spot.json), long build
//                            drills for the second try, and — if CB_DRILL_DEMO is
//                            set — that drill, then the same card with
//                            CB_DRILL_HINT. For hand testing.
//  - CB_DRILL_DEMO=<id>      without CB_TEST_BOOK: open straight into that drill.
//  - CB_DRILL_HINT=<text>    override hint (on the 2nd card in the test book).
//  - CB_DRILL_PLACE=<n>      pre-place the first n answer tokens on the line.
//  - CB_DRILL_HINT_OPEN=1    start with the hint revealed.
//  - CB_DRILL_HINT_CYCLE=1   toggle the hint every 1.6 s (animation recording).
//  - CB_DRILL_CHECK=1        check the pre-placed answer after 0.8 s.
//  - CB_DRILL_TYPE=<text>    typing drill: pre-fill the field (wrap check).
//

#if DEBUG
import Foundation
import SwiftUI

enum DrillDemo {
    private static var env: [String: String] { ProcessInfo.processInfo.environment }

    static let testBookBundleID = "wen.carambole.testbook"
    static var isTestBook: Bool {
        env["CB_TEST_BOOK"] == "1" || Bundle.main.bundleIdentifier == testBookBundleID
    }

    /// Prototype items stored in the app's own `Exercise` shape.
    static func bundled(_ name: String) -> [Exercise] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Exercise].self, from: data)) ?? []
    }

    static var placeCount: Int { Int(env["CB_DRILL_PLACE"] ?? "") ?? 0 }
    static var hintOpen: Bool { env["CB_DRILL_HINT_OPEN"] == "1" }
    static var hintCycle: Bool { env["CB_DRILL_HINT_CYCLE"] == "1" }
    /// Build drill: after pre-placing, add one wrong tile and check (second-try state).
    static var autoRetry: Bool { env["CB_DRILL_RETRY"] == "1" }
    /// Build drill: check the pre-placed answer (CB_DRILL_PLACE = full length → weld).
    static var autoCheck: Bool { env["CB_DRILL_CHECK"] == "1" }
    /// Typing drill: text to pre-fill (checks how a long answer wraps).
    static var typedText: String? { env["CB_DRILL_TYPE"] }
    /// Spot drill states: "miss" (one wrong tap), "found", or an option index to pick.
    static var spotState: String? { env["CB_SPOT_STATE"] }

    /// The root replacement requested by the environment, or nil for the
    /// normal library.
    @MainActor
    static func rootView() -> AnyView? {
        if isTestBook {
            return AnyView(TestBookView())
        }
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
                     translation: ex.translation, hint: hint, explanationEN: ex.explanationEN,
                     spot: ex.spot)
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

    /// One element per drill, so a review session serves every one of them.
    static func session(_ title: String, _ exercises: [Exercise],
                        onFinish: @escaping () -> Void) -> DrillSessionView {
        let elements = exercises.enumerated().map { i, ex in
            GrammarElement(id: "tb_\(i)_\(ex.id)", moduleID: "tb", sortOrder: i,
                           label: title, ruleNote: "", examples: [ex])
        }
        return DrillSessionView(title: title, ruleNote: "", elements: elements, mode: .review,
                                onFinish: onFinish)
    }

    /// Spot-the-error items vetted offline (see docs/plans/2026-10-10-drill-types-design.md).
    static func spotExercises() -> [Exercise] {
        struct Item: Decodable {
            let exampleId: String
            let sentenceTokens: [String]
            let wrongIndex: Int
            let correctToken: String
            let options: [String]
            let translation: String?
            let explanation: String
            let explanationEN: String?
        }
        guard let url = Bundle.main.url(forResource: "testbook_spot", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([Item].self, from: data) else { return [] }
        return items.map { item in
            var answer = item.sentenceTokens
            answer[item.wrongIndex] = item.correctToken
            return Exercise(id: "spot_" + item.exampleId, elementID: item.exampleId, type: .fillBlank,
                            prompt: "Trouve l'erreur.", cue: nil, answerTokens: answer,
                            tokenBank: item.options, inputMode: .spotError,
                            explanation: item.explanation, translation: item.translation,
                            explanationEN: item.explanationEN,
                            spot: SpotError(tokens: item.sentenceTokens, wrongIndex: item.wrongIndex,
                                            options: item.options))
        }
    }

    /// Long build drills (≥ 7 words) spread over the book, for the second try.
    static func longBuilds(count: Int = 10) -> [Exercise] {
        let builds = ContentLoader.loadBook().allElements.flatMap(\.examples).filter {
            $0.resolvedInputMode == .buildFromTokens && $0.producibleAnswerTokens.count >= 7
        }
        guard !builds.isEmpty else { return [] }
        let step = max(1, builds.count / count)
        return stride(from: 0, to: builds.count, by: step).prefix(count).map { builds[$0] }
    }
}

/// One page: a button per test session; each relaunches as often as wanted.
private struct TestBookView: View {
    private enum Kind: Hashable, Identifiable {
        case spot, build, transform, interp, situation, demo
        var id: Self { self }
    }
    @State private var running: Kind?
    @State private var runID = 0
    private let spot = DrillDemo.spotExercises()
    private let builds = DrillDemo.longBuilds()
    private let transforms = DrillDemo.bundled("testbook_transform")
    private let interps = DrillDemo.bundled("testbook_interp")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Test book").font(.appPrompt).foregroundColor(AppColor.ink)
                row("Repérer l'erreur · \(spot.count)",
                    "Tap the wrong word, then pick its fix. A wrong tap counts as a miss.", .spot)
                row("Construire · deuxième essai",
                    "Long sentences. A first wrong check keeps the right start and gives one more try.", .build)
                row("Transformer · \(transforms.count)",
                    "Change one thing in a sentence; build only the part that changes.", .transform)
                row("Comprendre · \(interps.count)",
                    "Read a sentence, answer what only its grammar tells you. No English shown.", .interp)
                row("En situation · essai",
                    "Eight short café dialogues, six drill types. Tap any word for its English.", .situation)
                if ProcessInfo.processInfo.environment["CB_DRILL_DEMO"] != nil {
                    row("Lancer le drill", "Tap Indice, place words, scroll the word tray, check.", .demo)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(AppColor.paper.ignoresSafeArea())
        .onAppear {
            // Simulator harness: open a session straight away (CB_TB_OPEN=spot|build|…|demo).
            switch ProcessInfo.processInfo.environment["CB_TB_OPEN"] {
            case "spot": running = .spot
            case "build": running = .build
            case "transform": running = .transform
            case "interp": running = .interp
            case "situation": running = .situation
            case "demo": running = .demo
            default: break
            }
        }
        .fullScreenCover(item: $running) { kind in
            Group {
                switch kind {
                case .spot: DrillDemo.session("Repérer l'erreur", spot) { running = nil }
                case .build: DrillDemo.session("Deuxième essai", builds) { running = nil }
                case .transform: DrillDemo.session("Transformer", transforms) { running = nil }
                case .interp: DrillDemo.session("Comprendre", interps) { running = nil }
                case .situation: SituationPilotView { running = nil }
                case .demo: DrillDemo.makeSession(testBook: true)
                }
            }
            .id(runID)
        }
    }

    private func row(_ title: String, _ note: String, _ kind: Kind) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { runID += 1; running = kind } label: {
                Text(title).font(.appBody).foregroundColor(AppColor.ink)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Capsule().fill(AppColor.hairline))
            }
            .buttonStyle(.plain)
            Text(note).font(.appBody).foregroundColor(AppColor.g2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
#endif
