import Foundation

@main
struct Book3PilotTests {
    static func main() throws {
        let paths = Array(CommandLine.arguments.dropFirst())
        precondition(paths.count == 20, "Pass all 20 Book 3 module files in order")

        let modules = try paths.map { path in
            try JSONDecoder().decode(
                [Book3PilotCard].self,
                from: Data(contentsOf: URL(fileURLWithPath: path))
            )
        }

        let sentencePunctuation = CharacterSet(charactersIn: ".,?!;:«»…\"()")
        for (index, cards) in modules.enumerated() {
            let number = index + 1
            let prefix = String(format: "b3_%02d_", number)
            precondition(cards.count >= 10, "Module \(number) needs a full review batch")
            precondition(cards.allSatisfy { $0.id.hasPrefix(prefix) })
            precondition(Set(cards.map(\.id)).count == cards.count)
            precondition(cards.allSatisfy { $0.validationErrors.isEmpty })
            precondition(Book3PilotCard.Format.allCases.allSatisfy { format in
                cards.contains { $0.format == format }
            })

            for card in cards where card.response.kind == .typed {
                for answer in card.response.accepted ?? [] {
                    precondition(!answer.unicodeScalars.contains(where: sentencePunctuation.contains),
                                 "Typed answer contains punctuation: \(card.id)")
                }
            }
        }

        let everyCard = modules.flatMap { $0 }
        precondition(Set(everyCard.map(\.id)).count == everyCard.count)

        func card(_ id: String) throws -> Book3PilotCard {
            guard let match = everyCard.first(where: { $0.id == id }) else {
                throw NSError(domain: "Book3PilotTests.missingCard", code: 1)
            }
            return match
        }

        let event = try card("b3_01_rewrite_event")
        precondition(event.accepts("  LE CONCERT S’EST INTERROMPU.  "))
        precondition(!event.accepts("Le concert s'est interrompue"))

        let time = try card("b3_02_rewrite_before")
        precondition(time.accepts("THÉO AVAIT PARLÉ À INÈS."))
        precondition(!time.accepts("Théo a parlé à Inès"))

        let delay = try card("b3_09_word_delai")
        precondition(delay.accepts("the time before the bus arrives"))
        precondition(!delay.accepts("the length of the bus journey"))

        let synthesis = try card("b3_20_microtext_final_synthesis")
        precondition(synthesis.accepts("Le jardin pourrait améliorer la place, mais l'entretien et le coût restent à préciser."))
        precondition(!synthesis.accepts("Le jardin est financé et son entretien est déjà organisé."))

        print("Book 3 content: \(modules.count) modules, \(everyCard.count) cards, schema and answer checks passed")
    }
}
