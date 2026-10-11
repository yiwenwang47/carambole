import Foundation

@main
struct PilotScenarioTests {
    static func main() throws {
        let path = CommandLine.arguments.dropFirst().first ?? "carambole/Debug/testbook_situation.json"
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let content = try JSONDecoder().decode(PilotContent.self, from: data)
        assert(content.validationErrors.isEmpty, content.validationErrors.joined(separator: "; "))
        assert(content.dialogues.count == 8)

        // Every drill type appears at least once.
        let kinds = Set(content.dialogues.flatMap { $0.drills.map(\.type) })
        assert(kinds == [.comprehend, .reply, .pick, .complete, .fix, .word])

        // Longest phrase wins, typographic apostrophes match straight keys,
        // trailing punctuation stays outside the tappable word.
        let segs = PilotText.segments("Le sandwich ? Ça prend un quart d’heure.", glossary: content.glossary)
        assert(segs.map(\.display) == ["Le", "sandwich", "?", "Ça", "prend", "un quart d’heure"])
        assert(segs.last?.key == "un quart d'heure" && segs.last?.trailing == ".")
        assert(segs[2].key == nil)

        let gap = PilotText.segments("Un ___, s’il vous plaît.", glossary: content.glossary)
        assert(gap.map(\.kind) == [.word, .gap, .word])
        assert(gap[1].trailing == "," && gap[2].key == "s'il vous plaît")

        // Reply grading accepts every listed reply and nothing else.
        let ready = content.dialogues.first { $0.id == "sit_06_cafe_ready_01" }!
        let reply = ready.drills.first { $0.type == .reply }!
        assert(reply.accepts(["Alors,", "la", "salade,", "s’il vous plaît."]))
        assert(reply.accepts(["la", "salade,", "s’il vous plaît."]))
        assert(!reply.accepts(["le", "sandwich,", "s’il vous plaît."]))

        // Contract violations are caught.
        var broken = String(decoding: data, as: UTF8.self)
        broken = broken.replacingOccurrences(of: "\"correct\": 0,\n         \"miss\": \"Reread: « plus de",
                                             with: "\"correct\": 5,\n         \"miss\": \"Reread: « plus de")
        let bad = try JSONDecoder().decode(PilotContent.self, from: Data(broken.utf8))
        assert(bad.validationErrors.contains { $0.contains("correct out of range") })

        print("PilotScenarioTests: PASS")
    }
}
