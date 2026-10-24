# Carambole — French trainer (iOS, SwiftUI + raw SQLite)

Two books on a library shelf. **Fondations** (`book_fr_fondations`, Book 1):
grammar drills, 25 modules × 20 elements, tap-to-build / multiple choice / short
typing / spot-the-error. **En situation** (`book_fr_en_situation`, Book 2, DONE
2026-10-13): short chat dialogues, 25 modules, 3,000 items, 6,459 voiced clips.
**Book 3 (*Nuances*) is ARCHIVED (user, 2026-10-22):** removed from the app,
all material kept in `archive/book3-nuances/` (README there explains what
stayed and how to restore). Do not re-add it unless the user asks.
Older history is in `docs/archive/` and git log.

## Start here

- **Vocab swipe book (*Mots*, branch `vocab-swipe`, 2026-10-23):** start at
  `docs/plans/2026-10-23-vocab-swipe-handoff.md`; spec in
  `docs/plans/2026-10-23-vocab-swipe-plan.md`. Mock + review set v1 approved;
  engine (phase 3) and views (phase 4, `Features/Vocab/`, on the shelf) built;
  next is bulk content (phase 5).
- **Status + phone checks:** `docs/plans/2026-10-13-book-2-release-handoff.md`.
  Next, only when asked: the Écrire typing drill, in its own session.
- **Book 2 rulebook** (cast, voices, JSON shape, authoring steps):
  `docs/plans/2026-10-11-book-2-content-handoff.md`; tools in
  `tools/situations/README.md`.
- **Languages home (2026-10-14):** root is `Features/Languages/LanguagesView.swift`
  (Specimen layout) → `LibraryView(language:)`; marks in
  `DesignSystem/LanguageMark.swift` (Cut paper default, Script sticker; picked
  under Colors). App text English, book text in the book's language. Decisions:
  `design/studio/PREFERENCES.md`; mocks + drag editor: `design/studio/`
  (`python3 design/studio/server.py`).
- **Book marks (2026-10-14):** `DesignSystem/BookMark.swift` (Fondations = seed,
  En situation = guillemet «), same recipe as the language marks, "Pale" face;
  mock `design/studio/books.html`, votes in `design/studio/PREFERENCES.md`.
- **Design:** `design/UI_REDESIGN_HANDOFF.md` (white ground, ink text, colour on
  objects, pale capped fills). Code in `carambole/DesignSystem/Theme.swift`.
- **Book 1 drill types:** `docs/plans/2026-10-10-drill-types-design.md`.
- **Scheduling:** `docs/plans/2026-06-21-fsrs-mastery-design.md`.
- **Star = die-cut card (2026-10-14):** `DesignSystem/StarCard.swift`, loops in
  `Resources/StarVideos/` (`tools/star_video/README.md`).
- **Star + ring + stutter:** `docs/plans/2026-10-09-star-video-handoff.md`,
  `2026-10-10-ring-star-glow-handoff.md`, `2026-10-09-stutter-handoff.md`.
  Ring: bead leads, maîtrisé right behind it, en cours behind that
  (fixed 2026-10-14 for low %; test with `tools/sim/progress_db.py`).
- **Book 2 card slide (2026-10-15):** `SituationText.Matcher` indexes the
  glossary once per session. The Test book simulator profile and phone install
  are in `docs/plans/2026-10-13-book-2-release-handoff.md` §8.
- **Book 2 drill layout (2026-10-15):** the Test book simulator check and
  Release phone install are in that handoff §10. The user approved the layout.

## Hard rules

- **"Clean up" means finish integration:** merge the finished work, push the
  resulting branch, delete finished branches and worktrees, and remove unneeded
  cache files. Verify the merged tree before removing its source branch.
- **Audio is a release gate for every production book with bundled speech.**
  Register its situation manifest or `{key, text, voice}` clip index in
  `tools/situations/audio_books.json`. Run `tools/release_build.sh` for Release
  builds: it runs `audio_release_gate.py` across every registered book and fails
  for missing, corrupt, silent, or excessively padded/paused clips. Generate
  and repair before building. The signal check cannot judge pronunciation or
  intonation; use an exact-text TTS override and listen when a line sounds wrong.
  The user selected `fr-FR-Studio-A` for `sit_04_thank_d03_t0`; preserve the
  per-clip voice override and `/setɛ/` SSML pronunciation on regeneration.
