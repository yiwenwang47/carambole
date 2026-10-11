import Foundation

// Pure-logic tests for *En situation* production content (carambole/Models/Situation.swift):
// decoding every manifest module, render-time shuffling, grading by identity,
// all accepted replies, the dialogue rating, Réviser selection and the mastery gate.
//
//   swiftc carambole/Models/Situation.swift tools/situations/SituationModelTests.swift -o /tmp/cb-sit-model-tests
//   /tmp/cb-sit-model-tests carambole/Resources/Situations
//
// (The app has no XCTest target; this follows tools/pilot/PilotScenarioTests.swift.)

@main
struct SituationModelTests {
    static var failures = 0

    static func check(_ condition: Bool, _ message: String) {
        if !condition {
            failures += 1
            print("FAIL: \(message)")
        }
    }

    static func main() throws {
        let dir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "carambole/Resources/Situations")
        let decoder = JSONDecoder()
        let manifest = try decoder.decode(SituationManifest.self,
                                          from: Data(contentsOf: dir.appendingPathComponent("situations_manifest.json")))
        let words = try decoder.decode(SituationWordFile.self,
                                       from: Data(contentsOf: dir.appendingPathComponent("words.json"))).glossary
        var modules: [SituationModuleFile] = []
        for file in manifest.moduleFiles {
            modules.append(try decoder.decode(SituationModuleFile.self, from: Data(contentsOf: dir.appendingPathComponent(file))))
        }
        check(!modules.isEmpty, "manifest lists at least one module")
        let elements = modules.flatMap(\.elements)
        let items = elements.flatMap(\.items)
        check(Set(elements.map(\.id)).count == elements.count, "element IDs unique")
        check(elements.allSatisfy { $0.id.hasPrefix("sit_") }, "every Book 2 element ID starts with sit_")
        check(Set(items.map(\.id)).count == items.count, "item IDs unique")
        for item in items {
            check(item.validationErrors.isEmpty, item.validationErrors.joined(separator: "; "))
        }

        // Every drill type is present in the content.
        let kinds = Set(items.flatMap { $0.drills.map(\.type) })
        check(kinds == Set(SituationDrill.Kind.allCases), "all six drill types present, got \(kinds)")

        // Audio keys follow the production convention.
        let first = items.first { $0.id == "sit_06_order_d01" }
        check(first?.turnAudioKey(0) == "sit_06_order_d01_t0", "turn audio key")
        check(first?.followUpAudioKey == "sit_06_order_d01_f", "follow-up audio key")

        // Every accepted reply grades correct; the model is accepted; a one-tile
        // change grades wrong.
        for item in items {
            for drill in item.drills where drill.type == .reply {
                for reply in drill.accepted ?? [] {
                    check(drill.accepts(reply), "\(item.id): accepted reply grades correct")
                    check(drill.correctPrefixCount(reply) == reply.count, "\(item.id): full prefix")
                }
                check((drill.accepted ?? []).contains { $0.joined(separator: " ") == drill.model },
                      "\(item.id): model is an accepted reply")
                if let reply = drill.accepted?.first, reply.count > 1 {
                    check(!drill.accepts(Array(reply.dropLast())), "\(item.id): a shortened reply is wrong")
                }
            }
        }
        // A second valid reply (shorter order without « je voudrais ») grades correct.
        let s01 = items.first { $0.id == "sit_06_order_s01" }!.drills[0]
        check(s01.accepts(["Bonjour,", "un café", "et", "un thé,", "s'il vous plaît."]), "alternative reply accepted")
        check(!s01.accepts(["Bonjour,", "je voudras", "un café", "et", "un thé,", "s'il vous plaît."]), "distractor rejected")
        check(s01.correctPrefixCount(["Bonjour,", "je voudrais", "une thé,"]) == 2, "prefix kept on retry")

