# Carambole — French Grammar Trainer

SwiftUI + raw-SQLite iOS app. **Pivoted** from a vocabulary swipe-flashcard app
to a modular French grammar trainer: active-production drills (tap-to-build +
multiple choice), an unlockable topic tree, and spaced-repetition review.

## Locked design decisions

1. **Active production** — user produces answers (conjugate / fill blank / pick
   gender), not recognition swipe.
2. **Input = tap-to-build + multiple choice** — fixed token bank → exact match,
   no free-text / accent / typo handling.
3. **Topic tree + SRS mixing** — ordered unlockable topics; daily review queue
   resurfaces due drills across finished topics.
4. **Modular content** — one topic = one JSON in `Resources/Topics/`. Add grammar
   = author JSON + manifest line, zero Swift changes.

Full design: `docs/plans/2026-06-18-french-grammar-pivot-design.md`
Implementation plan: `docs/plans/2026-06-18-french-grammar-pivot.md`

## Architecture

- **Models** `GrammarTopic`, `Exercise` (replace `Word`/`WordList`/`Book`);
  `ReviewStatus` keyed by `exerciseID`.
- **Persistence** `DataManager` (raw SQLite C API). Tables: `topics`,
  `exercises`, `review_status`.
- **Content** `Resources/Topics/manifest.json` + per-topic JSON; seeded by
  `TopicLoader`.
- **Study loop** one `DrillView` (`DrillEngine.check` = exact token match) serves
  both topic sessions and the daily review queue.
- **SRS** `SRSScheduler`, intervals `[1, 3, 7, 16, 35]` days.
- **Feature folders** `Features/{TopicMap,Drill,Review,Completion}`, `Core/`.

## Build / verify

Xcode 16 `PBXFileSystemSynchronizedRootGroup` — drop `.swift` files in
`carambole/`, no `project.pbxproj` edits. No XCTest target yet; verification gate
is a clean build + `#if DEBUG` self-tests on pure-logic types.

```bash
xcodebuild build -project carambole.xcodeproj -scheme carambole \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet CODE_SIGNING_ALLOWED=NO
```
Expected: `** BUILD SUCCEEDED **`.

## Progress

Branch: `french-grammar-pivot`. Status legend: ☐ todo · ◐ in progress · ☑ done.

### P1 — Data spine
- ☐ T1 `GrammarTopic` + `Exercise` models; rekey `ReviewStatus`
- ☐ T2 SQLite tables + `DataManager` methods (topics/exercises/review_status)
- ☐ T3 `TopicLoader` + first module (`03_passe_compose_etre.json`)

### P2 — Drill core
- ☐ T4 `DrillEngine` (exact-token check)
- ☐ T5 `DrillView` + token/choice input + `DrillSessionView`

### P3 — Topic map + unlock
- ☐ T6 `TopicMapView` nav; remove vocabulary flow
- ☐ T7 add 2–3 more topic modules (present / -ER / imparfait)

### P4 — SRS / Daily Review
- ☐ T8 `SRSScheduler` + persisted `review_status`
- ☐ T9 Daily Review queue (`ReviewQueueView`)

### P5 — Content scale (ongoing, no code)
- Author topic JSON modules one at a time.

## Authoring a new grammar module

1. Add `Resources/Topics/NN_slug.json` — one `GrammarTopic` + 5–6 `Exercise`s,
   mixed `buildFromTokens` / `multipleChoice`.
2. Add a `manifest.json` entry `{id, file, prerequisiteID}`; set `sortOrder` +
   `prerequisiteID` to place it in the unlock chain.
3. No Swift changes. `TopicLoader.seedIfNeeded()` picks it up.

## Execution

Driven by `superpowers:subagent-driven-development`: fresh implementer subagent
per task → spec-compliance review → code-quality review → mark done. Update the
checkboxes above as tasks land.
