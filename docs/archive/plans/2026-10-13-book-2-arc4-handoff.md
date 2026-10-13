# Book 2 handoff: arc 4

> **Superseded as the start point by [2026-10-13 audio handoff](2026-10-13-book-2-audio-handoff.md).** §5 is the arc 4 session log.

**Written:** 2026-10-12, end of session.
**Repo:** `carambole/`, branch `main`, **not pushed** (ahead of origin by 87+ commits).
**Still binding:**
- [2026-10-13 next-session handoff](2026-10-13-book-2-next-session-handoff.md): §3 (how going back works now), §4 (arc 4 pipeline, order and lessons from arc 3), §5 (commands and gotchas).
- [2026-10-12 session log](2026-10-12-book-2-handoff.md): the "Arc 3" section is the pipeline in full, step by step.
- [2026-10-11 handoff](2026-10-11-book-2-next-session-handoff.md): §2 decisions, §4 pipeline, §6 commands.
- [Content handoff](2026-10-11-book-2-content-handoff.md): the rulebook. §9 has the Test book build and phone install commands.

## 1. Start here

**Arc 4: modules 16–20.** Use the same pipeline as arc 3:

1. Planner.
2. The user OKs the defaults.
3. Coordinator prep.
4. 2 authors per module.
5. Gloss conflict scan.
6. Assemble.
7. 4 judges per module.
8. Fixers.
9. Apply gloss widenings book-wide.
10. Vocab audit.
11. 9-card review set (v9).
12. Phone, if the user asks.
13. User verdict.
14. Production audio.

Read the lessons in the next-session handoff §4 before you write the author prompt:
- Run about 7 agents at a time.
- Authors and fixers check every Comprendre `correct`.
- Every Choisir le ton option must be natural French.
- Use `_past` / `_verb` audio keys for verb / past-participle pairs.

## 2. State

| Area | State |
|---|---|
| Content | 15 of 25 modules (1,800 items): authored, judged, fixed, assembled. |
| Audio | Complete for modules 01–15 (3,982 production clips). Strict `lint.py` passes. |
| Review sets | v7 (arc 2) and v8 (arc 3) are approved. |
| Going back | **Done and confirmed on the phone** (§3). |
| Phone | The Test book has v8 on the new carousel. The main Carambole app has NOT been reinstalled; install it only when the user asks. |

## 3. Fix this session: Book 1 carousel in Book 2 (`56af4b7`)

**Problem:**
- Book 2 had a one-card slide imitation for going back.
- The user rejected it and wanted Book 1's real carousel.
- It could not simply be ported. Book 2's card was drawn from about 20 session `@State` vars, so only one card could exist on screen.

**Fix:**
- **`Features/Situation/SituationCardView.swift` (new).**
  - One card: cue, chat, drill zone, footer, tooltip, card fit and DEBUG autoplay.
  - Its logic state is a `SituationCardState` value. The session owns it in `states[index]` and passes a binding.
  - A card rebuilt after it leaves the screen comes back exactly as it was. A pending `advanceSoon` still lands while the card is off-screen.
  - Transient UI state stays in the card's `@State`: tip, fit, tray height and shake.
- **`SituationSessionView`.**
  - The session keeps the queue, the cursor and frontier, results, mistakes, grading and the summary.
  - It renders Book 1's `visibleIndices` (cursor ± 1) at `(i - cursor) * w + dragOffset`, with `allowsHitTesting(i == cursor)`.
  - It uses Book 1's `resistedOffset`, `endDrag` (28 % or a fast flick), `pageSpring` and light haptic.
  - The drag axis is decided on the first change, so vertical chat scrolls still win.
  - The top bar stays fixed.
- **User decision (2026-10-12):** « Suivant » slides the next card in from the right, as in Book 1. A left swipe on a finished card also advances.
  - The new card sits one frame off-screen right before it animates in, so it slides rather than appearing in place.
  - `leavingIndex` is Book 1's `hideExplanationAt`: the card you leave keeps its live look while it slides out, with no « Révision » flash. Heading back clears it.
- **Removed:** `CardState`, `captureCard` / `restoreCard`, `swapCard`, `dragX`, and the fade-and-rise dialogue change.
- **Test book pilot (`Debug/SituationPilotView.swift`).**
  - It is now a ~60-line adapter (was 1,206 lines).
  - It decodes `testbook_situation.json` twice: as `PilotContent` (validation, element labels, glossary) and as `[SituationItem]`.
  - It runs the production session through `SituationSessionView(pilot:words:audioPrefix:onFinish:)`, with no grading or saving, `pilot2_` audio and `CB_PILOT_*` flags.
  - `PilotScenario.swift` and its tests are unchanged.
  - **Behaviour change:** the Test book now uses production rules (Choisir / Compléter allow one retry, and shuffles happen at render time). Review sets therefore play exactly like the book.