        // Retry gate: after a wrong reply, Vérifier stays off until the answer
        // changes, so pressing it again unchanged never spends the second try.
        let wrongReply = ["Bonjour,", "je voudrais", "une thé,"]
        let keep = s01.correctPrefixCount(wrongReply)
        let refused = SituationRetry.rejected(after: wrongReply, keep: keep)
        let kept = Array(wrongReply.prefix(keep))
        check(SituationRetry.canCheck(wrongReply, rejected: []), "first check is allowed")
        check(!SituationRetry.canCheck([], rejected: []), "nothing placed → no check")
        check(!SituationRetry.canCheck(kept, rejected: refused), "kept start alone, unchanged → Vérifier stays off")
        check(!SituationRetry.canCheck(wrongReply, rejected: refused), "same wrong reply rebuilt → Vérifier stays off")
        check(SituationRetry.canCheck(kept + ["un café"], rejected: refused), "a changed answer can be checked")
        check(SituationRetry.canCheck(Array(kept.prefix(1)), rejected: refused), "removing a tile is a change")
        check(!SituationRetry.canCheck([], rejected: SituationRetry.rejected(after: ["x"], keep: 0)),
              "nothing kept → nothing to check")
        // Every reply drill: one wrong attempt leaves an answer that cannot be
        // re-checked as is, and finishing a valid reply from it is allowed.
        for item in items {
            for drill in item.drills where drill.type == .reply {
                guard let reply = drill.accepted?.first, reply.count > 1,
                      let odd = (drill.bank ?? []).first(where: { !reply.contains($0) }) else { continue }
                let wrong = Array(reply.dropLast()) + [odd]
                guard !drill.accepts(wrong) else { continue }
                let k = drill.correctPrefixCount(wrong)
                let blocked = SituationRetry.rejected(after: wrong, keep: k)
                let left = Array(wrong.prefix(k))
                check(!SituationRetry.canCheck(left, rejected: blocked), "\(item.id): unchanged retry blocked")
                if let fix = drill.accepted?.first(where: { Array($0.prefix(k)) == left }) {
                    check(SituationRetry.canCheck(fix, rejected: blocked), "\(item.id): corrected reply can be checked")
                }
            }
        }

        // Choice shuffling: a permutation, deterministic per seed, every slot used,
        // and grading follows the choice TEXT whatever its screen position.
        var slotHits = [0, 0, 0]
        for item in items {
            for (step, drill) in item.drills.enumerated() {
                guard let choices = drill.choices, let right = drill.correctChoice else { continue }
                for salt in 0..<4 {
                    let seed = SituationShuffle.seed("\(item.id)#\(step)#c#\(salt)")
                    let order = SituationShuffle.order(count: choices.count, seed: seed)
                    check(order.sorted() == Array(choices.indices), "\(item.id): order is a permutation")
                    check(order == SituationShuffle.order(count: choices.count, seed: seed), "deterministic")
                    for (slot, authored) in order.enumerated() {
                        check(drill.isCorrect(choice: choices[authored]) == (choices[authored] == right),
                              "\(item.id): grading by identity")
                        if choices.count == 3, choices[authored] == right { slotHits[slot] += 1 }
                    }
                }
            }
        }
        check(slotHits.allSatisfy { $0 > 0 }, "the right answer lands in every slot: \(slotHits)")
        let maxShare = Double(slotHits.max() ?? 0) / Double(max(1, slotHits.reduce(0, +)))
        check(maxShare < 0.5, "no slot holds the answer most of the time: \(slotHits)")

        // Reply bank order never spells an accepted reply left to right.
        for item in items {
            for (step, drill) in item.drills.enumerated() where drill.type == .reply {
                let bank = drill.bank ?? []
                for salt in 0..<4 {
                    let order = SituationShuffle.bankOrder(bank: bank, accepted: drill.accepted ?? [],
                                                           seed: SituationShuffle.seed("\(item.id)#\(step)#bank#\(salt)"))
                    check(order.sorted() == Array(bank.indices), "\(item.id): bank permutation")
                    let shown = order.map { bank[$0] }
                    check(!(drill.accepted ?? []).contains { $0.count > 1 && Array(shown.prefix($0.count)) == $0 },
                          "\(item.id): bank never spells the answer")
                }
            }
        }

        // Dialogue rating = worst drill; any miss or retry → at most hard.
        check(SituationOutcome.dialogue([.good, .good]) == .good, "all first try → good")
        check(SituationOutcome.dialogue([.good, .hard]) == .hard, "one retry → hard")
        check(SituationOutcome.dialogue([.hard, .again]) == .again, "one unsolved → again")
        check(SituationOutcome.drill(misses: 1, solved: true) == .hard, "solved after a miss → hard")
        check(SituationOutcome.drill(misses: 0, solved: true) == .good, "first try → good")
        check(SituationOutcome.drill(misses: 2, solved: false) == .again, "not solved → again")

