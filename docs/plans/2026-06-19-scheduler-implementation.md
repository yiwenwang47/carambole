# Scheduler — App-Side Implementation Plan

**Date:** 2026-06-19 · **Branch:** `scheduler` (off `main`)
**Drives:** `docs/plans/2026-06-19-schedule-design.md` → "Still to build".

Realizes the daily-driven learning loop in the app: a hard-capped daily NEW
intake, a soft REVIEW target the user may exceed via overflow, and a home that
shows "X new · Y due". Ladder stays `[1,3,7,16,35]` in `SRSScheduler` — untouched.

## Locked definitions (apply to every task)

- **Seen** exercise = has a row in `review_status`. **Unseen / new** = no row.
  (Every answered card gets a row via `DrillSessionView.grade`.)
- **Course order** = topics by `sortOrder` ascending, then exercises by `id`
  ascending within a topic. Exercise ids are zero-padded sequential per topic
  (`eap_01`, `pce_02`…), so lexicographic id sort = authoring order. Deterministic.
- **Due** = `review_status.next_review_date <= now`.
- **newPerDay** = HARD cap on cards introduced per calendar day (default 20,
  clamped 5…40). **reviewTarget** = SOFT daily review target (default 200); the
  review queue may EXCEED it (a big due stack is never truncated) and may grow
  toward it via overflow. No review hard cap.
- **Overflow** = seen-but-not-yet-due cards used to top the review queue up to
  `reviewTarget` when the due stack is smaller. Order: soonest-due first, then
  lowest familiarity (`next_review_date ASC, interval_days ASC`). Overflow cards
  grade normally through the same `DrillSessionView` path.

---

## Task 1 — Persistence + scheduler core (no UI)

Pure logic + SQLite. Build-gated only (no screenshot). Follow TDD discipline via
`#if DEBUG _selfTest()` on pure types, matching `SRSScheduler`/`DrillEngine`
(invoked in `caramboleApp.init()`).

### 1a. `StudySettings` value type + `StudySettingsStore`
New file `carambole/Core/StudySettings.swift`.

- `struct StudySettings: Equatable` with `newPerDay: Int`, `reviewTarget: Int`.
  - `static let newPerDayRange = 5...40`
  - `static let `default` = StudySettings(newPerDay: 20, reviewTarget: 200)`
  - Initializer CLAMPS `newPerDay` into `newPerDayRange` and `reviewTarget` to a
    sane floor (`>= 1`; suggest clamp `1...1000`). Clamping is the invariant —
    out-of-range inputs must never persist.
- `final class StudySettingsStore: ObservableObject` backing `StudySettings` in
  `UserDefaults` (keys `"settings.newPerDay"`, `"settings.reviewTarget"`).
  - `@Published var settings: StudySettings` — `didSet` persists (clamped).
  - Loads clamped values on init, falling back to `.default` when keys absent.
  - Inject the `UserDefaults` instance (default `.standard`) so the self-test can
    use an isolated suite.
- `#if DEBUG static func _selfTest()`: clamping (newPerDay 1→5, 99→40; reviewTarget
  0→1), round-trip persistence through an isolated `UserDefaults(suiteName:)`.

### 1b. `DataManager` additions — `carambole/Models/CoreDataManager.swift`

1. Add column `first_seen_date REAL` to the `review_status` `CREATE TABLE`.
2. Replace `upsertReviewStatus`'s `INSERT OR REPLACE` with a true UPSERT that
   STAMPS `first_seen_date` once and PRESERVES it on later writes:
   ```sql
   INSERT INTO review_status
     (exercise_id, learning_state, last_review_date, next_review_date, interval_days, first_seen_date)
   VALUES (?, ?, ?, ?, ?, ?)
   ON CONFLICT(exercise_id) DO UPDATE SET
     learning_state   = excluded.learning_state,
     last_review_date = excluded.last_review_date,
     next_review_date = excluded.next_review_date,
     interval_days    = excluded.interval_days,
     first_seen_date  = COALESCE(review_status.first_seen_date, excluded.first_seen_date);
   ```
   Bind `first_seen_date` = `status.lastReviewDate?.timeIntervalSince1970 ??
   Date().timeIntervalSince1970` (grade always sets `lastReviewDate = now`, so the
   first grade stamps the introduction time; COALESCE keeps it stable thereafter).
   `INSERT OR REPLACE` would delete+reinsert the row and lose the original
   `first_seen_date` — do NOT keep it.
3. `func fetchSeenExerciseIDs() -> Set<String>` — `SELECT exercise_id FROM
   review_status`. Used to compute unseen = all − seen.
4. `func countNewIntroduced(on day: Date) -> Int` — `SELECT COUNT(*) ... WHERE
   first_seen_date >= ? AND first_seen_date < ?` for `[startOfDay,
   startOfNextDay)` via `Calendar.current`. Drives the daily new budget.
5. `func fetchOverflowExerciseIDs(asOf now: Date, limit: Int) -> [String]` —
   ```sql
   SELECT exercise_id FROM review_status
   WHERE next_review_date IS NOT NULL AND next_review_date > ?
   ORDER BY next_review_date ASC, interval_days ASC
   LIMIT ?;
   ```
   Returns 0 rows when `limit <= 0`.

Match the file's existing raw-SQLite idioms exactly (the `dbQueue.sync`/`.async`
pattern, `SQLITE_TRANSIENT`, `sqlite3_finalize` on every path, prepared
statements). Keep the existing `print` logging style.

### 1c. `StudyScheduler` — new file `carambole/Core/StudyScheduler.swift`
Pure, no persistence/UI. Composes course content + DB facts (facts passed in).

