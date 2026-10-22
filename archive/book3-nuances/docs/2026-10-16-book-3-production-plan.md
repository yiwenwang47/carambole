# Book 3 production implementation plan

**Status:** implemented 2026-10-16. The execution record below and
`2026-10-16-book-3-production-handoff.md` supersede the unchecked planning
list, which is retained as the original sprint scope.

> **For agentic workers:** Execute the checked waves in order. Use subagents
> for independent module ranges and for a fresh review of each completed wave.

**Goal:** Ship the edited 20-module Book 3 course as a third book with its own
review progress and a short source-card study loop.

**Architecture:** Reviewed Test book cards feed deterministic production module
files. Five contiguous groups per module become FSRS elements. The existing
book shell and scheduler load those elements, while a dedicated Nuances session
renders and grades the four card formats. A new additive table rotates cards.

**Tech stack:** SwiftUI, Foundation, SQLite, Python 3 content tool, bundled JSON.

**Spec:** `docs/plans/2026-10-16-book-3-production-design.md`.

## Global constraints

- Keep all 550 card IDs and all 20 module outcomes; preserve visible French
  sources and four formats.
- Do not change migrations 1–5 or Book 1/2 progress. Add migration 6 only.
- Reuse shared `TooEasyGate`, control, and undo behavior.
- The whole card does not scroll; only its French source may scroll.
- No phone installation. Use the iPhone 18 Pro simulator for visual checks.
- Run every shell command through `rtk` per repository instructions.

## Wave 1 — editorial source

**Files:** `carambole/Debug/testbook_book3*.json`.

- [ ] Review each card in disjoint module ranges for French, source support,
  answer uniqueness, continuity, vocabulary staging, and repetitions.
- [ ] Run the Swift pilot model test and inspect all changed IDs.
- [ ] Resolve material repeated-task clusters before packaging.

## Wave 2 — production content and pure model

**Files:** `tools/nuances/module_groups_*.json`, `tools/nuances/package.py`,
`tools/nuances/test_package.py`, `carambole/Resources/Nuances/*.json`,
`carambole/Models/Nuance.swift`, `tools/nuances/NuanceModelTests.swift`.

- [ ] Write grouping metadata with five named groups and notes per module.
- [ ] Write a failing package test for module 01: all cards assigned once,
  stable IDs, four formats, lengths, and answer shape.
- [ ] Build module 01 with the converter; validate its output and Swift decode.
- [ ] Generate modules 02–20. Run the full content gate: 20 modules, 100
  groups, 550 cards, no duplicate IDs or unassigned cards.
- [ ] Add pure accepted-answer normalization, card selection, and the
  three-card/two-format mastery gate. Test each against concrete variants and
  history states.

## Wave 3 — persistence and book loading

**Files:** `carambole/Models/CoreDataManager.swift`,
`carambole/Models/BookCatalog.swift`, `carambole/Models/BookContent.swift`,
`carambole/Models/ContentLoader.swift`, and migration/model checks.

- [ ] Add version 6 `nuance_card_log` without altering old migration blocks.
  Upgrade a populated version 5 database and verify its old rows survive.
- [ ] Load all production modules into `Book → CourseModule → GrammarElement`
  with distinct `nu_` IDs, five groups per module, and card pools.
- [ ] Route Book 3 through the existing book settings, due queue, counts,
  unlocks, and FSRS state. Confirm IDs from other books never enter a Book 3
  session or count.

## Wave 4 — app session and release checks

**Files:** `carambole/Features/Nuance/*.swift`,
`carambole/Features/Drill/StudySessionView.swift`, shelf and module views,
plus focused session checks.

- [ ] Make a short learning visit and one-card-per-group review visit. Implement
  choice and typed grading, paraphrase self-check, feedback, retry, and
  `TooEasy` resolution.
- [ ] Add *Nuances* to the shelf and route learn/review/module/Today/history
  through the dedicated session. Keep the source block layout from the pilot.
- [ ] Build the app for the simulator; inspect modules 01 and 18, including a
  long source, a typed answer, wrong feedback, and the Too Easy state.
- [ ] Run the full content gate, model checks, migration check, app build,
  and `git diff --check`. Record any editorial limits before handoff.

## Review focus

- A valid French paraphrase missing from `accepted` must have an honest
  self-check path rather than a forced wrong grade.
- A reinstalled app with version 5 data must retain Books 1 and 2 progress.
- A cleared Too Easy group must become unseen again and leave the session queue.
- A module file with duplicate or missing cards must fail the content gate.
- A Book 3 due queue must never include an ID from the other two books.

## Execution record — 2026-10-16

- Editorial wave: all 20 Test book modules reviewed in three disjoint ranges;
  chronology, unsupported conclusions, and repeated tasks corrected. The pilot
  model accepts all 550 cards.
- Content wave: 20 production modules, 100 groups, and 550 cards packaged. The
  content validator and pure Swift model and loader checks pass.
- Integration wave: the third shelf entry, group progress, additive v6 card
  history, Nuances session, module details, and book-specific settings are in
  place. The v5-to-v6 SQL contract test preserves populated Book 1/2 rows.
- Visual wave: production cards from modules 01 and 18 fit the iPhone 18 Pro
  simulator. Module 18 uses the long microtext; module 01 uses typed input.
  The module 18 wrong-answer panel initially truncated the model answer; its
  source area now contracts after grading, and the answer wraps fully. The
  armed Too Easy state also fits.
- Audio: this first production version has no bundled speech, as set in the
  design. The registered Book 2 audio gate passes (6,459 clips, zero unresolved).
  Any later Book 3 speech addition must register an index and pass that gate.
- The final simulator Release build passed through `tools/release_build.sh` with
  the audio gate enabled. The content gate, model/loader/policy checks, migration
  contract checks, and `git diff --check` also passed.