- **"Trop facile" in every book, one logic (user, 2026-10-13).** Arm on a card,
  still answer it; a clean answer grades .easy + suspends (instant maîtrisé, undo
  pill); anything else cleans the element's records; either way the session moves
  to the next element. **Book 2 (user, 2026-10-22):** the gate is armed on ONE
  drill and resolves on that drill alone; the card's other drills still play and
  grade the element normally (`SituationTooEasy.gradedOutcome`). Shared code: `Features/Drill/TooEasy.swift` (`TooEasyGate`,
  `TooEasyControl`, `.tooEasyUndo`). Book 1: `DrillView`/`DrillSessionView`.
  Book 2: `SituationCardView`/`SituationSessionView` + `SituationTooEasy`.
  **Mots (2026-10-23):** no `TooEasyControl`; swipe up on a card IS trop facile
  (resolved at once, clean by definition), and a word armed by tapping its
  Leçon-page row resolves on its first swipe (clean right → removed; peek or
  left → cleaned, then a normal word). `VocabQueue` → `VocabStudy.commit` →
  `TooEasyGate.resolve`; pill via `.tooEasyUndo(edge: .bottom, onUndo:)`.
  A new book or session view reuses these; never fork the logic.
- **The drill card never scrolls as a whole.** Book 1 can scroll its word-bank
  tray (`MagnetBoard.bankTray`); text uses `minimumScaleFactor`. In Book 2, only
  the chat scrolls. The purple reply bank shows all tiles and stays fixed.
- **Book 2:** never show English automatically (tap only; a tap elsewhere closes
  it), never strike through words, keep the current transition timing, every tap
  gloss must fit its sentence (`tools/situations/gloss_dump.py`), review content
  in small sets (~9 cards).
- **Answer + extra tile is wrong, no retry (user, 2026-10-17).** A build that
  spells the whole answer and adds tiles after it grades wrong at once; the
  second try is only for a wrong start or middle. Book 1:
  `DrillEngine.isAnswerPlusExtra`; Book 2: `SituationDrill.isAcceptedPlusExtra`.
- **Typing answers carry no punctuation** (`. , ? ! ; : « » … " ( )`). Enforced by
  `Exercise.isTypeable` (a punctuated answer stays picked) and `tools/lint_topics.py`.
- **Rendered-surface grammar.** Audit a drill by reading the blank filled with the
  answer as final French (« Je ___ » + « habitais » shipped as « Je habitais »).
  Prompts pre-elide (`J'___`) when every candidate starts with a vowel or mute h.
  `lint_topics.py` checks elision, contractions, `si il` → `s'il` (extend
  `H_ASPIRE_PREFIXES` for new aspirated-h words); `deep_lint.py` (Grammalecte,
  `tools/vendor/`) catches agreement and conjugation, gated by
  `tools/deep_lint_suppressions.json` (read the sentence aloud before adding).
  Both run from a PostToolUse hook after edits to `Resources/Topics/*.json`.
- **Prompt self-sufficiency.** Every drill is answerable from the prompt + visible
  cue alone. English "it" has no gender: put the referent in a setup question
  (`Construis la réponse : « Vous vendez la voiture ? » — « We sell it. »`).
  Number, tu/vous and person must be recoverable too. `gender_ambiguity_errors`
  in `lint_topics.py` checks the clause-final "it" case.
  **Book 2 (user, 2026-10-18):** dialogue cards hide the English cue, so every
  fact an answer needs goes in the drill prompt (numbers as digits). Book-wide
  facts (Robin, a woman, from Eugene, Oregon) show once on the Leçon intro
  (manifest `persona`). `tools/situations/lint.py` fails cue-only answers.
- **Token banks:** authored order doesn't matter (`Exercise.displayBank` shuffles
  per id, never in answer order). Bank ≈ 1.6× answer length with grammar-trap
  distractors (min +2); bulk edits via `tools/distractors/{extract,apply}.py`.
- **Schema migrations** (`CoreDataManager.migrate()`, now `user_version` 6): add
  a new `if version < N` block, additive only (`ADD COLUMN`, `CREATE TABLE IF NOT
  EXISTS`); never edit an earlier block, never DROP a user-data table. User data
  survives reinstalls; only deleting the app wipes it.

## Architecture

- **Content** is in-memory from bundle JSON. Book 1: `Resources/Topics/` +
  `manifest.json` (`ContentLoader`). Book 2: `Resources/Situations/` +
  `situations_manifest.json` + one `words.json` glossary; module JSON is built
  from `tools/situations/drafts/` by `assemble.py` (keep the drafts).
- **Grading:** every answer grades its ELEMENT with FSRS-6 (`Core/FSRS.swift`,
  `Core/ElementGrader.swift`). An element is maîtrisé once stability passes 21
  days (sticky `graduated_date`). Book 2 also needs correct answers on 3 distinct
  items covering 2 drill types (`SituationMastery`).
- **Tables:** `review_status` (per element), `review_log`, `mastery_log`,
  `situation_item_log`, `situation_attempt_log`, and the unused `nuance_card_log`
  (v6, kept from archived Book 3). Each book
  has its own progress, history, due queue and settings (`settings.<book id>.*`).
