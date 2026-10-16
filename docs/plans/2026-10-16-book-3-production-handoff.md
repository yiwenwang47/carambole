# Book 3 production handoff

**Date:** 2026-10-16  
**State:** *Nuances* is integrated as the third French book in the app. This is
a text-only production version; it has not been installed on the user's phone.

## What shipped in the repository

- Book ID `book_fr_nuances`; 20 ordered modules (`nu_01`–`nu_20`), five review
  groups per module, 100 FSRS elements, and 550 cards. The four formats are
  word in context, dialogue, microtext, and rewrite. Every card keeps its
  French source visible.
- The 550 DEBUG Test book cards received an editorial pass across all modules.
  `tools/nuances/package.py` converts them with the named group metadata into
  `carambole/Resources/Nuances/nuances_manifest.json` and 20 module files.
- *Nuances* appears on the French shelf and uses the existing book, module,
  Today, history, and settings surfaces. `NuanceSessionView` handles one group
  per learning visit (up to three cards) and one card per group in a review
  round. Its source area alone scrolls.
- Correct typed answers are matched against authored variants after case,
  whitespace, apostrophe, and terminal punctuation normalization. A learner
  can self-grade a valid paraphrase as equivalent after seeing the model.
  Graduation requires 21-day FSRS stability plus correct answers on three
  distinct cards in at least two formats.
- Version 6 adds `nuance_card_log` for card rotation. Existing review tables
  still hold group progress. The shared `TooEasyGate` and undo are reused.

The work landed in three commits: `fa246299` (editorial), `5f52cb5b`
(production package and model), and `0b110c5a` (app integration).

## Verification completed

- Content gate: 20 modules, 100 groups, 550 cards; unique IDs, full assignment,
  format coverage, answer shape, and length checks passed.
- Pilot card test: all 20 DEBUG modules and 550 cards passed schema and answer
  checks. Pure Swift model, production loader, and attempt-policy checks passed.
- The v6 SQL contract test ran the new table creation against a populated v5
  SQLite fixture and confirmed its Book 1/2 rows survived. It also checked
  that clearing one Nuances group does not delete another group's history.
- The production app built in Debug and Release for the iPhone 18 Pro
  simulator. Visual checks covered a module 01 typed card and a long module 18
  choice card, including wrong feedback and armed Too Easy. The wrong-answer
  panel was corrected so the complete answer wraps.
- The Release build ran through `tools/release_build.sh`. Its registered Book 2
  audio audit passed: 6,459 clips, zero unresolved findings. Book 3 has no
  bundled speech or audio controls, so there is no Book 3 audio index yet.
- `git diff --check` passed after integration.

## Repeat the focused checks

From the repository root, with every shell command routed through `rtk`:

```sh
rtk proxy python3 -m tools.nuances.package --check
rtk proxy python3 -m unittest tools.nuances.test_package tools.nuances.test_migration
rtk proxy swiftc -D DEBUG carambole/Debug/Book3PilotModel.swift tools/pilot/Book3PilotTests.swift -o /tmp/book3-content-tests
rtk proxy /tmp/book3-content-tests carambole/Debug/testbook_book3*.json
rtk proxy swiftc carambole/Models/Nuance.swift tools/nuances/NuanceModelTests.swift -o /tmp/nuance-model-tests
rtk proxy /tmp/nuance-model-tests
rtk proxy swiftc -D NUANCE_RULE_TESTS carambole/Features/Nuance/NuanceAttemptPolicy.swift carambole/Features/Nuance/NuanceAttemptPolicyTests.swift -o /tmp/nuance-attempt-tests
rtk proxy /tmp/nuance-attempt-tests
```

The loader check also exercises the real 20-file package and rejects duplicate
or empty modules:

```sh
rtk proxy swiftc -enable-bare-slash-regex carambole/Models/BookCatalog.swift carambole/Models/BookContent.swift carambole/Models/Exercise.swift carambole/Models/Situation.swift carambole/Models/Nuance.swift carambole/Models/ContentLoader.swift tools/nuances/NuanceLoaderTests.swift -o /tmp/nuance-loader-tests
rtk proxy /tmp/nuance-loader-tests carambole/Resources/Nuances
```

Use `tools/release_build.sh` for every Release build, with a Python interpreter
that has NumPy and SciPy. The simulator check used
`/Users/yiwenwang/miniconda3/envs/gentian/bin/python` for the audio audit; the
default `python3` lacks NumPy. If spoken Book 3 content is added, create and register
its complete `{key, text, voice}` index in `tools/situations/audio_books.json`,
generate and normalize every clip, and pass the audio gate before shipping.

## Limits and next decisions

- The first production version is deliberately text only. Adding spoken French
  is a separate content and audio production pass under the established gate.
- The automated checks do not prove that every French line is native-sounding
  or that every possible paraphrase is covered. The editorial pass corrected
  specific chronology, source-support, ambiguity, and repetition issues; a
  native-level review remains useful for a later content update.
- The migration check executes the extracted v6 SQL on a populated fixture. A
  separate end-to-end upgrade of an existing app installation was not run.
- Simulator visual checks covered representative states, not every card or
  device size. No phone installation was performed.

The older 2026-10-15 curriculum and batch handoffs are drafting snapshots.
Start here for current Book 3 status; consult the production design and plan
for the decisions and execution record.
