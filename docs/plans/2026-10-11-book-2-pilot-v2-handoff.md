# Book 2 handoff — dialogue pilot v2

**Date:** 2026-10-11
**Repo:** `/Users/yiwenwang/Documents/CMU/research/personal/carambole/carambole`
**Branch:** `book2-dialogue-pilot` (not merged, not pushed)
**Supersedes:** [the first Book 2 handoff](2026-10-11-book-2-handoff.md), which described the rejected café pilot.

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
