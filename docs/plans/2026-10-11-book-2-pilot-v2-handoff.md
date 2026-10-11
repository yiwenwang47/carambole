# Book 2 handoff — dialogue pilot v2

**Date:** 2026-10-11
**Repo:** `/Users/yiwenwang/Documents/CMU/research/personal/carambole/carambole`
**Branch:** merged to `main` on 2026-10-11 (was `book2-dialogue-pilot`, now deleted); not pushed
**Supersedes:** [the first Book 2 handoff](2026-10-11-book-2-handoff.md), which described the rejected café pilot.
**Next session:** start from the [café handoff](2026-10-11-book-2-cafe-handoff.md). This file stays the reference for the pilot screen, the UI rules and review set v3. The branch was merged to `main` on 2026-10-11 and deleted.

## Read first

1. This file.
2. The [Book 2 action plan](2026-10-11-book-2-action-plan.md). The *Design rework* section and the *Interaction and content contract* section are current. The *Difficulty pilot checkpoint* section is history.
3. The [earlier Book 2 decision](../decisions/2026-10-10-next-book.md).
4. Reference mock (private artifact, playable): `https://claude.ai/artifact/WisTx5oe1Jq5ZW3h6SL6gN`. It shows eight café dialogues, six drill types, the Réviser model, palette colours and authoring rules. The Swift pilot now matches it, plus the later changes below.
5. Repo rules in `CLAUDE.md`. Simulator harness: `tools/sim/README.md`.

## Where things stand

The DEBUG **Test book** app (`wen.carambole.testbook`) runs the reworked pilot. It was last installed on the user's iPhone 18 Pro on 2026-10-11. To open it, go to **Test book → En situation · essai**.

The user approved the direction and asked for the changes listed below, which are all built and installed. They have not yet reported on a full play-through. Nobody has checked the audio on the phone yet.

The production Book 2 doesn't exist yet. There is no shelf entry, no `Resources/Situations/`, no per-book storage and no attempt log. The pilot state lives only in memory and never touches Book 1.

## User decisions (all binding)

**Why Codex's pilot was rejected:** the user said "layout was bad, problems were too difficult, I don't know half of the words."

- **Layout: one locked chat card.**
  - A one-line English cue at the top, 21 pt ink.
  - Server lines are left bubbles, white with an ink outline and a round play button (`quietFill`).
  - Learner lines are right bubbles in the palette's `tileOn`.
  - The drill area sits below a hairline. The Vérifier/Suivant button uses `DrillButtonStyle`.
  - Only the chat area scrolls; the card never scrolls as a whole.
  - All colours come from `AppTheme`, so they follow the palette the learner picked.
- **New words:**
  - The user is willing to learn new words, but the app must teach them.
  - New words are underlined. Tapping any word or set phrase shows its English in a dark tooltip right above that word, which hides after about 2.6 s.
  - **Never show English automatically.** A version with English printed above new words was rejected ("why did you do that").
  - The finished dialogue lists its new words.
- **Dialogues:** short, 1–3 lines including the learner's, ≤10 words per line, with 1–2 drills each.
  - Two drills in one dialogue are never the same type.
  - Répondre and Choisir never appear together.
- **Six drill types:**
  - **Comprendre:** 2 choices.
  - **Répondre:** build the reply from magnets inside your own bubble.
  - **Choisir:** pick 1 of 3 replies — one right, one wrong French, one good French that doesn't fit.
  - **Compléter:** fill the gap with 1 of 3 words.
  - **Corriger:** tap the wrong word, then pick its fix from 3.
  - **Mot:** pick the meaning of a new word, 1 of 3.
- **Dropped:** the optional speak-aloud step.
- **Réviser, planned:**
  - The move stays the review unit, with Book 1's review schedule.
  - Each review uses an unseen dialogue, with a different drill type from last time.
  - Mastery = 3 distinct dialogues across at least 2 drill types.
- **Size, planned:** 25 modules × 8 moves × 10 dialogues = 2,000 dialogues, about 3,000 drills.
- **Wrong answers must be recorded.** The learner is asked to correct their own answers.
  - A wrong attempt stays visible during the retry.
  - The finished dialogue lists "Vos erreurs".
  - The session ends on a "Séance terminée" summary with every mistake and its reason.
  - In production, each attempt goes to a `situation_attempt_log` table (see the plan).
