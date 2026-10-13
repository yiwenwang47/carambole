# Book 2 handoff: start here next session

**Written:** 2026-10-12, end of session.
**Repo:** `carambole/`, branch `main`, **not pushed**.
**Session log:** [2026-10-12 handoff](2026-10-12-book-2-handoff.md), with every step and decision in order.
**Still binding:**
- [2026-10-11 handoff](2026-10-11-book-2-next-session-handoff.md): §2 decisions, §4 pipeline, §6 commands.
- [Content handoff](2026-10-11-book-2-content-handoff.md): the rulebook.

## 1. Start here

1. **Carousel for going back: DONE (2026-10-12, late).** Book 1's real carousel is in Book 2 (§3). User decision: « Suivant » also slides (Book 1), and a left swipe on a finished card advances. Simulator-checked only; the Test book on the phone still has the old option-2 slide until reinstalled (only when the user asks).
2. **Audio for 11–15: done.** All 3,982 production clips are present, strict `lint.py` passes for 15 modules, and the clips are committed.
3. **Arc 4 (modules 16–20)** comes after that, using the same pipeline (§4).

## 2. State

| Area | State |
|---|---|
| Content | 15 of 25 modules (1,800 items). They are authored, judged, fixed and assembled. |
| Checks | `lint.py --no-audio` OK. Grammalecte: 4,721 lines, 0 flags. 77+ Python tests OK. Swift model test PASS. Pilot tests PASS. |
| Audio | Complete for all 15 modules (3,982 production clips). Strict lint passes. |
| Review sets | v7 (arc 2) and v8 (arc 3) are approved. The user said v8 "sounds ok". |
| Phone | The Test book has v8 plus going back (option 2 slide). The main Carambole app has NOT been reinstalled; install it only when the user asks. |
| Going back | Built in both `SituationSessionView` and the Test book pilot (§3). The user wants the animation replaced. |

## 3. Done: Book 1 carousel in Book 2

- `Features/Situation/SituationCardView.swift`: one card (cue, chat, drill zone, footer, tip, card fit, autoplay). Its logic state is a `SituationCardState` that the session owns (`states[index]`), so a card rebuilt off-screen comes back exactly as it was. `CardState`, `captureCard`/`restoreCard`, `swapCard`, `dragX`, the fade-and-rise dialogue change are gone.
- `SituationSessionView`: queue, `cursor` / `frontier`, Book 1's `visibleIndices` (cursor ± 1), offsets `(i - cursor) * w + dragOffset`, `resistedOffset`, `endDrag` thresholds, `pageSpring`, haptic. The axis is decided on the first drag change, so chat scrolls still win. `leavingIndex` = Book 1's `hideExplanationAt` (the card left with « Suivant » keeps its live look while sliding out). Top bar fixed.
- The Test book pilot (`Debug/SituationPilotView.swift`) is now a ~60-line adapter: it decodes the review set as `SituationItem`s and runs the production session with `recordsProgress = false`, `audioPrefix "pilot2_"`, flags `CB_PILOT_*`. **Behaviour change:** the Test book now uses production rules (Choisir/Compléter: one retry, render-time shuffles), so review sets look exactly like the book.
- Flags (both prefixes): `INDEX STEP STAGE TIP AUTOPLAY BACK_AT SKIP_INTRO`; `CB_SIT_ITEMS` for production.
- Checked on the iPhone 18 Pro sim by frames: pilot autoplay + `BACK_AT=2` (forward and back slides), production `CB_SIT_ITEMS=sit_07_taste_s04,…` (long Transformer card: chat fixed, tray shrinks and scrolls). Real finger swipes untested (no tap automation).

## 4. Arc 4 (modules 16–20)

- **Pipeline:** the same as arc 3; see the session log, the "Arc 3" section.
- **Order:** planner → user OKs the defaults → coordinator prep (`modules.json`, gloss and lint changes) → 2 authors per module → gloss conflict scan → assemble → 4 judges per module → fixers → apply gloss widenings book-wide → vocab audit → 9-card review set → phone (if asked) → user verdict → production audio.
- **Lessons from arc 3:**
  - **Usage limits.** 10 authors and then 20 judges in parallel ran into the usage limit, twice. Resume them with SendMessage; they keep their context. The session log lists which judge covers which moves. Running about 7 at a time is safer.
  - **Comprendre keys.** In 15b, 15 `comprehend` drills had `correct` pointing at the false choice (the author moved the index, not the choices). Lint can't catch this. Ask authors and fixers to check every `correct`.
  - **« bref » / « ouais » decoys.** Wrong-register Choisir le ton options were often not natural French. Put "every option must be natural French" in the author prompt.
  - **Masculine check.** `lint.py` `MASC_SELF` now checks a Corriger line with its fix applied (`corrected()`), so Robin's masculine error word is allowed there.
  - **Grammalecte false positives.** Situations have no suppression list; reword instead (13 `late_d04` became « Plutôt vingt minutes. Désolée ! »).
  - **Audio-key clashes.** The planner's inflection tables gave the same key to a verb and its past participle (répare / réparé, commence / commencé, remplace / remplacé, coupe / coupé, annules / annulés). Use a `_past` / `_verb` suffix.
- **Book-wide gloss widenings this session:** mal, place, regarder ×3, fait, j'arrive, ça va, pas trop, rapporte, and the two "(wrong form)" glosses.

## 5. Commands and gotchas

```sh
# production audio for one module, retrying the API's 503s
for m in 14 15; do until python3 tools/situations/generate_audio.py --module $m; do sleep 10; done; done
python3 tools/situations/generate_audio.py        # plain run: also makes the firstSeen:null base-word clips
python3 tools/situations/lint.py                  # strict, with audio
```

- **zsh:** don't put a command in `$cmd` and run `$cmd`, because zsh doesn't word-split it. That bug silently skipped the first 11–15 audio run.
- **Base-word clips:** `--module NN` skips `firstSeen: null` words, so finish with one plain `generate_audio.py` run.
- **Gap clips:** a clip of a gap line speaks the answer (hard rule). The play button stays off until the gap is settled.
- Simulator: iPhone 18 Pro `48420336-…`. Phone install commands are in the content handoff §9.
