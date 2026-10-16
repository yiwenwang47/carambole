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

        // Speaker labels: cast name, else the display role; never a "Serveur" fallback.
        let servers = items.flatMap { $0.turns.filter { !$0.isLearner } }
        check(servers.allSatisfy { $0.speakerLabel != nil }, "every bundled server turn has a name or role")
        check(servers.allSatisfy { $0.name == nil || $0.role == nil }, "role only on unnamed server turns")
        let byID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        check(byID["sit_02_morning_d01"]?.addressTag == "#tu", "informal dialogue address tag")
        check(byID["sit_02_morning_d06"]?.addressTag == "#tu", "group vous does not change the informal tag")
        check(byID["sit_17_react_s04"]?.addressTag == "#vous", "switch to formal address tag")
        check(byID["sit_03_slip_d03"]?.addressTag == "#tu", "a mistaken vous does not change the address tag")
        check(byID["sit_03_tutoyer_s04"]?.addressTag == "#tu", "switch to informal address tag")
        check(byID["sit_19_propose_s04"]?.addressTag == "#vous", "group reply uses plural address tag")
        check(byID["sit_19_book_s05"]?.addressTag == "#vous", "dialogue form supplies a missing cue tag")
        check(byID["sit_09_confirm_s05"]?.addressTag == "#vous", "formal standalone prompt address tag")
        check(byID["sit_03_landing_s05"]?.addressTag == "#vous", "older neighbour prompt address tag")
        check(byID["sit_04_group_s02"]?.addressTag == "#vous", "group prompt address tag")
        check(byID["sit_19_prefer_s05"]?.addressTag == "#tu", "one friend's group-chat reply stays informal")
        check(byID["sit_24_pont_d01"]?.addressTag(for: byID["sit_24_pont_d01"]!.drills[0]) == nil,
              "comprehension without address choice hides the tag")
        check(byID["sit_24_pont_d01"]?.addressTag(for: byID["sit_24_pont_d01"]!.drills[1]) == nil,
              "reply without address words hides the tag")
        check(byID["sit_18_flats_s01"]?.addressTag(for: byID["sit_18_flats_s01"]!.drills[0]) == nil,
              "a contextual tu alone does not show the tag")
        check(byID["sit_02_morning_d01"]?.addressTag(for: byID["sit_02_morning_d01"]!.drills[1]) == "#tu",
              "an answer with toi shows the informal tag")
        check(byID["sit_03_register_s04"]?.addressTag(for: byID["sit_03_register_s04"]!.drills[0]) == "#vous",
              "formal rewrite shows the tag")
        check(byID["sit_19_propose_s04"]?.addressTag(for: byID["sit_19_propose_s04"]!.drills[0]) == "#vous",
              "group reply with vous shows the tag")
        check(byID["sit_07_bread_d01"]?.turns.first?.speakerLabel == "Boulangère", "baker's role label")
        check(byID["sit_07_bread_d01"]?.followUpSpeaker == "Boulangère", "follow-up takes the first server's role")
        check(byID["sit_10_address_d01"]?.turns.first?.speakerLabel == "Livreur", "delivery driver's role label")
        check(byID["sit_09_voicemail_d01"]?.turns.first?.speakerLabel == "Messagerie", "voicemail role label")
        check(byID["sit_09_voicemail_d01"]?.followUpSpeaker == "Serveur", "followUpRole overrides the voicemail")
        check(byID["sit_06_order_d01"]?.followUpSpeaker == "Karim", "named server still labels the follow-up")
        let bare = try decoder.decode(SituationItem.self, from: Data("""
            {"id": "x", "cue": "c", "turns": [{"speaker": "server", "text": "Bonjour !"}],
             "drills": [], "followUp": "Voilà.", "newWords": []}
            """.utf8))
        check(bare.turns[0].speakerLabel == nil, "no name and no role → no label")
        check(bare.followUpSpeaker == nil, "no name and no role → no follow-up label")

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

        // Trop facile (same rule as Book 1): only a clean card removes the element;
        // after the gate resolves, the element's later cards leave the queue.
        check(SituationTooEasy.removes(.good), "too easy: all first try removes")
        check(!SituationTooEasy.removes(.hard), "too easy: a retry cleans instead")
        check(!SituationTooEasy.removes(.again), "too easy: unsolved cleans instead")
        check(SituationTooEasy.keptAfter(index: 1, elementIDs: ["a", "b", "b", "b", "c", "b"]) == [0, 1, 4],
              "too easy: later cards of the element are skipped, earlier and other elements kept")
        check(SituationTooEasy.keptAfter(index: 0, elementIDs: ["a"]) == [0], "too easy: last card keeps itself")
        func shows(finished: Bool = false, reviewing: Bool = false, locked: Bool = false,
                   pending: Bool = false, clean: Bool = true) -> Bool {
            SituationTooEasy.showsControl(finished: finished, reviewing: reviewing, locked: locked,
                                          pending: pending, clean: clean)
        }
        check(shows(), "too easy: control on a clean live card")
        check(!shows(clean: false), "too easy: no control once the card has a miss")
        check(shows(pending: true, clean: false), "too easy: armed card keeps its line after a miss")
        check(!shows(finished: true, pending: true), "too easy: no control on a finished card")
        check(!shows(reviewing: true), "too easy: no control while reviewing")
        check(!shows(locked: true), "too easy: cannot arm while a solved drill settles")
        check(SituationTooEasy.canCancel(clean: true), "too easy: Annuler while the card is still clean")
        check(!SituationTooEasy.canCancel(clean: false), "too easy: no Annuler after a miss (the clean is due)")

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
        // The reusable matcher must preserve the rendered words while avoiding
        // a full glossary scan on every SwiftUI card update.
        let matcher = SituationText.Matcher(keys: Set(words.keys))
        let phrase = matcher.segments("Bonjour ! Comme d'habitude ?")
        check(phrase.first?.key == "bonjour" && phrase.first?.trailing == "\u{00A0}!",
              "indexed matcher keeps spaced punctuation with its word")
        check(phrase.contains { $0.key == "comme d'habitude" },
              "indexed matcher keeps the longest set phrase")
        let split = SituationText.Matcher(keys: ["moi aussi", "moi", "aussi"])
            .segments("Moi aussi, j'adore !", keepApart: "aussi")
        check(split.map(\.key) == ["moi", "aussi", nil],
              "indexed matcher leaves a Corriger error word tappable")
        for index in stride(from: 0, to: items.count, by: max(1, items.count / 50)) {
            let item = items[index]
            for turn in item.turns {
                check(matcher.segments(turn.text) == SituationText.segments(turn.text, keys: Set(words.keys)),
                      "\(item.id): indexed dialogue text matches existing rendering")
            }
        }
        for item in items {
            guard let i = item.errorTurnIndex, let mark = item.errorMark else { continue }
            let segs = SituationText.segments(item.turns[i].text, keys: Set(words.keys), keepApart: mark.word)
            check(segs.contains { SituationText.norm($0.display) == SituationText.norm(mark.word) },
                  "\(item.id): error word « \(mark.word) » is one tappable segment")
            check(matcher.segments(item.turns[i].text, keepApart: mark.word) == segs,
                  "\(item.id): indexed Corriger line matches existing rendering")
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
