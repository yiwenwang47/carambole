# French Grammar Pivot — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task (same session, fresh subagent per task, spec review then code-quality review).

**Goal:** Convert Carambole from a vocabulary swipe-flashcard app into a modular
French grammar trainer with active-production drills (tap-to-build + multiple
choice), an unlockable topic tree, and spaced-repetition review.

**Architecture:** SwiftUI + raw-SQLite (`DataManager`). New models `GrammarTopic`
and `Exercise` replace `Word`/`WordList`/`Book`. Content ships as per-topic JSON
modules under `Resources/Topics/`, seeded by `TopicLoader`. One `DrillView`
serves both topic sessions and the daily SRS review queue. Built in phases so the
app compiles and runs at every step; old vocabulary code is removed only once the
new flow replaces it (Task 6).

**Tech Stack:** Swift 5 / SwiftUI (iOS 18), SQLite3 C API, Codable JSON. Xcode 16
`PBXFileSystemSynchronizedRootGroup` (drop `.swift` files in `carambole/`, no
project file edits). Verification gate = `xcodebuild build` succeeds; pure-logic
types verified by spot-check assertions (no XCTest target yet).

**Build command (verification):**
```bash
xcodebuild build -project carambole.xcodeproj -scheme carambole \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet CODE_SIGNING_ALLOWED=NO
```
Expected: `** BUILD SUCCEEDED **`.

---

## Phase P1 — Data spine

### Task 1: New core models

**Files:**
- Create: `carambole/Models/GrammarTopic.swift`
- Create: `carambole/Models/Exercise.swift`
- Modify: `carambole/Models/ReviewStatus.swift` (key by `exerciseID`, add `intervalDays`)

**Step 1:** Create `Exercise.swift` with `ExerciseType` (`conjugate`, `fillBlank`,
`genderArticle`, `wordOrder`), `InputMode` (`multipleChoice`, `buildFromTokens`),
and the `Exercise` struct (fields: `id`, `topicID`, `type`, `prompt`, `cue`,
`answerTokens`, `tokenBank`, `inputMode`, `explanation`). `Identifiable, Codable,
Equatable`. Provide a static `Exercise.sample` for previews.

**Step 2:** Create `GrammarTopic.swift` (fields: `id`, `title`, `sortOrder`,
`prerequisiteID`, `ruleNote`, `exercises`). `Identifiable, Codable`.

**Step 3:** Update `ReviewStatus` — rename `wordID` → `exerciseID`, add
`intervalDays: Int` (default 0). Keep `learningState`, `lastReviewDate`,
`nextReviewDate`. Leave the existing `updateReviewDates()` in place for now;
`SRSScheduler` (Task 7) supersedes it.

**Step 4 (verify):** Run the build command. Expected `BUILD SUCCEEDED`. New types
compile, are not yet referenced by UI.

**Step 5:** Commit `feat: add GrammarTopic + Exercise models, rekey ReviewStatus`.

---

### Task 2: SQLite schema for topics + exercises + review_status

**Files:**
- Modify: `carambole/Models/CoreDataManager.swift`

**Step 1:** In the table-creation SQL, add:
- `topics(id TEXT PRIMARY KEY, title TEXT NOT NULL, sort_order INTEGER,
  prerequisite_id TEXT, rule_note TEXT)`
- `exercises(id TEXT PRIMARY KEY, topic_id TEXT NOT NULL, type TEXT, prompt TEXT,
  cue TEXT, answer_tokens TEXT, token_bank TEXT, input_mode TEXT, explanation TEXT)`
  (`answer_tokens`/`token_bank` stored as JSON strings)
- `review_status(exercise_id TEXT PRIMARY KEY, learning_state TEXT,
  last_review_date REAL, next_review_date REAL, interval_days INTEGER)`

Keep existing tables for now (removed in Task 6).

**Step 2:** Add `DataManager` methods (mirror existing transactional style):
- `upsertTopic(_ topic: GrammarTopic)` (writes topic row + its exercises)
- `fetchAllTopics(completion: @escaping ([GrammarTopic]) -> Void)` (joins exercises)
- `topicCount() -> Int`
- `fetchExercises(forTopicID:) -> [Exercise]` (private helper)

**Step 3 (verify):** Build succeeds.

**Step 4:** Commit `feat: SQLite tables + DataManager methods for topics/exercises`.

---

### Task 3: TopicLoader + first content module

**Files:**
- Create: `carambole/Models/TopicLoader.swift`
- Create: `carambole/Resources/Topics/manifest.json`
- Create: `carambole/Resources/Topics/03_passe_compose_etre.json`

