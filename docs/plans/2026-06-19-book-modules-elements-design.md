# Book / Module / Element redesign — design

**Date:** 2026-06-19
**Status:** approved (decisions locked with user), implementation pending
**Supersedes:** the flat `GrammarTopic` course (4 sentence-composition topics — scrapped)

## Motivation

The current course is too small and too "Duolingo": micro-topics of ~6 exercises,
unlock = "answered once", SRS keyed per sentence so the learner memorizes a fixed
token order rather than the rule. We want **efficiency** — master a grammar *rule*,
proven across *varied* sentences, then move on.

## Decisions (locked)

1. **Scope of first delivery** — build the structure (model + schema + book/module
   UI + element-level SRS) and seed **1–2 real modules**. Bulk content (≈25×20×5 ≈
   2500 sentences) comes later via the content pipeline. Not authoring all 500
   elements now.
2. **One book** for v1; model supports many, ship one. Home opens into the book.
3. **Mastery gate, not "seen once"** — an element is *mastered* when the learner has
   answered **N distinct example sentences** of it correctly (default `N = 3`,
   configurable). Distinct examples (shuffled) prove the rule, not a memorized
   sentence. A module unlocks the next when **all** its elements are mastered.
4. **Scrap** the 4 sentence-composition topics; design a fresh A1→B1 grammar arc.

## Hierarchy

```
Book  →  Module (×25)  →  Element (×20)  →  Example sentence (×5+)
```

- **Book** — top container. Holds ordered modules + the Apprendre/Réviser entry
  points (these now live *inside* the book, not on a global home).
- **Module** — the unlock unit. Ordered; module N+1 unlocks when module N is
  complete (all elements mastered). ≈ today's `GrammarTopic` but much larger.
- **Element** — one grammar point (e.g. "indefinite article un/une by gender").
  Carries a short rule note + a pool of ≥5 example sentences. **This is the SRS
  unit and the new middle layer.**
- **Example** — a single drillable sentence (prompt, answerTokens, tokenBank,
  translation, hint, explanation). ≈ today's `Exercise`, kept as-is.

### Model types (Swift)

- `Book { id, title, modules: [Module] }`
- `Module { id, bookID, sortOrder, title, ruleNote?, elements: [GrammarElement] }`
- `GrammarElement { id, moduleID, sortOrder, label, ruleNote, examples: [Exercise] }`
- `Exercise` — unchanged leaf (rename the property `topicID` → `elementID` for
  clarity; type/inputMode enums unchanged so existing `DrillView` logic is reused).

`GrammarTopic` is removed. JSON content moves from one-file-per-topic to
one-file-per-module, each file carrying its 20 elements and their examples.

## Core mechanic — element-level SRS + example shuffle

**One `review_status` row per ELEMENT**, not per sentence. Every time an element is
presented (in Apprendre or Réviser), a **different** example is sampled from its
pool (shuffle, avoiding immediate repeats). The 5+ sentences are interchangeable
test instances of the same rule.

Two notions of progress per element, both persisted:

- **Mastery (unlock gate)** — `distinctCorrect`: the count of *distinct* example
  ids answered correctly. Element mastered ⇔ `distinctCorrect ≥ N` (default 3).
  Drives module completion / unlock. Achievable in one session via the shuffle.
- **SRS state (retention)** — the existing ladder `[1,3,7,16,35]` keyed per element,
  driving the Réviser due/overflow queues. Unchanged math, new key.

### Apprendre (learn new elements)
Walks new elements in book→module→element order, capped by today's `newPerDay`
budget (**now counted in ELEMENTS/day**, default 10, cap 3–20). For each new
element: present shuffled examples one at a time, grading each, until the element
hits mastery (`distinctCorrect ≥ N`); then advance to the next new element. The
element's first grade also starts its SRS clock.

### Réviser (retain mastered elements)
Every element whose SRS schedule is due, one **fresh** example each, SRS-regraded
on answer. Overflow top-up toward the soft review target as today. Due/overflow
exclude suspended elements (the "too easy" feature carries over — now keyed per
element).

## Unlock / completion

- Module complete ⇔ every element in it is mastered (`distinctCorrect ≥ N`).
- Module N+1 unlocks when module N complete. First module always unlocked.
- Book progress = mastered-element count / total.

## Navigation / UI

- **Home = the book.** Header (book title), the **Apprendre** / **Réviser**
  buttons with the daily "X new · Y due" counts (now in elements), then the
  scrollable list of 25 modules with lock/current/done state + per-module progress
  (mastered/20).