        // Tooltip text: spoken forms carry `* `.
        let spoken = words.values.filter(\.spoken)
        check(!spoken.isEmpty, "word list has spoken forms")
        check(spoken.allSatisfy { $0.tipText.hasPrefix("* ") }, "spoken tooltips start with * ")
        check(words.values.filter { !$0.spoken }.allSatisfy { !$0.tipText.hasPrefix("* ") }, "standard words have no *")
        // Longest phrase wins; trailing punctuation stays outside the word.
        let segs = SituationText.segments("Bonjour ! Comme d'habitude ?", keys: Set(words.keys))
        check(segs.first?.key == "bonjour" && segs.first?.trailing == "\u{00A0}!", "spaced ! rides on the word")
        check(segs.contains { $0.key == "comme d'habitude" }, "set phrase is one tappable segment")
        // A Corriger error word inside a set phrase stays tappable on its own.
        let apart = SituationText.segments("Moi aussi, j'adore !", keys: ["moi aussi", "moi", "aussi"], keepApart: "aussi")
        check(apart.map(\.key) == ["moi", "aussi", nil] || apart.contains { $0.key == "aussi" }, "error word split out of its phrase")
        for item in items {
            guard let i = item.errorTurnIndex, let mark = item.errorMark else { continue }
            let segs = SituationText.segments(item.turns[i].text, keys: Set(words.keys), keepApart: mark.word)
            check(segs.contains { SituationText.norm($0.display) == SituationText.norm(mark.word) },
                  "\(item.id): error word « \(mark.word) » is one tappable segment")
        }
        // Every new word and Mot target has a gloss.
        for item in items {
            for word in item.newWords { check(words[SituationText.norm(word)] != nil, "\(item.id): gloss for \(word)") }
            for drill in item.drills where drill.type == .word {
                check(words[SituationText.norm(drill.target ?? "")] != nil, "\(item.id): gloss for Mot target")
            }
        }

        // Réviser selection.
        let move = elements.first { $0.id == "sit_06_order" }!.items
        let day: TimeInterval = 86_400
        func h(_ daysAgo: Double, _ outcome: SituationOutcome = .good) -> SituationItemHistory {
            SituationItemHistory(lastDone: Date(timeIntervalSince1970: 1_000_000 - daysAgo * day), times: 1, lastOutcome: outcome)
        }
        // Nothing done → the first item.
        check(SituationSelector.reviewItem(move, history: [:], lastKinds: [])?.id == move[0].id, "unseen first, in order")
        // First two done → the third (unseen beats oldest).
        var hist: [String: SituationItemHistory] = [move[0].id: h(3), move[1].id: h(2)]
        let third = SituationSelector.reviewItem(move, history: hist, lastKinds: [])
        check(third.map { hist[$0.id] == nil } ?? false, "an unseen item is chosen while any remain")
        // Vary the type: skip one step ahead when the next unseen repeats the last types.
        let nextUnseen = move.filter { hist[$0.id] == nil }
        let varied = SituationSelector.reviewItem(move, history: hist, lastKinds: nextUnseen[0].drillKinds)
        if !nextUnseen[1].drillKinds.isDisjoint(with: nextUnseen[0].drillKinds) {
            check(varied?.id == nextUnseen[0].id, "no better candidate → keep order")
        } else {
            check(varied?.id == nextUnseen[1].id, "different drill type preferred")
        }
        // All done → the oldest.
        hist = Dictionary(uniqueKeysWithValues: move.enumerated().map { ($1.id, h(Double(30 - $0))) })
        check(SituationSelector.reviewItem(move, history: hist, lastKinds: [])?.id == move[0].id, "all done → oldest")
        // A missed item comes back first.
        hist[move[7].id] = h(1, .again)
        check(SituationSelector.reviewItem(move, history: hist, lastKinds: [])?.id == move[7].id, "missed item first")
        // Learn: next unseen chunk of three in authored order (d d s).
        let learn = SituationSelector.learnItems(move, history: [move[0].id: h(1)])
        check(learn.map(\.id) == move[1...3].map(\.id), "learn chunk = next unseen, in order")
        check(SituationSelector.learnItems(move, history: [:]).map(\.isStandalone) == [false, false, true],
              "first learn chunk mixes two dialogues and a standalone")

        // Mastery gate: 3 distinct items AND ≥ 2 drill types.
        let replyOnly = move.filter { $0.drillKinds == [.reply] }
        if replyOnly.count >= 3 {
            check(!SituationMastery.gateMet(correctItemIDs: Set(replyOnly.prefix(3).map(\.id)), items: move),
                  "3 items of one drill type do not master")
        }
        check(!SituationMastery.gateMet(correctItemIDs: Set(move.prefix(2).map(\.id)), items: move), "2 items do not master")
        let mixed = move.prefix(3)
        let mixedKinds = mixed.reduce(into: Set<SituationDrill.Kind>()) { $0.formUnion($1.drillKinds) }
        check(SituationMastery.gateMet(correctItemIDs: Set(mixed.map(\.id)), items: move) == (mixedKinds.count >= 2),
              "3 items over 2 types master")
        check(!SituationMastery.gateMet(correctItemIDs: ["other_book_item", move[0].id, move[1].id], items: move),
              "items of another element never count")

        if failures > 0 {
            print("SituationModelTests: \(failures) FAILED")
            exit(1)
        }
        print("SituationModelTests: PASS (\(modules.count) module(s), \(elements.count) moves, \(items.count) items)")
    }
}
