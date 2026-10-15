import Foundation

@main
struct Book3PilotTests {
    static func main() throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let cards = try JSONDecoder().decode([Book3PilotCard].self, from: Data(contentsOf: url))

        precondition(cards.count == 8)
        precondition(Set(cards.map(\.id)).count == cards.count)
        for format in Book3PilotCard.Format.allCases {
            precondition(cards.filter { $0.format == format }.count == 2)
        }
        precondition(cards.allSatisfy { $0.validationErrors.isEmpty })

        let rewrite = try XCTUnwrap(cards.first { $0.id == "b3_01_rewrite_event" })
        precondition(rewrite.accepts("  LE MICRO S’EST INTERROMPU.  "))
        precondition(!rewrite.accepts("Le micro s'est interrompue"))
        precondition(!rewrite.accepts("Le micro s'est interrompu hier"))

        let choice = try XCTUnwrap(cards.first { $0.id == "b3_01_dialogue_event" })
        precondition(choice.accepts("La lumière s'est éteinte."))
        precondition(!choice.accepts("La salle était pleine."))

        print("Book 3 pilot model: 8 cards, 4 formats, answer checks passed")
    }

    static func XCTUnwrap<T>(_ value: T?) throws -> T {
        guard let value else { throw NSError(domain: "Book3PilotTests", code: 1) }
        return value
    }
}
