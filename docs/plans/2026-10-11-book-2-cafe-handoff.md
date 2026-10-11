# Book 2 handoff — café module done, next steps

**Date:** 2026-10-11
**Repo:** `/Users/yiwenwang/Documents/CMU/research/personal/carambole/carambole`
**Branch:** `book2-cafe-content` merged into `main` (fast-forward). Not pushed.
**Supersedes:** the [content pause handoff](2026-10-11-book-2-content-pause-handoff.md). The [content handoff](2026-10-11-book-2-content-handoff.md) stays the rulebook (binding rules, cast, JSON shape, authoring procedure). The [pilot v2 handoff](2026-10-11-book-2-pilot-v2-handoff.md) stays the reference for the pilot screen.

## 1. Read first

1. This file.
2. [Content handoff](2026-10-11-book-2-content-handoff.md) §3 (binding rules), §4 (cast), §6 (JSON shape), §7–8 (authoring procedure and item checklist). Nothing there was reopened.
3. `tools/situations/README.md` for the schema, lint and commands.
4. `CLAUDE.md` *Rendered-surface grammar* and *Prompt self-sufficiency*.

## 2. Where things stand

- **Module 06 *Au café* is authored.** 8 moves × (10 dialogues + 5 standalone) = 120 items, in `carambole/Resources/Situations/06_au_cafe.json`. `words.json` has 204 entries: 31 taught words with a `firstSeen` item, 4 spoken forms, the rest base (*Fondations*) words.
- **Review set v4 played on the iPhone 18 Pro.** The user said "looks fine" after the two UI fixes below. Treat this as café approval only if the user confirms; ask at the start of the next session.
- **User decisions this session:**
  - The Karim, Léa and Théo voices are fine.
  - Karim switches to *tu* inside the `usual` move (d04 is « On peut se tutoyer, non ? »). He uses *vous* in every other module-06 move. Every `usual` cue states which form he uses, so cards stand alone in any review order.
- **Not done:** production audio (379 clips, 0 present), production loader / shelf / per-book progress (Tasks 2–3 of the action plan), the other 24 modules, the Écrire typing drill.

## 3. What was done this session

### Content

1. Two author agents reworked the two halves (`order size available substitute` / `takeaway usual mixup pay`).
2. Four independent judges reviewed two moves each. They found about 60 problems the lint cannot see. All were fixed. The common classes, to check in every future module:
   - **Cue leaks:** the English cue answers the Comprendre question on its own.
   - **Answer echo:** a line before the gap or reply prints the answer.
   - **Follow-ups that ignore the learner:** the closing line assumes an answer the learner never gave, or a speaker answers their own question.
   - **Unnatural French:** « Il reste deux thés » (café tea is not counted down), « café sans lait » (a café is black), « je l'ai pris sans lait » (reads as "drank it"), « sur place » in a friend's text.
   - **Hidden valid replies:** a second correct order buildable from the bank but missing from `accepted`.
   - **False errors:** « en carte » is common spoken French, so it can't be a Corriger error or a wrong option.
   - **Logic puzzles:** a gap only solvable by reasoning about who owns which drink.
   - **Untaught words used early:** a distractor using a word before its `firstSeen` item.
