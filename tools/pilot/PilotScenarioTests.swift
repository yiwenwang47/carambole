import Foundation

@main
struct PilotScenarioTests {
    static func main() throws {
        let json = """
        {
          "id": "case-1",
          "context": "A train leaves soon.",
          "turns": [{"speaker":"Cliente","text":"Bonjour."},{"speaker":"Serveur","text":"C'est prêt."}],
          "question": "What is ready?",
          "choices": ["The drink", "The food", "Nothing"],
          "correctChoice": 0,
          "responsePrompt": "Accept the drink.",
          "replyTokens": ["Je prends", "le café", "s'il vous plaît."],
          "tokenBank": ["Je prends", "le café", "s'il vous plaît.", "le thé"],
          "acceptedReplies": [
            ["Je prends", "le café", "s'il vous plaît."],
            ["le café", "s'il vous plaît."]
          ],
          "modelReply": "Je prends le café, s'il vous plaît.",
          "followUp": "Très bien.",
          "explanationEN": "The coffee is ready."
        }
        """
        let scenario = try JSONDecoder().decode(PilotScenario.self, from: Data(json.utf8))
        assert(scenario.validationErrors.isEmpty)
        assert(scenario.accepts(["Je prends", "le café", "s'il vous plaît."]))
        assert(scenario.accepts(["le café", "s'il vous plaît."]))
        assert(!scenario.accepts(["Je prends", "le thé", "s'il vous plaît."]))
        assert(!scenario.accepts(["le café"]))
        assert(scenario.replyText(["Je prends", "le café", "s'il vous plaît."])
               == "Je prends le café s'il vous plaît.")

        let invalid = json.replacingOccurrences(of: "\"correctChoice\": 0",
                                                 with: "\"correctChoice\": 4")
        let badScenario = try JSONDecoder().decode(PilotScenario.self, from: Data(invalid.utf8))
        assert(badScenario.validationErrors.contains("correctChoice out of range"))
        print("PilotScenarioTests: PASS")
    }
}