- `static func courseOrdered(_ topics: [GrammarTopic]) -> [Exercise]` — topics by
  `sortOrder`, then each topic's exercises by `id` ascending, flattened.
- `static func newQueue(topics: [GrammarTopic], seen: Set<String>,
  remainingBudget: Int) -> [Exercise]` — `courseOrdered`, drop `seen`, take the
  first `max(0, remainingBudget)`.
- `static func reviewQueue(due: [Exercise], overflow: [Exercise], target: Int)
  -> [Exercise]` — return ALL `due` (never truncated, even if `due.count >
  target`); if `due.count < target`, append the first `target - due.count` of
  `overflow`. (`due` and `overflow` are disjoint by construction: due ⇒
  `next <= now`, overflow ⇒ `next > now`.)
- `#if DEBUG static func _selfTest()` asserting: course ordering across two
  topics; newQueue drops seen + honors budget (incl. budget 0 and budget >
  available); reviewQueue tops up to target; reviewQueue does NOT truncate when
  `due.count >= target`.

Register `StudyScheduler._selfTest()` (and `StudySettingsStore._selfTest()`) in
`caramboleApp.init()` under the existing `#if DEBUG` block.

### Task 1 acceptance
- `xcodebuild build … -scheme carambole -destination 'platform=iOS
  Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO` ⇒ `** BUILD SUCCEEDED **`.
- New self-tests compiled and wired into `caramboleApp.init()`.
- No UI changes in this task.

---

## Task 2 — Daily-driven home + Settings UI + wiring

Consumes Task 1. Build- AND screenshot-gated (this changes the home screen).

### 2a. Settings screen
New file `carambole/Features/Settings/SettingsView.swift`. "Le Cahier" editorial
style (paper bg, serif title, `SectionLabel`, `PrimaryButtonStyle`, `Spacing`).

- Title "Réglages" + English `SectionLabel`.
- `newPerDay` control: a `Stepper` (or slider) bound to the store, range
  `StudySettings.newPerDayRange` (5…40). Show the value + a one-line English
  caption ("New cards introduced per day — a hard cap.").
- `reviewTarget` control: `Stepper` in steps of 10 or 20 (range e.g. 40…600),
  caption ("Daily review goal — you can exceed it.").
- Edits write through `StudySettingsStore` (clamped) and persist immediately.
- Presented as a `.sheet` from the home header (a small "Réglages" text button or
  gear — keep it quiet, not a loud control).

### 2b. `TopicMapViewModel` — daily intake + review composition
Extend the existing view model (it already owns topics + `dueCount` + seeding).

- Hold/observe a `StudySettingsStore` (inject; default a shared instance).
- `@Published var newAvailableToday: Int` = `min(remainingNewBudget,
  unseenCount)`, where `remainingNewBudget = max(0, settings.newPerDay -
  DataManager.countNewIntroduced(on: now))` and `unseenCount = courseOrdered
  minus seen`.
- `func todaysNewExercises() -> [Exercise]` =
  `StudyScheduler.newQueue(topics:, seen: DataManager.fetchSeenExerciseIDs(),
  remainingBudget: remainingNewBudget)`.
- `func reviewSessionExercises() -> [Exercise]` = `StudyScheduler.reviewQueue(due:
  dueExercises(), overflow: overflowExercises(), target: settings.reviewTarget)`,
  where `overflowExercises()` maps `DataManager.fetchOverflowExerciseIDs(asOf:
  now, limit: max(0, target - dueCount))` back to loaded `Exercise`s (preserving
  the SQL order).
- Extend `refreshDue()` (or add `refresh()`) to also recompute
  `newAvailableToday`. Call it on appear and after any session dismiss.
- Keep `dueCount` = actual due count (drives "Y due"). Keep existing completion /
  unlock logic untouched.

### 2c. Home (`TopicMapView`) — daily panel
Add a "Aujourd'hui" / Today panel ABOVE the existing topic table of contents
(keep the ToC and its topic-tap drilling — req (b) only decouples NEW intake from
finishing a topic; it does not remove the topic tree, a locked design decision).

- Panel shows the two counts prominently: "X new · Y due" (X =
  `newAvailableToday`, Y = `dueCount`), styled editorially.
- Two actions:
  - **Apprendre** (Learn) → `.fullScreenCover` `DrillSessionView(title:
    "Nouveau", exercises: viewModel.todaysNewExercises())`. Disable when X == 0.
  - **Réviser** (Review) → `.fullScreenCover` `ReviewQueueView(due:
    viewModel.reviewSessionExercises())` (its existing empty state covers the
    nothing-to-do case).
  - Both `onDismiss` → `viewModel.refresh()`.
- The existing standalone "Révision" row may be folded into this panel or kept —
  implementer's call, but avoid showing the due count twice in a confusing way.
- Header gains the quiet Settings affordance (2a).

### Task 2 acceptance
- Build succeeds (same command).
- Screenshot the new home (booted simulator, fresh install) showing the daily
  panel with real counts; screenshot the Settings sheet. Confirm:
  - Day-1 fresh install: X ≈ min(20, ~21) ≈ 20 new, Y = 0 due.
  - "Apprendre" runs a NEW session pulled across topics in course order (not
    gated by finishing topic 01); after finishing, X drops and seen cards begin
    surfacing as due over time.
  - "Réviser" with an empty due stack but some seen cards tops up with overflow
    (verify by grading a few new cards, then opening Réviser — overflow appears).
- No regression: topic ToC still navigates + drills; SRS grading still persists.

---

## Execution
Subagent-driven per CLAUDE.md: fresh implementer → spec-compliance review →
code-quality review per task, fix-loops until both pass; commit per task; final
whole-branch review; then `finishing-a-development-branch`. Update CLAUDE.md
STEP 2 status + the pivot progress tracker as tasks land.