**Step 1:** Author `03_passe_compose_etre.json` — one `GrammarTopic`
(`id: "passe_compose_etre"`, title "Passé composé — être verbs", `sortOrder: 3`,
`prerequisiteID: "er_verbs_present"`, a one-line `ruleNote`) with **6 exercises**
mixing `buildFromTokens` and `multipleChoice`. Example exercise:
```json
{
  "id": "pce_01",
  "topicID": "passe_compose_etre",
  "type": "conjugate",
  "prompt": "Il ___ (partir) hier.",
  "cue": "partir",
  "answerTokens": ["est", "parti"],
  "tokenBank": ["a", "est", "parti", "partie", "partait"],
  "inputMode": "buildFromTokens",
  "explanation": "être verb → past participle agrees with the subject (il → parti)."
}
```
Cover masc/fem/plural agreement so the topic actually teaches the rule.

**Step 2:** Author `manifest.json` — ordered array of `{id, file, prerequisiteID}`
entries (just this one topic for now).

**Step 3:** Write `TopicLoader`:
- `seedIfNeeded()` — if `DataManager.topicCount() == 0`, read `manifest.json` from
  the bundle, then decode each listed topic file and `upsertTopic`.
- Decodes against the `GrammarTopic`/`Exercise` Codable types directly.

**Step 4:** Call `TopicLoader.seedIfNeeded()` from `RootView.loadData()` (alongside
the existing word loading for now — do not remove word loading yet).

**Step 5 (verify):** Build succeeds. Add a temporary `print(topicCount)` after seed
or a debug assertion to confirm seeding runs; remove before commit.

**Step 6:** Commit `feat: TopicLoader + first grammar module (passé composé être)`.

---

## Phase P2 — Drill core

### Task 4: DrillEngine (pure logic)

**Files:**
- Create: `carambole/Features/Drill/DrillEngine.swift`

**Step 1:** Implement `DrillEngine.check(_ submitted: [String], _ ex: Exercise) -> Bool`
returning `submitted == ex.answerTokens` (order-sensitive exact match).

**Step 2 (verify logic):** Add a `#if DEBUG static func _selfTest()` with
assertions: correct order passes, wrong order fails, extra/missing token fails,
single-token MC answer passes. Call it once from `caramboleApp.init()` under
`#if DEBUG`. Confirm no assertion fires at launch (build + run in simulator, or at
minimum build succeeds and reasoning is spot-checked). Leave `_selfTest` in place.

**Step 3:** Commit `feat: DrillEngine with exact-token checking`.

---

### Task 5: DrillView + input components + drill session