- **Corriger:**
  - Never cross out the word being fixed ("too complicated").
  - No colour flash either. The word gets a white highlight on the lime bubble until it's fixed.
  - A wrong tap shakes the word instead of flashing.
- **Motion:** smooth and "slightly longer" than the first smooth version. Current timings are below; don't speed them up.
- **Order:** Corriger is the first dialogue in the pilot so the user can try it first.
- **Text:** the French text is always visible from the start. Audio is replay only.

## Book 2 UI rules (moved from assistant memory, binding)

The user set these on 2026-10-11 while testing the pilot on the phone. They apply to all Book 2 UI work, pilot or production.

- **English only on tap.** A tap shows the English in a tooltip right above the tapped word. Never print English above words automatically ("english shouldnt immediately appear above the french! tap to show. come on why did you do that"). New words may be underlined.
- **The app must teach new words.** Many new words are fine if the app teaches them. Logic puzzles and arithmetic inside questions were rejected.
- **Learner bubble colour comes from the active palette** (`tileOn`), not a fixed colour. "Sender's bubble" means the learner's own messages.
- **No strike-through** on a word being corrected ("too complicated"). **No colour flash** either: the palette `tint` read as a pale-sky flash. Use the white highlight.
- **Motion:** smooth, then "slightly longer". Settle about 0.7 s, fade-out 0.16 s, rise 0.45 s. Don't speed them up.
- **Wrong answers are recorded and shown back**, because the learner is asked to correct their own answers.

## Drill mix: not dialogues only (user direction, 2026-10-11)

Book 2 must not be dialogue drills only. Sessions mix the chat dialogues with **standalone sentence drills reused from Book 1's drill types**, with harder questions.

**Harder means:** longer sentences (8–14 words), two grammar points in one item, closer distractors (same word in another gender, person, tense or register), less scaffolding (typing instead of tiles). **Harder never means** logic puzzles, arithmetic or untaught words. Every word in a standalone drill is either in *Fondations*, in Book 1, or already taught in Book 2.

Book 1 types to reuse (`InputMode` in `carambole/Models/Exercise.swift`):

| Book 1 type | Book 2 use | What makes it harder |
|---|---|---|
| `buildFromTokens` | Build a full sentence from an English prompt, outside the chat | Longer sentence; decoy tiles are near forms (`vais`/`va`, `lui`/`leur`, `le`/`la`); Book 1's second-try flow stays |
| `freeText` | Type a short reply or a missing chunk, accent-strict | No tiles at all; 2–5 words; only after the words have been seen in tiles |
| `multipleChoice` | Pick the French that fits the cue | All 3 options are good French; only one fits the register or situation (tu/vous, polite/blunt) |
| `spotError` | One wrong word in a standalone sentence | Errors that need context: agreement across a clause, wrong register for the cue, wrong tense for the time marker |

Mixing rules:

- Never two items of the same type back to back.
- A standalone drill reuses the module's situation and words, so the session still feels like one scene.
- Standalone drills use the same card, button, colours, motion and mistake log as dialogues. Wrong attempts go to the same attempt log and summary.
- **Ratio: 1 standalone drill per 2 dialogues** (user decision, 2026-10-11).
- A standalone drill uses only words already taught before it in the session or module.

**Approved new types (2026-10-11):**

1. **Transformer.** Rewrite a line one step: tu → vous, present → passé composé, affirmative → negative. Code computes the answer; build or type it.
2. **Mot en retour.** Reverse of Mot: English shown, pick or type the French word taught earlier in the module.

**Dropped ideas:** Remettre en ordre, Écouter puis choisir, Réplique libre limitée.

**Next:** mockup first, in the style of the reference mock, before any Swift work. Drill-mix mock v1 (private artifact, playable): `https://claude.ai/artifact/8A6hQgxpcQo1Ud9hyQnvGv`. Séance 1 has 8 dialogues and 4 standalone drills (Construire, Écrire, Choisir le ton, Corriger). Séance 2 shows Transformer and Mot en retour. Waiting for the user's review.

## Content direction (2026-10-11)

See *Content direction* in the action plan: recurring Lyon cast, varied channels, social and culture moves, mostly standard French with spoken forms marked `*` in the tooltip, no texting abbreviations, both genders accepted in learner lines. Next: author the full café module with Karim, play it in Test book, then freeze the schema.

## Review set v3 (installed 2026-10-11)