3. **Vocabulary audit against *Fondations*.** Several `firstSeen: null` words are not in Book 1: *bonjour, merci, pardon, s'il te plaît, encore, euros, erreur, espèces, désolé…* They are now taught (first item + `newWords` + ≥2 later dialogues + one Mot drill) or avoided (*payer, minutes, salut, d'accord, super, bien sûr, j'arrive, je vous dois, il vous faut…*). Compositional forms of taught words stay base: *donné, m'a, me faire, au lait*. **Repeat this audit for every new module**: grep each `firstSeen: null` word against `carambole/Resources/Topics/*.json`.
4. **Choice order.** The correct answer sat in slot 0 in 82 of 135 choice drills, and the pilot view does not shuffle choices. The drafts now place correct answers with a fixed per-drill hash. Authors must keep `correct` and `why` aligned and vary the slot in new drills. The production view should shuffle at render time (as Book 1's `Exercise.displayBank` does); then this stops mattering.

### Tools

- `tools/situations/lint.py`: a dialogue's turns plus its built reply must not exceed 3 lines (`over 3 lines with the built reply`). Test added; 48 Python tests total.
- `tools/pilot/test_content.py` accepts production review-set IDs (`sit_06_<move>_dNN/sNN`), allows 8–14-word standalone lines, and lets a Mot drill target a word taught on an earlier card.
- `tools/pilot/PilotScenarioTests.swift` validates the review set given on the command line, then runs its segmentation checks against the frozen v2 pilot `tools/pilot/fixtures/testbook_situation_v2.json`.

### Pilot screen (`carambole/Debug/SituationPilotView.swift`)

- **Answer hidden under the question card:** the chat scrolled only when the answer bubble appeared. It now pins to the bottom on size changes (`defaultScrollAnchor(.bottom, for: .sizeChanges)`) and when tiles are placed, a gap is filled, or the drill step changes.
- **Tiles outside the blue tray:** with three rows of tiles, the locked card squeezed the tray below its tiles. The tray now keeps its ideal height (`fixedSize(vertical:)`) and the scrollable chat gives up the space.
- Carry both fixes into the production view (Task 3).

### Review set v4 (in `carambole/Debug/testbook_situation.json`, with `pilot2_*` audio)

`order_d02, takeaway_d07, size_s03, usual_d04, mixup_d08, available_s02, pay_d04, substitute_d06, usual_s05`: D D S order, all six engines, the culture card, the *tu* switch, texts, payment.

## 4. Commits (on `main`)

| Commit | What |
|---|---|
| `6926000` | WIP café content and the pause handoff (previous session) |
| `ed2f09f` | Reworked drafts, vocabulary audit, choice-slot spread |
| `0a419c7` | Independent-review fixes, line-limit lint check |
| `7287113` | Review set v4, cast audio, pilot tests accept production IDs |
| `518e539` | Pilot screen: answer stays in view, tray not squashed |
| (this) | Handoff and doc updates |

## 5. Next steps, in order

1. **Ask the user** whether "looks fine" approves the café content, or whether they want another small review set (about 9 cards, never the whole module).
2. **Production audio** for café: `rtk python3 tools/situations/generate_audio.py --dry-run` (expect 379 missing), then the default mode. Needs `gcloud auth application-default` credentials. Then strict `rtk python3 tools/situations/lint.py` (with audio) must pass. Record the API characters used.
3. **Tasks 2–3 of the [action plan](2026-10-11-book-2-action-plan.md):** per-book progress and the production Book 2 view, loader and shelf entry. Port the pilot view, with choice shuffling and the two scroll/tray fixes.
4. **Other 24 modules** in batches of 5–6 (one arc). Per batch: plan matrix → author (two agents per module, split by moves; each edits only its own draft) → `assemble.py` → lint/tests/Grammalecte → four judges (two moves each) → fixes → *Fondations* vocabulary audit → small review set for the user.
5. Open questions from the content handoff §10 still unanswered: is the module 06 move list right (§10.3; it was built as planned); should Écrire be built in Swift now (§10.4); should the main app get the swipe-up "trop facile" change (§10.5).

## 6. Working rules learned this session

- **Agents on parallel halves:** each agent edits only its own `drafts/06_*_half*.json`; nobody runs `assemble.py` except the coordinator. Words file entries shared by both halves must be identical, or `assemble.py` fails. The half where a word first appears owns its entry.
- **Judges are read-only** and get the rules plus the context they can't infer (Karim's *tu/vous* plan, the shuffled choice order, untaught verbs to avoid).
- Grammalecte only proves grammar. Naturalness, answer uniqueness and cue leaks need the judges.
- Simulator checks: launch flags `CB_TEST_BOOK=1 CB_TB_OPEN=situation CB_PILOT_INDEX=n [CB_PILOT_STEP=n] [CB_PILOT_AUTOPLAY=1|wrong]`, take a burst of `simctl io screenshot`s and look at the frames. `CB_PILOT_AUTOPLAY=wrong` exercises wrong attempts and wrapping banks.
- Phone install only when the user asks (commands in the content handoff §9). Delete `/tmp/cb-book2-pilot-*` afterwards.

## 7. Commands

```sh
rtk python3 tools/situations/assemble.py                  # drafts → production JSON
rtk python3 tools/situations/lint.py --no-audio           # full content lint
rtk python3 -m unittest tools/situations/test_lint.py tools/situations/test_tools.py tools/pilot/test_content.py
rtk python3 tools/situations/deep_lint.py                 # Grammalecte on rendered lines
rtk python3 tools/situations/review_set.py <nine item IDs>  # Test book export
rtk python3 tools/situations/generate_audio.py --review   # pilot2_* clips for the review set
rtk proxy swiftc -D DEBUG carambole/Debug/PilotScenario.swift tools/pilot/PilotScenarioTests.swift -o /tmp/cb-pilot-scenario-tests
rtk proxy /tmp/cb-pilot-scenario-tests carambole/Debug/testbook_situation.json
```

Last run: lint OK, 48 tests OK, Swift contract PASS, Grammalecte 310 lines / 0 flags.