**Files:**
- Create: `carambole/Features/Drill/DrillView.swift` (single exercise card)
- Create: `carambole/Features/Drill/TokenBuilderView.swift` (tap tiles → answer slots)
- Create: `carambole/Features/Drill/ChoiceView.swift` (3–4 MC buttons)
- Create: `carambole/Features/Drill/DrillSessionView.swift` (sequences a topic's exercises)
- Add: a temporary launch path from the existing UI so the session is reachable.

**Step 1:** `TokenBuilderView` — renders `exercise.tokenBank` as tappable tiles;
tapping appends to a `selected: [String]` answer row; tapping a selected token
removes it. Exposes the current `[String]`.

**Step 2:** `ChoiceView` — renders options (for MC the `tokenBank` holds full-phrase
choices; `answerTokens` is a single-element array with the correct phrase). One tap
commits.

**Step 3:** `DrillView` — shows `prompt`, the right input component per
`inputMode`, a Check button. On check: call `DrillEngine.check`, show green/red +
`explanation`, reveal a Next button. Reuse `ScaleButtonStyle`; reuse
`CircularProgressView` for session progress.

**Step 4:** `DrillSessionView` — takes a `GrammarTopic`, iterates its exercises,
tracks correct/total, and on finish presents the existing `SessionCompletionView`
(adapt its labels to "Correct"/"Review"). Reuse the completion view rather than a
new screen.

**Step 5:** Temporary reachability — in `RootView`, when a word list is tapped,
instead (behind a clearly-marked TODO) push `DrillSessionView` for the seeded
topic, so the drill is playable now. (Full nav replacement is Task 6.)

**Step 6 (verify):** Build succeeds; run in simulator and play the topic
start→completion (tap-build a correct answer → green; a wrong answer → red +
explanation; reach completion).

**Step 7:** Commit `feat: DrillView + token/choice input + topic drill session`.

---

## Phase P3 — Topic map + unlock

### Task 6: TopicMap navigation, rip out vocabulary flow

**Files:**
- Create: `carambole/Features/TopicMap/TopicMapView.swift`
- Create: `carambole/Features/TopicMap/TopicMapViewModel.swift`
- Modify: `carambole/Views/RootView.swift` (new `Screen` enum + flow)
- Delete: `Word.swift`, `WordList.swift`, `WordListLoader.swift`,
  `FlashcardView.swift`, `WordListSessionView.swift`, `QuestionView.swift`,
  `QuestionItem.swift`, `Resources/test_words.json`; remove `Book`/word tables
  from `CoreDataManager` and word loading from `loadData()`.

**Step 1:** `TopicMapViewModel` — loads topics via `fetchAllTopics`, computes
completion (a topic is complete when all its exercises have a `review_status` row
in a non-`.new` learned state; until Task 7 persists status, treat "session
finished once" via a simple `completedTopicIDs` set persisted in `UserDefaults`).
Computes unlock: a topic is unlocked when `prerequisiteID` is nil or its prereq is
complete.

**Step 2:** `TopicMapView` — vertical list/tree of topics with state glyphs
(✓ done · • current · 🔒 locked) and a "Daily Review" button (wired in Task 8).
Tapping an unlocked topic pushes `DrillSessionView`.

**Step 3:** Rewrite `RootView` `Screen` enum to `.map`, `.drill(GrammarTopic)`,
`.review`, `.completion`; on session completion mark the topic complete and pop to
map (next topic now unlocked). Remove `Book` and the Home/Book screens.

**Step 4:** Delete the vocabulary files and tables listed above. Update
`loadData()` to only seed topics.

**Step 5 (verify):** Build succeeds with the old files gone. Run: map shows the
one topic unlocked; complete it; (with only one topic, confirm completion glyph
turns ✓). No references to deleted types remain.

**Step 6:** Commit `feat: topic map navigation; remove vocabulary flow`.

---

### Task 7: Add 2–3 more topic modules

**Files:**
- Create: `carambole/Resources/Topics/01_etre_avoir_present.json`
- Create: `carambole/Resources/Topics/02_er_verbs_present.json`
- Create: `carambole/Resources/Topics/04_imparfait.json`
- Modify: `carambole/Resources/Topics/manifest.json` (add entries, set prereq chain)

**Step 1:** Author three topics (each 5–6 exercises, mixed input modes) forming a
chain: `etre_avoir_present` (no prereq) → `er_verbs_present` →
`passe_compose_etre` → `imparfait`. Fix `sortOrder` and `prerequisiteID` to match.

**Step 2 (verify):** Build succeeds; run: only the first topic unlocked; finishing
it unlocks the second; locked topics show 🔒 and are not tappable.

**Step 3:** Commit `content: add present/-ER/imparfait grammar modules`.

---

## Phase P4 — SRS / Daily Review

### Task 8: SRSScheduler + persisted review_status

**Files:**
- Create: `carambole/Core/SRSScheduler.swift`
- Modify: `carambole/Models/CoreDataManager.swift` (review_status read/write)
- Modify: `carambole/Features/Drill/DrillSessionView.swift` (grade each answer)

**Step 1:** `DataManager` — `upsertReviewStatus(_:)`, `fetchReviewStatus(exerciseID:)`,
`fetchDueExerciseIDs(asOf: Date) -> [String]`
(`WHERE next_review_date <= ?`).

**Step 2:** `SRSScheduler.grade(_ status: ReviewStatus, pass: Bool, now: Date) ->
ReviewStatus` — intervals `[1, 3, 7, 16, 35]` days; pass advances a step (top →
`.learned`), fail resets to 1 day and `.learning`; set `nextReviewDate = now +
interval`. Pure function.

**Step 3 (verify logic):** `#if DEBUG _selfTest()` for `SRSScheduler`: pass from
fresh → interval 1; consecutive passes climb the ladder; fail drops to 1.

**Step 4:** In `DrillSessionView`, after each check call `SRSScheduler.grade` and
`upsertReviewStatus`. Replace the `UserDefaults` completion heuristic from Task 6
with the real rule (topic complete when all its exercises are `.learned`).

**Step 5:** Commit `feat: SRS scheduler with persisted review_status`.

---

### Task 9: Daily Review queue

**Files:**
- Create: `carambole/Features/Review/ReviewQueueView.swift`
- Modify: `carambole/Views/RootView.swift` (wire `.review`)
- Modify: `carambole/Features/TopicMap/TopicMapView.swift` (Daily Review button →
  `.review`; show due count)

**Step 1:** `ReviewQueueView` — loads `fetchDueExerciseIDs(asOf: now)`, resolves the
`Exercise` objects, and drives the **same `DrillView`** through them, grading via
`SRSScheduler`. Empty state when nothing is due.

**Step 2:** Topic map's "Daily Review" button shows the due count and opens the
queue.

**Step 3 (verify):** Build + run: finish a topic, advance the clock conceptually
(or temporarily seed a past `next_review_date`) to confirm due items appear in the
queue and grade correctly.

**Step 4:** Commit `feat: daily review queue over due exercises`.

---

## Phase P5 — Content scale (ongoing, no code)

Author additional topic JSON modules under `Resources/Topics/` + one manifest line
each. No Swift changes. Out of scope for this plan beyond the seed set in Tasks 3
and 7.

---

## Done criteria

- App launches to a topic map; first topic unlocked, rest locked.
- A topic plays as tap-build / MC drills with explanations; completion unlocks the
  next.
- Finished exercises schedule via SRS; Daily Review surfaces due items and grades.
- Vocabulary code (Word/WordList/Book/Flashcard) fully removed.
- Adding a grammar topic requires only a JSON file + manifest line.
- `xcodebuild build` succeeds at every committed task.
