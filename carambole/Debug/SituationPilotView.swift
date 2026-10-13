#if DEBUG
import SwiftUI

/// Test book probe for Book 2: the current review set (`testbook_situation.json`)
/// played on the production session and card, so a review set looks and
/// behaves exactly like the book. Nothing is graded or saved. Simulator flags
/// use the `CB_PILOT_` prefix (`SituationSessionView.applyLaunchFlags`).
/// Reference mock: https://claude.ai/artifact/WisTx5oe1Jq5ZW3h6SL6gN
struct SituationPilotView: View {
    let onFinish: () -> Void

    private let content = Self.load()

    var body: some View {
        if let content {
            SituationSessionView(pilot: content.cards, words: content.words, audioPrefix: "pilot2_",
                                 onFinish: onFinish)
        } else {
            VStack(spacing: Spacing.md) {
                Text("Le pilote n'a pas pu être chargé.").font(.appPrompt)
                Button("Fermer", action: onFinish).buttonStyle(PrimaryButtonStyle())
            }
            .padding(Spacing.screenH)
        }
    }

    private struct Loaded {
        let cards: [SituationSessionView.Card]
        let words: [String: SituationWord]
    }

    /// The review set's dialogues as production items, each under a one-item
    /// element named after its `element` label.
    private struct ItemsFile: Decodable { let dialogues: [SituationItem] }

    private static func load() -> Loaded? {
        guard let url = Bundle.main.url(forResource: "testbook_situation", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let content = try? JSONDecoder().decode(PilotContent.self, from: data),
              let items = try? JSONDecoder().decode(ItemsFile.self, from: data).dialogues
        else { return nil }
        let errors = content.validationErrors + items.flatMap(\.validationErrors)
        if !errors.isEmpty {
            print("Situation pilot: \(errors.joined(separator: "; "))")
            return nil
        }
        let cards = zip(content.dialogues, items).enumerated().map { i, pair in
            let element = GrammarElement(id: "pilot_\(pair.0.id)", moduleID: "pilot", sortOrder: i,
                                         label: pair.0.element, ruleNote: "", examples: [], items: [pair.1])
            return SituationSessionView.Card(element: element, item: pair.1, salt: 0)
        }
        // Glosses keep their `* ` spoken mark, which the tooltip shows as is.
        let words = content.glossary.reduce(into: [String: SituationWord]()) { out, entry in
            out[entry.key] = SituationWord(fr: entry.key, en: entry.value, spoken: false, audio: nil, firstSeen: nil)
        }
        return Loaded(cards: cards, words: words)
    }
}
#endif
