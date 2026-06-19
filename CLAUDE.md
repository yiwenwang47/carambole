# Carambole — French Grammar Trainer

> ## ▶ ACTIVE TASK — START HERE (next session, continue without re-asking)
>
> The French-grammar pivot + the content pipeline are DONE. Two things remain;
> do them in order, using the same discipline as before (branch off `main`;
> subagent-driven implement → spec review → code-quality review per task; build
> gate `xcodebuild build ... -scheme carambole -destination 'platform=iOS
> Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO` = EXIT 0; screenshot UI
> changes; commit per task; update this block as you go).
>
> **STEP 1 — merge the content pipeline. ✅ DONE (2026-06-19).** Branch
> `content-pipeline` fast-forward-merged into `main` and deleted; stray
> `verbecc.log` gitignored. Not pushed.
>
> **STEP 2 — build the app-side scheduler. ✅ DONE + MERGED (2026-06-19).**
> Fast-forward-merged into `main` (not pushed); branch deleted. (a) Settings +
> daily home ("X new · Y due", `newPerDay` 20/hard-cap 5–40 + soft review target
> 200/exceedable), (b) new intake decoupled from topic completion
> (`StudyScheduler.newQueue` across the course), (c) overflow review top-up. Ladder
> `[1,3,7,16,35]` unchanged. Build-green + screenshot-validated; spec +
> code-quality + whole-branch reviews passed. Plan + details:
> `docs/plans/2026-06-19-scheduler-implementation.md`, progress §P6.
>
> **STEP 3 — sentence-composition track. ✅ BUILT (2026-06-19, branch
> `sentence-composition`, not yet merged).** Replaced the 4 verb-conjugation
> topics with a 4-topic **"Composer des phrases"** track (01 S-V-O · 02
> adjectives · 03 prepositions · 04 negation+questions), shared daily-life vocab,
> controlled distractors, English ease-in per drill; grammar-audited; `type` maps
> to existing enums so ZERO Swift content changes. Added `tools/lint_topics.py`
> (Codable-contract + multiset token-bank lint). Also shipped drill-UX fixes
> (pinned footer, auto-advance on correct, read-only back/forward review) + a
> scheduler refresh fix (topic-session dismiss now recomputes daily counts).
> Full end-to-end verified on sim (home, intro card, build/MC drills,
> correct/wrong, review, completion→unlock, count refresh). Design:
> `docs/plans/2026-06-19-sentence-composition-track-design.md`. NEXT: merge to
> main (prior steps ff-merged, not pushed).
>
> **STEP 4 (optional, ask first)** — run the pipeline at scale (5 agents × 100 →
> ~500) via `tools/content_pipeline/` (`prepare_all.py` → agents on
> `agent_template.md` → `finalize_all.py`), then CURATE `out/staging/` into
> `carambole/Resources/Topics/`. NOTE: pipeline output is verb-conjugation; the
> live course is now sentence-composition — reconcile before curating.
>
> Status tracker for the pivot is below; pipeline details in its `README.md`.

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
5. **Ease-in English** — learner knows words but struggles with full sentences.
   Every exercise carries an always-visible subtle English `translation` + a
   tap-to-reveal English `hint`; each topic opens with a short English intro card
   (the `ruleNote`). Light touch — present, not cluttering. (Task T-EN.)

Full design: `docs/plans/2026-06-18-french-grammar-pivot-design.md`
Implementation plan: `docs/plans/2026-06-18-french-grammar-pivot.md`
Design system ("Le Cahier"): `docs/plans/2026-06-18-design-system.md`
Schedule / SRS design (next phase): `docs/plans/2026-06-19-schedule-design.md`

## Content pipeline (dev tooling)

`tools/content_pipeline/` — generates grammar-correct conjugation exercises at
volume. Deterministic seeds (verbecc, 3360 available) + LLM sub-agents writing
prose, gated by a seed-fidelity contract so a hallucinated form can't ship. TDD,
57 tests. Run: `cd tools && python3 -m pytest content_pipeline -q`. Workflow:
`prepare_all.py` → dispatch N agents on `agent_template.md` → `finalize_all.py` →
curate `out/staging/` into `carambole/Resources/Topics/`. See its `README.md`.