- **Audio:** `Core/Speaker.swift`, bundled MP3 by content hash (Xcode flattens
  `Resources/Audio/*` to the bundle root). The silent star video keeps the audio
  session ACTIVE, and changing the category on an active session stops Apple
  Music. So: `.ambient` outside clips; per clip release → `.playback` /
  `.default` / `[.mixWithOthers, .duckOthers]` → activate; afterwards
  `setActive(false, .notifyOthersOnDeactivation)` → `.ambient`. Clips must be
  equal loudness (`tools/situations/normalize_audio.py`).
- **Folders:** `Features/{Library,Book,Today,Drill,Situation,Vocab,History,Settings}`,
  `Core/`, `Models/`, `DesignSystem/`, `Debug/` (DEBUG-only harness + Test book).

## Build and check

Xcode 16 synchronized folders: drop `.swift` files in `carambole/`, no
`project.pbxproj` edits. No XCTest target; checks are builds, launch self-tests
and the tools below. Use explicit device ids (name destinations break).

```bash
# simulator build (iPhone 18 Pro, iOS 27.0 — the only runtime installed)
xcodebuild build -project carambole.xcodeproj -scheme carambole \
  -destination 'id=48420336-6EA1-4545-A656-1DF72A82089E' -quiet CODE_SIGNING_ALLOWED=NO
```

- **Simulator checks:** read `tools/sim/README.md` first (`tools/sim/sim.sh`
  build/install/load-db/launch with `CB_*` flags/remote/record/frames/clean).
  Look at the frames, not pixel counts. Delete recordings, builds and test apps
  afterwards. Never use xctrace/Instruments casually (leftover `.ktrace` files
  once filled 83 GB).
- **Book 1 lints:** `python3 tools/lint_topics.py`, `tools/deep_lint.py`,
  `tools/bank_lint.py`.
- **Book 2:** `python3 tools/situations/lint.py` (strict, with audio);
  `python3 tools/situations/audio_audit.py` (hard audio gate and playable
  report); `python3 tools/situations/repair_audio.py --apply` shortens
  excessive quiet gaps without changing spoken samples;
  `python3 -m unittest tools/situations/test_lint.py tools/situations/test_tools.py tools/pilot/test_content.py tools/situations/test_normalize_audio.py tools/situations/test_audio_audit.py tools/situations/test_audio_release_gate.py tools/situations/test_repair_audio.py`;
  model tests: `swiftc carambole/Models/Situation.swift tools/situations/SituationModelTests.swift -o /tmp/t && /tmp/t carambole/Resources/Situations`.
- **Content pipeline tests:** `cd tools && python3 -m pytest content_pipeline -q`.
- **Phone** (iPhone 18 Pro `00008160-001A09920AA0000A`, team `QMV4SPL476`,
  bundle `wen.carambole`). Install only when the user asks. The user tests on the
  phone; Claude never tests, records or profiles there. The 2026-10-22 Release
  build (`6e454f78`, per-drill Trop facile) is Books 1 and 2 only (Book 3 archived). Phone behavior is
  still for the user to check.
  ```bash
  CARAMBOLE_AUDIO_PYTHON=/path/to/python-with-numpy-scipy-lameenc \
    tools/release_build.sh \
    -destination 'id=00008160-001A09920AA0000A' -allowProvisioningUpdates \
    DEVELOPMENT_TEAM=QMV4SPL476 -derivedDataPath /tmp/cb-device build -quiet
  xcrun devicectl device install app --device 00008160-001A09920AA0000A \
    /tmp/cb-device/Build/Products/Release-iphoneos/carambole.app
  ```
  Release drops `CB_*` flags and the Test book files (`EXCLUDED_SOURCE_FILE_NAMES`).
  Debug builds log audio session steps to `Documents/audio_diag.txt`
  (`Debug/AudioDiag.swift`); after the user reproduces a bug, pull it with
  `xcrun devicectl device copy from --domain-type appDataContainer --domain-identifier wen.carambole --source Documents/audio_diag.txt --destination <path>`.
  Test book (hand testing, separate data): add
  `PRODUCT_BUNDLE_IDENTIFIER=wen.carambole.testbook INFOPLIST_KEY_CFBundleDisplayName='Test book'`
  to a Debug build. The simulator Test book was uninstalled after the Book 2
  layout check. Build it again when needed.

## Open items

- ~1,055 Book 1 `explanation` fields are in English:
  `docs/handoffs/2026-10-10-french-explanations-in-english.md`, finder
  `tools/explanation_lang.py`.
- The Écrire typing drill for Book 2 (own session).
- `SwipeBackGuard` (`Core/SwipeBackModifier.swift`) is not yet on Today rows,
  colour options or module-detail buttons.
- Page-switch stutter leads (75–155 ms freeze at push/pop) remain in the
  stutter handoff. The separate Book 2 card-slide stutter was fixed on 2026-10-15.
- `upsertReviewStatus` binds `first_seen_date` from `lastReviewDate` (masked by
  COALESCE; low impact).
