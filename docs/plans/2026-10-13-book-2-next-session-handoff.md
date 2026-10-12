# Book 2 handoff: start here next session

**Written:** 2026-10-12, end of session.
**Repo:** `carambole/`, branch `main`, **not pushed**.
**Session log:** [2026-10-12 handoff](2026-10-12-book-2-handoff.md), with every step and decision in order.
**Still binding:**
- [2026-10-11 handoff](2026-10-11-book-2-next-session-handoff.md): §2 decisions, §4 pipeline, §6 commands.
- [Content handoff](2026-10-11-book-2-content-handoff.md): the rulebook.

## 1. Start here

1. **Carousel for going back (user decision; do it first).**
   - The user wants Book 1's real carousel in Book 2. They tried the one-card slide (option 2, now on the phone) and said "nah let's do 1".
   - The plan is in §3.
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

## 3. Task: Book 1 carousel in Book 2

**What exists now** (`0761e3f`, `36c23cd`):
- Each finished card is saved as a `CardState` in `finishedCards[index]` when you leave it (`nextDialogue`).
- `live` holds the card in play while an earlier one is shown.
- `captureCard()` / `restoreCard()` copy between the session's `@State` and a `CardState`.
- ‹ › chevrons sit by the counter. « Révision · … » is the place label in review, and the footer says « Suivant » / « Reprendre ».
- `dragX` slides the single card. The thresholds, rubber-band, spring and haptic match Book 1.
- Debug flag: `CB_PILOT_AUTOPLAY=1 CB_PILOT_BACK_AT=n` plays to dialogue n, then goes back.

**Why it can't simply be a carousel:**
- Book 1 (`Features/Drill/DrillSessionView.swift`, `carousel`, `dragGesture`, `endDrag`, `resistedOffset`) renders each drill as its own self-contained `DrillView`, so the neighbours sit side by side at `(i - cursor) * w + dragOffset`.
- Book 2's card is drawn straight from about 20 session `@State` vars, so only one card can exist on screen.

**Plan:**
1. Extract the card into its own view.
   - Make a `SituationCardView` with all its per-card state (step, finished, slot, gapText, placed, …) as its own `@State`, taking `Card` (production) or `PilotDialogue` (pilot).
   - Pass callbacks for grading, logging mistakes and finishing.
   - The session keeps the queue, `results`, `mistakes`, the summary, and the history and cursor.
   - Watch out: card fit (`SituationCardFit`, `fit.*` geometry), the tip overlay, `locked` / `advanceSoon` timing, `autoSpeak`, and the DEBUG launch flags (`CB_SIT_*`, `CB_PILOT_*`). They all live in the card today.
2. Do the pilot and the production view in the same way. They are near copies; consider one shared card with a small adapter instead of two copies.
3. Port Book 1's carousel:
   - Render `visibleIndices` (cursor ± 1), each card offset by `(i - cursor) * w + dragOffset`, with `allowsHitTesting(i == cursor)`.
   - Use the same `resistedOffset`, `endDrag` thresholds and haptic.
   - Cards behind the frontier are read-only: they show their finished state, mistakes and « Révision ».
4. Keep the top bar (✕, progress, ‹ n/N ›) fixed. Only the card moves; Book 1 does the same.
5. Vertical chat scroll must still win. Decide the axis on the first drag change (the current code does this with `dragIsHorizontal`).
6. Then delete `CardState`, `captureCard` / `restoreCard`, `swapCard` and `dragX` if the new card view makes them redundant.
7. Verify:
   - Build. Record the simulator with `CB_PILOT_AUTOPLAY=1 CB_PILOT_BACK_AT=2` and look at the frames (`tools/sim/frames.swift`; no ffmpeg on this machine; PIL is available for contact sheets).
   - Check the card fit on a long dialogue plus a reply tray (memory: the card never scrolls whole; only the tray shrinks).
   - Install the Test book only when the user asks. Never test or record on the phone.

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