**App-side scheduler — BUILT** (branch `scheduler`, 2026-06-19): daily-driven home
("X new · Y due"), `newPerDay`(20, hard cap 5–40) + soft review target(200,
exceedable), new-intake decoupled from topic completion (`StudyScheduler.newQueue`
across the course), and overflow review (`reviewQueue` tops up past the due-stack).
See `docs/plans/2026-06-19-scheduler-implementation.md`.

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
- ☑ T1 `GrammarTopic` + `Exercise` models; rekey `ReviewStatus`
- ☑ T2 SQLite tables + `DataManager` methods (topics/exercises/review_status)
- ☑ T3 `TopicLoader` + first module (`03_passe_compose_etre.json`)

### Design foundation (before any UI task)
- ☑ T-DS `DesignSystem.swift` — palette, serif typography, `PrimaryButtonStyle`,
  `ProgressRing`, `DesignGalleryView` ("Le Cahier"). Visually validated. API:
  `AppColor.{paper,ink,graphite,saffron,saffronDeep,success,error,hairline}`,
  `Font.{appPrompt,appTitle,appToken,appLabel,appExplain}`, `Spacing`,
  `PrimaryButtonStyle`, `SectionLabel`/`.uppercaseLabel()`, `ProgressRing(progress:)`.

### P2 — Drill core
- ☑ T4 `DrillEngine` (exact-token check)
- ☑ T5 `DrillView` + token/choice input + `DrillSessionView` (consumes T-DS).
  Visually validated.

