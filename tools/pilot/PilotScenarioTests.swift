import Foundation

@main
struct PilotScenarioTests {
    static func main() throws {
        let path = CommandLine.arguments.dropFirst().first ?? "carambole/Debug/testbook_situation.json"
        let reviewData = try Data(contentsOf: URL(fileURLWithPath: path))
        let review = try JSONDecoder().decode(PilotContent.self, from: reviewData)
        assert(review.validationErrors.isEmpty, review.validationErrors.joined(separator: "; "))
        assert(review.dialogues.count == 9)
        assert(review.dialogues.filter(\.isStandalone).count == 3)

        // The checks below use the approved v2 pilot cards as a fixed fixture,
        // so any review set can be validated above without matching their IDs.
        let fixturePath = CommandLine.arguments.dropFirst(2).first ?? "tools/pilot/fixtures/testbook_situation_v2.json"
        let data = try Data(contentsOf: URL(fileURLWithPath: fixturePath))
        let content = try JSONDecoder().decode(PilotContent.self, from: data)
        assert(content.validationErrors.isEmpty, content.validationErrors.joined(separator: "; "))

        // Longest phrase wins, typographic apostrophes match straight keys,
        // trailing punctuation stays outside the tappable word.
        let segs = PilotText.segments("Y a plus de croissants, du coup… pain au chocolat ?", glossary: content.glossary)
        assert(segs.map(\.key) == ["y a", "plus de", "croissants", "du coup", "pain au chocolat"])
        assert(segs.last?.trailing == "\u{00A0}?")
        assert(segs[2].display == "croissants" && segs[2].trailing == ",")
        let apos = PilotText.segments("On peut se tutoyer, non ?", glossary: content.glossary)
        assert(apos.first?.key == "on peut se tutoyer" && apos.first?.trailing == ",")

        // A gap may sit in a server line (Mot en retour).
        let back = content.dialogues.first { $0.id == "sit_06_solo_back_01" }!
        assert(back.gapTurnIndex == 0 && !back.turns[0].isLearner)
        assert(back.followUp == nil && back.followUpSpeaker == "Karim")

        // Follow-up voice: explicit speaker wins over the first named turn.
        let chat = content.dialogues.first { $0.id == "sit_06_cafe_groupchat_01" }!
        assert(chat.followUpSpeaker == "Théo")

        // Reply grading accepts every listed reply and nothing else.
        let usual = content.dialogues.first { $0.id == "sit_06_cafe_usual_01" }!
        let reply = usual.drills.first { $0.type == .reply }!
        assert(reply.accepts(["Oui,", "un", "grand", "café", "au soja,", "s'il vous plaît."]))
        assert(!reply.accepts(["Oui,", "un", "grande", "café", "au soja,", "s'il vous plaît."]))
        assert(reply.correctPrefixCount(["Oui,", "un", "grande"]) == 2)

        // Contract violations are caught.
        var broken = String(decoding: data, as: UTF8.self)
        broken = broken.replacingOccurrences(of: "\"correct\": 0,\n         \"miss\": \"Reread: « plus de",
                                             with: "\"correct\": 5,\n         \"miss\": \"Reread: « plus de")
        let bad = try JSONDecoder().decode(PilotContent.self, from: Data(broken.utf8))
        assert(bad.validationErrors.contains { $0.contains("correct out of range") })

        // A standalone drill never carries a follow-up.
        let solo = String(decoding: data, as: UTF8.self).replacingOccurrences(
            of: "\"standalone\": \"Transformer\",", with: "\"standalone\": \"Transformer\", \"followUp\": \"Oui.\",")
        let soloBad = try JSONDecoder().decode(PilotContent.self, from: Data(solo.utf8))
        assert(soloBad.validationErrors.contains { $0.contains("no follow-up") })

        print("PilotScenarioTests: PASS")
    }
}
