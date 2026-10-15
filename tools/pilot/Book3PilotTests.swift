import Foundation

@main
struct Book3PilotTests {
    static func main() throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let cards = try JSONDecoder().decode([Book3PilotCard].self, from: Data(contentsOf: url))

        precondition(cards.count == 10)
        precondition(Set(cards.map(\.id)).count == cards.count)
        for format in Book3PilotCard.Format.allCases {
            precondition(cards.filter { $0.format == format }.count == (format == .word ? 4 : 2))
        }
        precondition(cards.allSatisfy { $0.validationErrors.isEmpty })

        let rewrite = try XCTUnwrap(cards.first { $0.id == "b3_01_rewrite_event" })
        precondition(rewrite.accepts("  LE CONCERT S’EST INTERROMPU.  "))
        precondition(!rewrite.accepts("Le concert s'est interrompue"))
        precondition(!rewrite.accepts("Le concert s'est interrompu hier"))

        let choice = try XCTUnwrap(cards.first { $0.id == "b3_01_dialogue_event" })
        precondition(choice.accepts("La musique s'est arrêtée."))
        precondition(!choice.accepts("Léa parlait à Théo."))

        let vocabulary = try XCTUnwrap(cards.first { $0.id == "b3_01_word_interrompre" })
        precondition(vocabulary.accepts("to stop suddenly"))
        precondition(!vocabulary.accepts("to begin again"))

        let module02URL = URL(fileURLWithPath: CommandLine.arguments[2])
        let module02 = try JSONDecoder().decode([Book3PilotCard].self, from: Data(contentsOf: module02URL))
        precondition(module02.count == 4)
        precondition(Set(module02.map(\.id)).count == module02.count)
        precondition(module02.allSatisfy { $0.validationErrors.isEmpty })
        precondition(Book3PilotCard.Format.allCases.allSatisfy { format in
            module02.filter { $0.format == format }.count == 1
        })

        let first = module02[0]
        precondition(first.id == "b3_02_dialogue_before")
        precondition(first.accepts("Il a parlé à Inès avant l'arrivée de Léa."))
        precondition(!first.accepts("Il a parlé à Inès après l'arrivée de Léa."))

        let last = module02[3]
        precondition(last.id == "b3_02_rewrite_before")
        precondition(last.accepts("THÉO AVAIT PARLÉ À INÈS."))
        precondition(!last.accepts("Théo a parlé à Inès"))

        let later = try CommandLine.arguments.dropFirst(3).map { path in
            try JSONDecoder().decode([Book3PilotCard].self, from: Data(contentsOf: URL(fileURLWithPath: path)))
        }
        precondition(later.count == 18)
        for (offset, group) in later.enumerated() {
            let module = offset + 3
            precondition(group.count == 6)
            precondition(group.allSatisfy { $0.id.hasPrefix(String(format: "b3_%02d_", module)) })
            precondition(Set(group.map(\.id)).count == group.count)
            precondition(group.allSatisfy { $0.validationErrors.isEmpty })
            precondition(group.filter { $0.format == .word }.count == 2)
            precondition(Book3PilotCard.Format.allCases.allSatisfy { format in
                group.contains { $0.format == format }
            })
        }
        precondition(later[0][0].accepts("according to Inès"))
        precondition(later[0][4].accepts("Inès dit qu'elle a parlé à Théo"))
        precondition(!later[0][4].accepts("Inès dit que j'ai parlé à Théo"))
        precondition(later[1][4].accepts("Selon Théo, Léa est arrivée après la panne"))
        precondition(later[2][4].accepts("L'affiche dont j'ai parlé est bleue"))
        precondition(later[3][4].accepts("Ce dont nous avons besoin, c'est de temps"))
        precondition(later[4][4].accepts("Théo la lui envoie"))
        precondition(later[5][4].accepts("Le concert est reporté parce qu'il y a une panne"))
        precondition(later[6][4].accepts("Le bus coûte moins cher que le taxi"))
        precondition(later[7][4].accepts("Je viens à condition que tu sois là"))
        precondition(later[8][4].accepts("Si j'avais vérifié l'heure, je serais arrivée à l'heure"))
        precondition(later[9][4].accepts("Je le prends même si le taxi coûte cher"))
        precondition(later[10][4].accepts("Pourriez-vous préciser à quelle heure le concert commence"))
        precondition(later[11][4].accepts("Je suis contente que tu sois là"))
        precondition(later[12][4].accepts("Je doute que le concert ait lieu demain"))
        precondition(later[13][4].accepts("Je préférerais que nous commencions à huit heures"))
        precondition(later[14][4].accepts("L'affiche a été envoyée par Théo"))
        precondition(later[15][4].accepts("Léa fait réparer son téléphone au magasin"))
        precondition(later[16][4].accepts("Le concert a commencé en retard, pourtant il était bon"))
        precondition(later[17][4].accepts("Léa l'a trouvé bon même s'il a commencé en retard"))
        let everyCard = cards + module02 + later.flatMap { $0 }
        precondition(Set(everyCard.map(\.id)).count == everyCard.count)

        print("Book 3 content: modules 01–20, answer and format checks passed")
    }

    static func XCTUnwrap<T>(_ value: T?) throws -> T {
        guard let value else { throw NSError(domain: "Book3PilotTests", code: 1) }
        return value
    }
}