- Tap an unlocked module → its element list (or straight into a learn session for
  that module's next unmastered element). Reuses `DrillSessionView` / `DrillView`;
  the drill UI itself is unchanged (token build / multiple choice, translation,
  hint, the "Trop facile" gate).
- Settings (gear) unchanged in spirit; `newPerDay` label now reads "elements".

## Persistence (SQLite)

New/changed tables:

- `books(id, title, sort_order)`
- `modules(id, book_id, sort_order, title, rule_note)`
- `elements(id, module_id, sort_order, label, rule_note)`
- `exercises(id, element_id, type, prompt, cue, answer_tokens, token_bank,
  input_mode, explanation, translation, hint)` — `topic_id` → `element_id`.
- `review_status(element_id PRIMARY KEY, learning_state, last_review_date,
  next_review_date, interval_days, first_seen_date, suspended,
  distinct_correct, mastered_example_ids)` — **rekeyed from exercise_id to
  element_id**; adds `distinct_correct` (INTEGER) and `mastered_example_ids`
  (JSON array, so distinctness survives restarts).

**Migration note.** This is a breaking schema change (review_status rekeyed). Dev
path = uninstall-to-reseed (`xcrun simctl uninstall booted wen.carambole`). Real
users have none yet, so no production migration needed — but this is the moment to
add the `PRAGMA user_version` scheme flagged in CLAUDE.md tech-debt, since we are
already rewriting the schema. (Tracked as a plan task.)

## Content — the 25-module arc (A1 → B1)

Seed **Module 1 fully** (20 elements × ≥5 sentences), grammar-audited + linted;
optionally Module 2. The rest are titled now, authored later via the pipeline.

1. Articles & gender (le/la/les, un/une/des)
2. Subject pronouns + être (present)
3. avoir (present) + il y a
4. Regular -ER verbs (present)
5. Negation (ne…pas / n')
6. Questions (est-ce que, intonation, inversion)
7. Adjectives — agreement & placement
8. Possessive adjectives (mon/ma/mes…)
9. Regular -IR / -RE verbs (present)
10. Prepositions of place + à/de contractions (au, du, aux, des)
11. Plurals & partitive (du/de la/des), quantities
12. Futur proche (aller + infinitive)
13. Passé composé with avoir
14. Passé composé with être + agreement
15. Pronominal / reflexive verbs
16. Imparfait
17. Direct & indirect object pronouns (le/la/les, lui/leur)
18. y and en
19. Comparatives & superlatives
20. Imperative
21. Futur simple
22. Conditionnel présent (politeness, hypotheticals)
23. Relative pronouns (qui / que / dont / où)
24. Subjonctif présent (introduction)
25. Si-clauses + synthesis review

## Implementation plan (task breakdown)

Each task: fresh implementer subagent → spec review → code-quality review → build
gate (`xcodebuild … iPhone 16 CODE_SIGNING_ALLOWED=NO` = BUILD SUCCEEDED) → commit.

- **T1 Model** — `Book`, `Module`, `GrammarElement`; retarget `Exercise.elementID`;
  delete `GrammarTopic`. Codable + JSON contract + `#if DEBUG` self-tests.
- **T2 Persistence** — new tables, `element_id` rekey, `distinct_correct` /
  `mastered_example_ids`, `user_version` migration scaffold; loader reads
  module JSON.
- **T3 SRS/queues** — element-level `ReviewStatus`; example sampler (shuffle, no
  immediate repeat); `StudyScheduler` new/review queues over elements; mastery
  predicate.
- **T4 Learn/Review sessions** — Apprendre drills an element to mastery; Réviser
  one fresh example per due element; element-level grading + `distinctCorrect`
  bump; "Trop facile" rekeyed per element.
- **T5 Book UI** — book home (Apprendre/Réviser inside + counts), module list with
  state/progress, module → session wiring.
- **T6 Content** — Module 1 authored (20 elements × ≥5), grammar-audited; manifest;
  `lint_topics.py` updated to the new contract. (Module 2 optional.)
- **T7 Cleanup** — remove dead `GrammarTopic`/topic seeders; update CLAUDE.md.

## As built — deviations from the plan above

- **Content is NOT persisted in SQLite.** Books/Modules/Elements/Examples load
  in-memory from bundle JSON each launch (`ContentLoader`). Only `review_status`
  persists (rekeyed to `element_id`, plus `distinct_correct` /
  `mastered_example_ids` / `suspended`). This dropped the planned content tables
  and all their CRUD — far less surface, and the content-migration concern with it.
  Setup includes a one-time dev migration: drop obsolete `topics`/`exercises` and
  the old exercise-keyed `review_status`.
- **Module-complete = all elements mastered** via `distinct_correct >= 3` (or
  suspended), as planned — achievable in one session through the shuffle (no forced
  multi-day waits).
- **Back/forward read-only review inside a session was dropped** (it existed in the
  old flat `DrillSessionView`). The element/example driver is forward-only;
  revisiting is the job of the Réviser queue.
- **`newPerDay` now counts ELEMENTS** (default 10, range 3–20). `masteryThreshold`
  is a constant (`StudySettings.masteryThreshold = 3`), not yet a Settings control.
- **Status:** structure + Module 1 shipped and merged-pending. Modules 2–25 are
  titled only; T7 cleanup folded into the same commit.

## Open / deferred

- Multi-book shelf UI (model ready, UI later).
- Pipeline reconciliation: current pipeline emits verb-conjugation exercises; the
  new arc is broader grammar — adapt templates before scaling content.
- `N` (mastery threshold) and `newPerDay` unit ("elements") exposed in Settings.