- **DEBUG flags:** `<prefix>INDEX STEP STAGE TIP AUTOPLAY BACK_AT SKIP_INTRO`. The prefix is `CB_SIT_` (book) or `CB_PILOT_` (Test book). `CB_SIT_ITEMS=id,…` forces the book's queue.
  - Book: `CB_OPEN_BOOK=book_fr_en_situation CB_START=learn`.
  - Test book: `CB_TEST_BOOK=1 CB_TB_OPEN=situation`.

**Verified:**
- Simulator frames:
  - Test book autoplay with `BACK_AT=2`: forward and back slides.
  - Book with `CB_SIT_ITEMS=sit_07_taste_s04,sit_07_hours_s04,sit_02_frequency_s04`: on the long Transformer card the chat stays put and the tray shrinks and scrolls. The outgoing card keeps its live look.
- The user tested the Test book on the phone and said "works".

**Lesson:** "like Book 1" means port Book 1's real code (memory `reuse-existing-motion`). Lifting per-card state into a value the session owns was what made a true carousel possible.

## 4. Open / later

- Reinstall the main Carambole app with the carousel only when the user asks.
- Écrire typing drill: later, in its own session.
- History page does not yet show attempt-log rows. VoiceOver is only partly labelled.
- `main` is not pushed.

## 5. Arc 4 progress log (2026-10-12 session)

