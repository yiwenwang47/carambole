# French Grammar Pivot — Design

**Date:** 2026-06-18
**Status:** Approved (brainstorm complete)

## Goal

Pivot Carambole from a vocabulary swipe-flashcard app into a **French grammar
trainer** built for fast learning: active-production drills, structured topic
progression, and spaced repetition for retention.

## Decisions (locked during brainstorm)

1. **Core interaction = active production.** User produces the answer
   (conjugate, fill the blank, pick gender), not just recognizes it.
2. **Input = tap-to-build + multiple choice.** Tap word tiles to assemble the
   answer, or pick from 3–4 choices. No free-text keyboard → exact token
   checking, no accent/typo handling needed.
3. **Progression = topic tree + SRS mixing.** Ordered, unlockable grammar
   topics. A daily review queue resurfaces due drills across finished topics.
4. **Modular content.** One topic = one JSON file dropped into
   `Resources/Topics/`. Adding grammar = author JSON, zero Swift changes.

## Why a re-model, not a relabel

Vocabulary cards are `word → definition`. Grammar is `rule + production`
("conjugate *partir* in passé composé with agreement"). Recognition swipe can't
teach production, so the data model and study loop change. The existing
infrastructure (SQLite `DataManager`, `ReviewStatus` model, `QuestionItem`
prompt/options/answer, completion + progress views, nav state machine) is
reused; the vocabulary-specific models and the swipe card are replaced.

## Data model

Old → new mapping:

| Today        | Becomes                | Note                                            |
|--------------|------------------------|-------------------------------------------------|
| `Book`       | `Unit` (optional)      | Coarse grouping ("Verbs", "Articles"); optional |
| `WordList`   | `GrammarTopic`         | The unlockable tree node                        |
| `Word`       | `Exercise`             | One production drill                            |
| `QuestionItem` | folds into `Exercise`| Reuse `prompt`/`options`/`correctAnswer` shape  |
| `ReviewStatus(wordID)` | `ReviewStatus(exerciseID)` | Finally persisted              |

Core types:

```swift
struct GrammarTopic: Identifiable, Codable {
    let id: String
    let title: String          // "Passé composé — être verbs"
    let sortOrder: Int         // tree position
    let prerequisiteID: String?// unlock gate (nil = always unlocked)
    let ruleNote: String       // 1–2 line rule, shown as feedback/hint
    var exercises: [Exercise]
}

enum ExerciseType: String, Codable { case conjugate, fillBlank, genderArticle, wordOrder }
enum InputMode: String, Codable { case multipleChoice, buildFromTokens }

struct Exercise: Identifiable, Codable {
    let id: String
    let topicID: String
    let type: ExerciseType
    let prompt: String         // "Il ___ (partir) hier."
    let cue: String?           // "partir"
    let answerTokens: [String] // ["est","parti"]  (order matters)
    let tokenBank: [String]    // ["a","est","parti","partie","partait"]
    let inputMode: InputMode
    let explanation: String    // shown on answer
}
```

One `Exercise` type covers all four drill kinds; `type` + `inputMode` drive
rendering. No per-kind model explosion (YAGNI).

## Persistence

Same `DataManager` raw-SQLite pattern. Schema changes:

- Drop `words`, `word_list_words`.
- Add `topics` (id, title, sort_order, prerequisite_id, rule_note).
- Add `exercises` (id, topic_id, type, prompt, cue, answer_tokens JSON,
  token_bank JSON, input_mode, explanation).
- Persist `review_status` (exercise_id PK, state, last_review_date,
  next_review_date, interval_days) — modeled today, never stored.

## Content modularity

```
Resources/Topics/
  manifest.json                 # ordered list + prerequisites
  03_passe_compose_etre.json    # one GrammarTopic + its Exercises
  04_imparfait.json             # add later, app auto-seeds
```

`TopicLoader` (rename of `WordListLoader`) reads the manifest, then each topic
file, and seeds SQLite when a topic id is new. Adding a module = add a JSON +
one manifest line.

## Code modularity (feature folders)

```
Features/
  TopicMap/    TopicMapView, TopicMapViewModel
  Drill/       DrillView, DrillEngine, input components
  Review/      ReviewQueueView (SRS)
  Completion/  reuse SessionCompletionView
Core/
  Models/  DataManager  TopicLoader  SRSScheduler
```

## Screens / navigation

```
TOPIC MAP  (replaces Home/Book screens)
  vertical tree: ✓ done · • current · 🔒 locked
   ├─ tap unlocked topic → DRILL SESSION
   │     exercise → check → explanation → next
   │     (N exercises) → COMPLETION → unlock next → back to map
   └─ "Daily Review" → SRS QUEUE (due exercises across finished topics)
                       reuses the same DrillView
```

`Screen` enum shrinks to `.map`, `.drill(GrammarTopic)`, `.review`,
`.completion`. **One `DrillView`** serves both topic sessions and the review
queue. The current Review "Coming Soon" stub becomes a real queue.

## Drill loop + checking

```
load Exercise
  multipleChoice → 3–4 choice buttons
  buildFromTokens → tap tiles + answer slots
commit answer → DrillEngine.check(submitted, exercise)
  correct → green, explanation, SRS.grade(.pass)
  wrong   → red, highlight answer, explanation, SRS.grade(.fail)
next → end → COMPLETION (correct/total, unlock next topic)
```

```swift
struct DrillEngine {
    static func check(_ submitted: [String], _ ex: Exercise) -> Bool {
        submitted == ex.answerTokens   // exact, order-sensitive
    }
}
```

Structured input (fixed token bank) makes equality enough — that is the payoff
of choosing tap/MC over free text.

## SRS scheduler

`SRSScheduler` persists to `review_status`. Reuse `ReviewStatus`, key by
`exerciseID`, add interval stepping:

```
grade(exercise, pass):
  pass: interval = next of [1, 3, 7, 16, 35] days; top step → state .learned
  fail: interval = 1 day, drop one step, state .learning
  nextReviewDate = today + interval
```

Daily Review = `SELECT exercise_id FROM review_status WHERE next_review_date <= today`,
feed that list into `DrillView`. Topic mixing is automatic.

## Build order (each phase = a working app)

- **P1 Data spine** — new models, SQLite tables, `TopicLoader`, one authored
  topic JSON (`03_passe_compose_etre`).
- **P2 Drill core** — `DrillView` (buildFromTokens + multipleChoice),
  `DrillEngine`, explanation feedback. One topic playable start→completion.
- **P3 Topic map + unlock** — `TopicMapView` tree, prerequisite gating,
  completion unlocks next. Add 2–3 more topic JSONs → it's a course.
- **P4 SRS / Daily Review** — persist `review_status`, `SRSScheduler.grade`,
  wire Review stub to the queue. Teaches *and* retains.
- **P5 Content scale** — author topics one JSON at a time, no code touch.

P1+P2 is the smallest thing that proves the pivot. P4 is where "learn quickly"
lands (retention). P5 is forever.

## Constraints / notes

- Xcode 16 `PBXFileSystemSynchronizedRootGroup`: dropping `.swift` files into
  `carambole/` auto-includes them — no `project.pbxproj` edits.
- No XCTest target today. Verification gate = `xcodebuild build` succeeds +
  pure-logic spot checks. A dedicated test target is a later, optional task.
