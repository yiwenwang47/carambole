import Foundation

@main
struct NuanceModelTests {
    static func main() throws {
        let fixture = """
        {
          "id": "nu_01", "number": 1, "title": "Ce qui s'est passé",
          "goal": "Distinguer le cadre de l'événement.",
          "elements": [{
            "id": "nu_01_e01", "title": "La panne", "note": "Repère le changement.",
            "cards": [
              {"id":"a","format":"word","source":[{"text":"La musique s'arrête."}],"task":"Que se passe-t-il ?","response":{"kind":"choices","choices":["Elle s'arrête.","Elle commence.","Elle continue."],"answer":"Elle s'arrête."},"feedback":"Elle s'arrête."},
              {"id":"b","format":"dialogue","source":[{"speaker":"Léa","text":"Le son s'est coupé."}],"task":"Qui parle ?","response":{"kind":"choices","choices":["Léa","Inès","Théo"],"answer":"Léa"},"feedback":"C'est Léa."},
              {"id":"c","format":"rewrite","source":[{"text":"Le concert s'interrompt."}],"task":"Mets au passé.","response":{"kind":"typed","answer":"Le concert s'est interrompu","accepted":["Le concert s'est interrompu","Le spectacle s'est interrompu"]},"feedback":"L'arrêt est terminé."},
              {"id":"d","format":"microtext","source":[{"text":"La salle était pleine."}],"task":"Quel est le cadre ?","response":{"kind":"choices","choices":["La salle","La rue","Le bus"],"answer":"La salle"},"feedback":"La salle est le cadre."},
              {"id":"e","format":"word","source":[{"text":"Une panne a coupé le son."}],"task":"Que signifie panne ?","response":{"kind":"choices","choices":["Un problème","Un billet","Une place"],"answer":"Un problème"},"feedback":"Le son s'est coupé."},
              {"id":"f","format":"rewrite","source":[{"text":"Léa parlait."}],"task":"Recopie.","response":{"kind":"typed","answer":"Léa parlait","accepted":["Léa parlait"]},"feedback":"L'action dure."},
              {"id":"g","format":"word","source":[{"text":"Le concert commence."}],"task":"Que se passe-t-il ?","response":{"kind":"choices","choices":["Il commence","Il finit","Il s'arrête"],"answer":"Il commence"},"feedback":"Il commence."},
              {"id":"h","format":"dialogue","source":[{"speaker":"Inès","text":"Je suis là."}],"task":"Qui parle ?","response":{"kind":"choices","choices":["Inès","Léa","Théo"],"answer":"Inès"},"feedback":"C'est Inès."}
            ]
          }]
        }
        """
        let module = try JSONDecoder().decode(NuanceModuleFile.self, from: Data(fixture.utf8))
        let sameModule = try JSONDecoder().decode(NuanceModuleFile.self, from: Data(fixture.utf8))
        precondition(module == sameModule)
        precondition(module.elements[0].cards[0] != module.elements[0].cards[1])
        precondition(module.id == "nu_01" && module.number == 1)
        precondition(module.elements[0].id == "nu_01_e01")
        precondition(module.elements[0].cards.map(\.id) == ["a", "b", "c", "d", "e", "f", "g", "h"])
        precondition(module.elements[0].cards[1].source[0].speaker == "Léa")

        let typed = module.elements[0].cards[2]
        precondition(typed.accepts("  LE  CONCERT  S’EST INTERROMPU?!  "))
        precondition(typed.accepts("Le spectacle s'est interrompu."))
        precondition(!typed.accepts("Le concert s'est interrompue"))
        precondition(!typed.accepts("Le concert s'est interrompu demain"))
        precondition(module.elements[0].cards[0].accepts(" ELLE S’ARRÊTE… "))
        precondition(!module.elements[0].cards[0].accepts("Elle commence."))
        precondition(NuanceCard.normalized(" COTE ") != NuanceCard.normalized("CÔTÉ"))

        let cards = module.elements[0].cards
        let base = Date(timeIntervalSince1970: 1_000)
        let history: [String: NuanceCardHistory] = [
            "a": .init(lastDone: base.addingTimeInterval(20), times: 2, lastRating: 3),
            "d": .init(lastDone: base.addingTimeInterval(30), times: 1, lastRating: 1),
            "f": .init(lastDone: base.addingTimeInterval(10), times: 3, lastRating: 2),
            "h": .init(lastDone: base.addingTimeInterval(40), times: 1, lastRating: 1)
        ]
        let learn = NuanceCardSelector.select(from: cards, history: history, limit: 6, mode: .learn)
        precondition(learn.map(\.id) == ["d", "h", "b", "c", "e", "f"], "Learn: misses first, at most three unseen, then oldest")
        let review = NuanceCardSelector.select(from: cards, history: history, limit: 8, mode: .review)
        precondition(review.map(\.id) == ["d", "h", "b", "c", "e", "g", "f", "a"], "Review: all unseen in authored order, then oldest")
        precondition(NuanceCardSelector.select(from: cards, history: history, limit: 1, mode: .review).map(\.id) == ["d"])
        let allSeen = Dictionary(uniqueKeysWithValues: cards.enumerated().map { index, card in
            (card.id, NuanceCardHistory(lastDone: base.addingTimeInterval(Double(100 - index)), times: 1, lastRating: 3))
        })
        precondition(NuanceCardSelector.select(from: cards, history: allSeen, limit: 2, mode: .review).map(\.id) == ["h", "g"], "Oldest cards must be chosen when there are no misses or unseen cards")

        precondition(!NuanceMastery.gateMet(correctCardIDs: ["a", "e", "g"], cards: cards), "One format cannot pass")
        precondition(!NuanceMastery.gateMet(correctCardIDs: ["a", "b"], cards: cards), "Two cards cannot pass")
        precondition(NuanceMastery.gateMet(correctCardIDs: ["a", "b", "c"], cards: cards))
        precondition(!NuanceMastery.gateMet(correctCardIDs: ["a", "b", "unknown"], cards: cards), "Unknown IDs cannot count")

        if let path = CommandLine.arguments.dropFirst().first {
            let real = try JSONDecoder().decode(NuanceModuleFile.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
            precondition(real.elements.count == 5 && real.elements.allSatisfy { (4...7).contains($0.cards.count) })
            precondition(Set(real.elements.flatMap { $0.cards.map(\.id) }).count == real.elements.flatMap(\.cards).count)
        }
        print("Nuance model tests passed")
    }
}