- [x] Planner: `2026-10-13-book-2-arc4-plan.md` + 5 matrices. User accepted all §12 defaults.
- [x] Prep (`3702e9a`): modules.json 16–20; lint roles « Agent immobilier / Agente immobilière »; `MASC_SELF` + « je me suis » and couché, tombé, épuisé, trempé, convaincu, sûr (test added).
- **Gloss decision (Claude, user delegated):** existing glosses are correct for every line in 01–15 (checked by scan). Keep them; arc 4 avoids the plan §2.8 trap senses or adds longer phrase keys. Widen book-wide only where a new line truly needs the sense. User rule: **every gloss must be correct in every drill** — authors self-check; judges and a coordinator gloss-in-context pass verify.
- [x] Authors: all 10 done. batch 1 launched (16a, 16b, 17a, 17b, 18a, 18b, 19a); 19b, 20a launched as slots freed; 20b next. DONE: 19a, 19b, 20a, 16a, 16b, 17a, 17b, 18a, 18b.
- Gloss traps found while authoring (add to judge/fixer prompts): *raconte* "tell (me) (tu)" wrong in « je te raconte » (needs phrase key); *cuisine* "kitchen / cook(s)" wrong for *faire la cuisine*; *l'entrée* "the entrance" wrong for a starter; *je prends l'addition* (16 dinner_d03) reads oddly with "I'll have / I take"; wrong-form decoy « on votes » glossed "votes" (19 vote_d03/d08). If interrupted: relaunch halves whose drafts are missing or fail `lint.py --draft`.
- Book-wide widening applied: « que » → "that / which / than" (comparisons). Committed.
- `tools/situations/gloss_dump.py MODULE WORDS --moves a,b` prints every tappable line with each token's gloss: give judges their moves' dump; they must check every pair.
- Gloss todos for the coordinator pass: « il n'y a plus de » phrase key ("there's no more"); wrong-form decoys (« à le maison », « on votes ») show normal glosses — decide a convention; optional « je te prête » key (17b cheer_d01); *on y va* "let's go" on a question (18 better_d09); *il fait chaud* "it's hot" (17b).
- 17 uses *aïe* instead of *oh là là* (Grammalecte doublon flag).
- Gloss pass todos (book-wide, incl. 01–15): phrase keys « il n'y a pas » / « il n'y a plus (de) » / « il n'y a plus rien » (now "there isn't · not"), « il y avait » (16b). New keys need audio (plain generate_audio run).
- More gloss todos: « si j'étais vous » key ("if I were you"; 20a inplace_s02 shows j'étais = "I was"); 20a inplace_d02 « dans l'entrée » (hallway) vs gloss "the entrance" (fine?).
- Gloss todo: « rembourse » "refund / refunds" → widen to "pay back, refund" (19b share_d02 « Je te rembourse demain »).
- [x] Gloss conflict scan: 0 conflicts, 0 audio clashes. Assembled (`e28c8f2`): 20 modules / 2,400 items; lint --no-audio OK; Grammalecte 6,265 lines 0 flags; 87 tests; Swift model PASS. Fix: 04 invite_s01 decoy « ça vous dit, » → « vous voulez » (now taught in 19).
- [ ] Judges (20; 2 moves each; ~7 at a time). Prompt `/private/tmp/claude-501/arc4-judges/prompt.md` (judge.md + gloss-dump check of every token); dumps in `.../arc4-judges/dumps/NN.md`; findings `.../arc4-judges/findings/NN_m1_m2.md` → copy to `docs/archive/plans/arc4-judges/` when done. Pairs: 16 evening/order, out/dinner, met/late, mood/askback; 17 galere/what, react/sympathise, story/askback, cheer/help; 18 flats/rent, area/plan, bike/better, pros/decide; 19 propose/options, prefer/vote, compromise/confirm, book/share; 20 ask/should, inplace/reason, warn/weigh, formal/after. Batch 1 launched: all 16 + 17 galere/what, react/sympathise, story/askback.
- After arc 4: book-wide gloss sweep of 01–15 with the same dump check (user rule: every drill's glosses correct).
- Judges done: 16 ×4, 17 galere/what, react/sympathise. Running: 17 story/askback, cheer/help; 18 ×4; 19 propose/options, prefer/vote. Next: 19 compromise/confirm, book/share; 20 ×4.
- **Systemic gloss issues found by judges (fix book-wide in the coordinator gloss pass, all modules 01–20):**
  1. Negation doubled: n'-forms are glossed "is (not)", "have (not)", "don't like"… and *pas* = "not", so « n'est pas » reads "is (not) · not", « ce n'est pas grave » "is (not) · no big deal" (says the opposite). Plan: n'-forms get the plain verb + note, e.g. n'est = "is (n'est pas = isn't)"; ne / n' = "(ne … pas = not)"; phrase keys « ce n'est pas grave », « il n'y a pas », « il n'y a plus (de) », « ne marchait plus ».
  2. Passé composé with être: « je suis allée » reads "I am · gone". Consider widening être forms: suis = "am / (je suis allée = I went)", es, est, sommes, êtes, sont similarly.
  3. Phrase keys to add: il y avait, en ville, de la chance, bon week-end, ce n'est pas grave, si j'étais vous, il n'y a plus de.
  4. Widen: vas → "go / are going (to) / are doing (tu)", on va → "let's go / we're going (to)", votre → "your (polite / plural)", sort → "go out / goes out", pris → "taken, had, got", rentre → "go / come home", en boîte → "at / to a club, clubbing", rembourse → "pay back, refund".
- [x] Judges: all 20 done; findings in `docs/archive/plans/arc4-judges/`.
- [x] Fixers: all 10 done (`e57fcd2`, module 20 commit after).
- [x] Book-wide gloss pass (`763b66b`): spec `docs/archive/plans/arc4-judges/gloss_spec.json`, applied by `tools/situations/apply_gloss_spec.py` (55 widenings, 42 new base phrase keys). Reassembled; lint --no-audio OK, Grammalecte 6,272 lines 0 flags, 87 tests, Swift PASS. **New keys need audio** (plain `generate_audio.py` run) — strict lint fails until then.
- [ ] Gloss verification sweep over ALL 20 modules (user rule): fresh dumps `/private/tmp/claude-501/gloss-sweep/dumps/NN.md`, prompt `.../gloss-sweep/prompt.md`, findings `.../gloss-sweep/findings/NN.md`. Batch 1 (01–07) launched; then 08–14, 15–20. Then apply findings (second spec) and re-verify.
- Then: vocab audit, review set v9, user verdict, production audio 16–20 + new keys.
- [x] Gloss verification sweep 01–20 done: findings in `docs/archive/plans/gloss-sweep/NN.md` (~20 MUST, ~140 SHOULD; recurring: on + verb "we is", à + weekday order, le + day/matin, chez moi, il faut, pronoun le/la, de + verb, comma-spanning keys non plus / merci de). `gloss_dump.py` fixed to break phrases at ___ and free-standing punctuation like the app.
- [ ] Compile spec2 (agent → `/private/tmp/claude-501/gloss-sweep/spec2.json` + notes), apply with `apply_gloss_spec.py` (+ rewrites), reassemble, checks, re-dump and spot-verify.
- [x] Gloss sweep pass 2 applied (`abfbf56`): spec `docs/archive/plans/gloss-sweep/spec2.json` + notes; 57 widenings, 84 new keys, 1 rewrite (02 morning_d07 « Non ! Plus ___ »). All 24 MUST resolved, spot-checked in fresh dumps. Checks green. No existing 01–15 clip changed text.
- [x] Vocab audit: 324 new base entries; 115 single words not literally in Fondations — all inflections of taught words, decoys, parts of taught phrases or proper nouns (bord ← au bord de, souci ← pas de souci, saône, pralines…). No action.
- [x] Review set v9 (`d56babc`): sit_16_dinner_d01 sit_17_what_d03 sit_16_late_s03 sit_18_bike_d04 sit_19_vote_d03 sit_20_should_s02 sit_17_story_d05 sit_19_options_d02 sit_16_order_s04; review audio generated; pilot tests PASS; sim frames of cards 1, 4, 7 OK. Installed on the iPhone (Test book) 2026-10-12.
- [x] User verdict on v9 (2026-10-12): "v9 works" — approved. Then production audio 16–20 + all new base-key clips: `for m in 16 17 18 19 20; do until python3 tools/situations/generate_audio.py --module $m; do sleep 10; done; done` then a plain `generate_audio.py` (base keys, incl. ~125 new phrase keys for 01–20), then strict `lint.py`.