### Ease-in English (before T7 content)
- ☑ T-EN `Exercise.translation`/`hint` + schema/content + DrillView surfacing +
  topic intro card ("LEÇON"). English for a beginner (decision #5). Visually
  validated — intro card + subtle translation + "Indice" reveal.

### P3 — Topic map + unlock
- ☑ T6 `TopicMapView` ("Table des matières") nav; vocabulary flow removed.
  Visually validated. Single seeder = `TopicMapViewModel`. `Font.appDisplay` added.
- ☑ T7 4-topic course: être/avoir présent → -ER présent → passé composé être →
  imparfait. English + `wordOrder` sentence-build drills. Grammar-audited (0
  errors / 21 exercises). Chain verified: only topic 01 unlocked.

### P4 — SRS / Daily Review
- ☑ T8 `SRSScheduler` (ladder [1,3,7,16,35]) + persisted `review_status`, graded
  per answer. NOTE deviation: unlock stays "finished once"; SRS drives retention
  only (not unlock gating) — keeps progression fast (decision-aligned).
- ☑ T9 Daily Review queue (`ReviewQueueView`) — reuses `DrillSessionView` (SRS
  re-grades on review), real `dueCount` on the map, editorial empty state.
  Visually validated.

**PIVOT COMPLETE** (T1–T9 + T-DS + T-EN). App: topic map → English intro →
tap-build/MC drills with translation + Indice → completion unlocks next; Daily
Review surfaces SRS-due items. Adding a topic = JSON + manifest line.

### P5 — Content scale (ongoing, no code)
- Author topic JSON modules one at a time.

### P6 — App-side scheduler (branch `scheduler`, 2026-06-19)
- ☑ S1 `StudySettings`/`StudySettingsStore` (newPerDay 5–40 hard cap, reviewTarget
  soft) + `StudyScheduler` (`courseOrdered`/`newQueue`/`reviewQueue`, self-tested)
  + `DataManager` `first_seen_date` UPSERT, `fetchSeenExerciseIDs`,
  `countNewIntroduced(on:)`, `fetchOverflowExerciseIDs(asOf:limit:)`.
- ☑ S2 Daily-driven home ("Aujourd'hui · X new · Y due"), `SettingsView` (gear →
  sheet), Apprendre = cross-course new intake (decoupled from topic completion),
  Réviser = due + overflow top-up. Topic ToC + topic-tap drilling preserved.
  Build-green + screenshot-validated; spec + code-quality + whole-branch reviews
  passed. Fast-forward-merged into `main` (not pushed); `scheduler` branch deleted.

### P7 — Sentence-composition track (branch `sentence-composition`, 2026-06-19)
- ☑ C1 4-topic **"Composer des phrases"** course replacing the verb topics:
  01 `phrases_svo` (S-V-O + article/gender) · 02 `phrases_adjectifs` (placement +
  agreement) · 03 `phrases_prepositions` (à/de/dans/avec + à+le→au) · 04
  `phrases_negation_questions` (ne…pas / n' / est-ce que / inversion). Shared
  daily-life vocab, controlled distractors, English `translation`+`hint` per
  drill, grammar-audited. `type` reuses existing enums → no Swift content changes.
- ☑ C2 `tools/lint_topics.py` — validates topic JSON vs the Codable contract
  (types, multiset token-bank subset, MC shape, required English ease-in).
- ☑ C3 Drill UX: pinned Vérifier/Suivant footer (no longer hidden by a tall
  banner); correct → green flash + auto-advance; wrong → stays with answer +
  manual Suivant; read-only back/forward **review** of answered drills (session
  holds submitted tokens + result). `DrillView`/`DrillSessionView`.
- ☑ C4 Scheduler fix: topic-session `fullScreenCover` now refreshes daily counts
  on dismiss (was the only cover missing it → stale "X new"). `TopicMapView`.
- Verified end-to-end on sim; lint + build green. NOT yet merged to `main`.

## Authoring a new grammar module

1. Add `carambole/Resources/Topics/NN_slug.json` — one `GrammarTopic` + 5–6
   `Exercise`s, mixed `buildFromTokens` / `multipleChoice`. JSON keys must match
   the Codable property names exactly (`sortOrder`, `prerequisiteID`, `topicID`,
   `answerTokens`, `tokenBank`, `inputMode`). Set `sortOrder` + `prerequisiteID`
   to place it in the unlock chain.
2. Add the filename to `carambole/Resources/Topics/manifest.json` →
   `{ "topicFiles": [ ... ] }`.
3. No Swift changes. `TopicLoader.seedIfNeeded()` picks it up.

**Gotchas (verified in T3):**
- Xcode 16 `PBXFileSystemSynchronizedRootGroup` **flattens** `Resources/Topics/*`
  to the bundle ROOT at build time (no `Topics/` subdir in the `.app`).
  `TopicLoader.bundleURL` tries the subdirectory then falls back to root — works
  either way; filenames must stay unique.
- `seedIfNeeded()` only seeds when `topicCount() == 0`. To re-seed after editing
  content during dev: `xcrun simctl uninstall booted wen.carambole` then reinstall
  (clears the SQLite DB). Bundle id = `wen.carambole`.

## Known tech debt
- **No SQLite schema migration.** Tables use `CREATE TABLE IF NOT EXISTS`; new
  columns only exist on a fresh DB. There is no `ALTER TABLE`/`PRAGMA user_version`
  versioning, so an in-place schema change can break installs that already have the
  old table populated. Masked in dev by uninstall-to-reseed + `TopicLoader`
  short-circuit. Affected columns so far:
  - `exercises.translation` / `exercises.hint` (T-EN). Lower risk: `exercises` is
    re-seeded whenever `topics` is empty.
  - `review_status.first_seen_date` (scheduler). **Higher risk:** `review_status`
    is accumulated *user* data and is NEVER reseeded. On an upgraded DB missing the
    column, `upsertReviewStatus` (which now always references `first_seen_date`)
    fails to prepare → SRS grading silently stops persisting. The new READ queries
    (`countNewIntroduced`, `fetchOverflowExerciseIDs`) degrade safely to 0/empty.

  **Before shipping to real users**, add a `user_version` migration that runs
  `ALTER TABLE review_status ADD COLUMN first_seen_date REAL` (and any future
  column adds) on existing DBs.

## Execution

Driven by `superpowers:subagent-driven-development`: fresh implementer subagent
per task → spec-compliance review → code-quality review → mark done. Update the
checkboxes above as tasks land.