The Test book pilot now holds a small review set instead of the old 8 café dialogues (those are in git history before this commit). It has 9 cards: 6 dialogues and 3 standalone drills in the order D D S D D S D D S. It uses the Lyon cast, the channels and the spoken register. The user will review this set, not a full module.

| # | Card | Shows |
|---|---|---|
| 1 | Comme d'habitude (Karim) | Comprendre + Répondre, cast name, history |
| 2 | Bonjour d'abord | culture move, Mot + Compléter |
| 3 | Choisir le ton (standalone) | Book 1 multiple choice, register |
| 4 | Faire répéter | spoken *y a*, *du coup* with `*` glosses |
| 5 | Les copains (group chat) | two named speakers, *ouais*, *carrément* |
| 6 | Transformer (standalone) | grey "Vous · avant" line → passé composé |
| 7 | Texto · Léa | text channel, *t'es*, gender-free *Pardon* |
| 8 | On peut se tutoyer ? | register switch, twist follow-up |
| 9 | Mot en retour (standalone) | gap in Karim's line, English → French |

Contract changes (`PilotScenario.swift`, JSON):
- Turn `name` (speaker label) and `source` (grey line to rewrite).
- Dialogue `place` (label above the cue), `standalone` (drill label; no follow-up, 0–2 lines, one drill) and `followUpBy`.
- A gap may sit in any line.
- Spoken glosses start with `* `.
- Lone `?`/`!` attach to the word before with a no-break space.

Audio: cast voices are Chirp 3 HD: Karim `Charon`, Théo `Achird`, Léa `Aoede`. Unnamed speakers use Neural2-G. 14 clips were generated and the 16 old clips removed.

Checks: 10 Python content tests and the Swift contract test pass. I looked at simulator screenshots of every card type. `CB_PILOT_AUTOPLAY=wrong` plays all 9 cards through to the summary. Not checked: real taps, audio on the phone, and the Écrire typing drill, which isn't built in Swift.

## Pilot behaviour (as built)

| Moment | Behaviour |
|---|---|
| Right answer | Stays on screen 0.7–0.75 s (1.1 s after a miss, 1.7 s after two missed choices). Input is locked meanwhile (`advanceSoon`). |
| Next drill | Old drill area fades out in 0.16 s. The new one rises 14 pt over 0.45 s, starting at +0.16 s (`swap` transition). |
| Reply bubble settles | Tiles swap to text in place with no crossfade. The fill becomes `tileOn`, or grey if missed. |
| Server follow-up | Appears 0.45 s after the last drill. |
| Next dialogue | Everything fades out in 0.24 s, the content swaps, then rises over 0.5 s (`.smooth(0.5)`). |
| Placed tiles | Spring in (0.32 s), keyed by tile so a row wrap doesn't leave a ghost. |
| Wrong reply | The correct start stays placed (Book 1's second-try pattern). The note quotes the wrong attempt. |
| Wrong choice | Stays dashed with the palette's `fragile` colour. The why-line or miss note shows. |

Rating line: "Du premier coup" means right first time (good). "Réussi avec un essai de plus" means right after a miss (hard). "Pas trouvé. On le reverra bientôt." means missed twice (again). A dialogue is rated by its worst drill.

## Files

| File | Purpose |
|---|---|
| `carambole/Debug/SituationPilotView.swift` | Chat card, six drills, tooltip, transitions, mistake log, summary, simulator flags. |
| `carambole/Debug/PilotScenario.swift` | `PilotContent` / `PilotDialogue` / `PilotDrill` contract, validation, `PilotText.segments` (longest phrase first, punctuation kept outside), `correctPrefixCount`. |
| `carambole/Debug/testbook_situation.json` | Glossary and 8 café dialogues, Corriger first. |
| `carambole/Debug/DrillDemo.swift` | Test book row text. |
| `carambole/Resources/Audio/pilot2_*.mp3` | 16 clips: `pilot2_<id>_t<n>` (server lines) and `pilot2_<id>_f` (follow-ups), voice `fr-FR-Neural2-G`. |
| `tools/pilot/test_content.py` | 7 content tests: limits, types, choices, buildable replies, gap/error lines, glosses, audio. |
| `tools/pilot/PilotScenarioTests.swift` | Swift contract and segmentation test. Pass the JSON path as an argument. |
| `tools/pilot/generate_audio.py` | Google TTS for server lines and follow-ups. Skips files that already exist. |

Simulator flags (with `CB_TEST_BOOK=1 CB_TB_OPEN=situation`):

| Flag | What it does |
|---|---|
| `CB_PILOT_INDEX=n` | Opens dialogue n. |
| `CB_PILOT_STEP=n` | Jumps to drill n. |
| `CB_PILOT_STAGE=fill` | Shows a filled answer. |
| `CB_PILOT_STAGE=done` | Shows the finished state. |
| `CB_PILOT_TIP=<gloss key>` | Pins a tooltip open. |
| `CB_PILOT_AUTOPLAY=1` | Answers every drill correctly. |
| `CB_PILOT_AUTOPLAY=wrong` | Misses once per dialogue first. |

Simulator taps can't be automated here. Use autoplay with `simctl io recordVideo`, then `tools/sim/sim.sh frames` and `tools/sim/sheet.py`, and look at the frames.

## Checks

- 7 Python content tests and the Swift contract test pass.
- The Debug simulator build and the signed device build pass.
- I looked at simulator frames (30 fps recordings) for:
  - every drill type,
  - tooltips on a first-line word, a second-line word and an edge word,
  - drill-to-drill and dialogue-to-dialogue transitions,
  - a tile wrapping to a second row,
  - the reply settling,
  - the wrong-answer notes, "Vos erreurs" and the summary,
  - the Corriger highlight (no sky flash).
- **Not checked:**
  - The pilot in the Iris or Surimpression palettes.
  - Real hand taps on the simulator. The user taps on the phone.
  - The wrong-tap shake (autoplay's wrong tap doesn't hit a real word).
  - The audio on the phone.

Device: iPhone 18 Pro, UDID `00008160-001A09920AA0000A`, team `QMV4SPL476`. Simulator: iPhone 18 Pro, iOS 27.0, `48420336-6EA1-4545-A656-1DF72A82089E`. Never test, record or profile on the phone. It is only for installs the user asks for.

## Next steps

1. Get the user's feedback on the full pilot play-through and the audio, then adjust. Don't bring back auto English, hidden text, strike lines or faster motion.
2. If the user wants the real book, follow the action plan tasks in order:
   - **Task 1:** schema and lint, built from `PilotContent`.
   - **Task 2:** book selection with separate per-book progress. Fix the global overflow query first.
   - **Task 3:** move the pilot card into the real drill loop, plus `situation_attempt_log`.
   - **Task 5:** the café module at 8 moves × 10 dialogues.
   - Bulk authoring only after that.
3. Keep Book 1 IDs, JSON, audio keys and settings keys unchanged. Test with an existing database as well as a fresh install.
4. Keep this file and the plan up to date after each milestone.

## Commands

```sh
rtk python3 -m unittest tools/pilot/test_content.py
rtk proxy swiftc -D DEBUG carambole/Debug/PilotScenario.swift tools/pilot/PilotScenarioTests.swift -o /tmp/cb-pilot-scenario-tests
rtk proxy /tmp/cb-pilot-scenario-tests carambole/Debug/testbook_situation.json
rtk xcodebuild -project carambole.xcodeproj -scheme carambole -configuration Debug -destination 'id=48420336-6EA1-4545-A656-1DF72A82089E' PRODUCT_BUNDLE_IDENTIFIER=wen.carambole.testbook INFOPLIST_KEY_CFBundleDisplayName='Test book' CODE_SIGNING_ALLOWED=NO -derivedDataPath /tmp/cb-book2-pilot-sim build -quiet
rtk xcodebuild -project carambole.xcodeproj -scheme carambole -configuration Debug -destination 'id=00008160-001A09920AA0000A' -allowProvisioningUpdates DEVELOPMENT_TEAM=QMV4SPL476 PRODUCT_BUNDLE_IDENTIFIER=wen.carambole.testbook INFOPLIST_KEY_CFBundleDisplayName='Test book' -derivedDataPath /tmp/cb-book2-pilot-device build -quiet
xcrun devicectl device install app --device 00008160-001A09920AA0000A /tmp/cb-book2-pilot-device/Build/Products/Debug-iphoneos/carambole.app
xcrun devicectl device process launch --terminate-existing --device 00008160-001A09920AA0000A wen.carambole.testbook
```

Delete `/tmp/cb-book2-pilot-*`, recordings and frame folders when you're done. Audio regeneration needs `gcloud auth application-default` credentials.
