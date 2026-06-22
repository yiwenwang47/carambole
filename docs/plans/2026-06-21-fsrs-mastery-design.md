# FSRS Memory-Strength Mastery — Design

**Date:** 2026-06-21
**Branch:** `fsrs-mastery` (off `main`, head `4360ff4`)
**Status:** Design locked, not yet implemented.

## Problem

The current mastery gate is `distinctCorrect >= 3` — a count of distinct example
sentences answered correctly for an element. Two flaws surfaced while inspecting a
real install (150 maîtrisé / 0 en cours):

1. **Too lenient / ignores the forgetting curve.** `recordCorrect` only inserts
   into a set; the count is add-only and monotonic. Three correct answers in ONE
   session (massed practice, same minute) graduate an element instantly. The SRS
   ladder `[1,3,7,16,35]` and `learningState (.new→.learning→.learned)` model
   spacing in parallel, but the mastery / unlock / progress gate **ignores them** —
   it reads only the raw count.
2. **Mistakes don't regress progress.** A wrong answer resets the SRS *interval* to
   1 (resurfaces sooner — correct for scheduling) but never lowers `distinctCorrect`
   and never removes the element from maîtrisé. Only "Trop facile → wrong"
   (`clearReviewStatus`) ever un-counts. A normal miss costs nothing.

Consequence of the learn loop ("drill an element to 3-distinct-correct in the
session, then advance"): between sessions every touched element is either fully
maîtrisé or untouched, so **en cours is always 0** — the middle bar segment never
populates.

## What Lingvist does (research, 2026-06-21)

- **Continuous probability-of-recall, not a count.** Custom **ACT-R** implementation
  (Anderson & Lebiere 1998). Each word+learner carries a **memory strength 0–100%**
  = how close to forgotten (0) vs instantly available (100). Decays over time
  (forgetting curve).
- **Schedule trigger:** review when predicted recall decays to **~80%** (their
  empirically-found sweet spot).
- **Every answer updates the model.** Miss → strength drops, resurfaces sooner. Hit
  → strength up, interval stretches.
- **No "3 correct = done" gate, and no completion bar at all.** "Known" is not a
  finish line — success metric = the learner retains ~80% of all words seen. Memory
  is a moving estimate, never permanently banked.

Both of the user's instincts (too lenient; misses should regress) match Lingvist.
The current count gate is the lenient outlier. But Lingvist has **no completion
bar** (open-ended vocabulary, always decaying); Carambole is a **bounded 500-element
course** and DOES want a finish line. So: borrow Lingvist's memory-strength +
miss-regresses idea, but keep a completion target.

Sources:
- https://lingvist.com/blog/spaced-repetition-in-learning/

## Locked decisions

1. **Full memory-strength model**, driven by **FSRS** (what Anki ships):
   per-element `stability S` + `difficulty D`, power-law recall
   `R(t) = (1 + FACTOR·t/S)^DECAY` (the FSRS-6 curve, `DECAY = -w[20]`,
   `FACTOR = 0.9^(1/DECAY)-1`, so `R(S,S)=0.90`). Ships pre-tuned default params (FSRS-6 weight vector)
   so it works on day one with zero user training. FSRS computes its own intervals →
   **retires the `[1,3,7,16,35]` ladder and the `.new/.learning/.learned` enum**
   from the gate (columns kept, no longer authoritative).
2. **Sticky graduation finish-line bar + at-risk band.** The completion bar is
   **monotonic** — an element counts maîtrisé once it first graduates and never
   un-counts from decay. Forgetting surfaces in a SEPARATE "fragile" band, not as a
   shrinking %. Mirrors Lingvist's split (cumulative learned vs current retention).
3. **Graduation requires spaced success.** `S` only climbs past the 21-day bar
   through successful reviews on *separate days* (FSRS math). Same-session
   3-in-a-row keeps `S` small → cannot graduate. **Kills the accidental-massing
   leniency.**
4. **Misses regress health, not the finish line.** A wrong answer (FSRS *Again*)
   collapses `S`, can pull a graduated element into **fragile** and drops its review
   interval to ~now. The sticky maîtrisé count does not lie; the fragile band + the
   review queue show the slip.
5. **Two graduation paths, by design:**
   - **Earned** — `S` crosses 21d through spaced successful reviews (the honest,
     curve-respecting path).
   - **Self-attested skip** — "Trop facile" + correct → **instant sticky graduate +
     suspend from review** (preserves today's `setSuspended`-counts-as-done
     behavior). Suspended → never decays into fragile. The one remaining "instant
     maîtrisé" loophole, but it is user-initiated, explicit, and self-defeating —
     not the accidental massing being killed. Legit advanced-learner skip.
6. **Un-graduate ("remettre en cours").** A graduated element can be demoted back to
   en cours (for accidental graduation). Mechanic: clear `graduated_date`, clear
   `suspended`, set `nextReview ≈ now`, knock `S` below 21d (keep `D`), leave the
   `mastery_log` row (historical, matches `clearReviewStatus` convention). Two
   surfaces: an **undo toast** right after "Trop facile" (catches the accidental
   case at the moment), AND a durable **module element-list** with a swipe action.
7. **v4 migration re-derives the existing 150 honestly** (not grandfathered, not
   wiped). Seed FSRS state from the spacing data already stored, recompute
   graduation. Deep-ladder elements graduate; massed ones demote to en cours. The
   bar honestly re-rates on day one.

## State model

Per element, derived every refresh:

| Bucket    | Rule                                          | Bar          |
|-----------|-----------------------------------------------|--------------|
| à venir   | no FSRS state (never seen)                     | grey segment |
| en cours  | has state, `S < 21d` (not yet durable)         | amber segment — fills the empty middle |
| maîtrisé  | **sticky flag** `graduated_date != NULL`; set once `S >= 21d` after a successful review (or via too-easy skip). Never un-set by decay. | green segment (monotonic) |
| fragile   | maîtrisé AND `R(now) < 0.80`                    | ⚠ chip + priority in Réviser, NOT a bar drop |

## Grading & scheduling

**Binary → FSRS rating** (no new drill UI):

| Drill outcome           | FSRS rating | Effect                                   |
|-------------------------|-------------|------------------------------------------|
| wrong                   | Again (1)   | `S` collapses, relearn, resurface ~now   |
| correct                 | Good (3)    | `S` grows normally                       |
| "Trop facile" + correct | Easy (4)    | `S` jumps; ALSO flips sticky `graduated_date` + suspends |
| "Trop facile" + wrong   | —           | `clearReviewStatus` (back to unseen), unchanged |

`gradeElement` swaps `recordCorrect` + `SRSScheduler.grade` for a single
`FSRS.next(S, D, elapsedDays, rating)` → writes back `S, D, lastReview, nextReview`.

**Scheduling.** Next review when predicted `R` decays to **0.90**
(`desiredRetention`); FSRS computes the interval. Réviser queue = elements with
`R(now) <= 0.90`, **fragiles first** (lowest R).

**Learn-loop change (real behavior shift).** Today Apprendre drills one element to
`distinctCorrect >= 3` in-session then advances — exactly the massing being killed.
New rule: Apprendre **introduces** an element (1–2 correct = "seen", enters FSRS as
en cours), then advances. **Graduation happens later, across review days**, not in
the intro session. So:
- Apprendre = meet new elements (breadth).
- Réviser = where graduation actually happens (spaced depth).
- A session can no longer complete an element to maîtrisé.
- **Module-unlock gate loosens to en-cours-or-better (seen)** — else nothing unlocks
  for weeks of review. (Consequence worth watching.)

## Persistence & migration (v4, additive — never edits an earlier block, never drops)

New columns on `review_status`:
```sql
ALTER TABLE review_status ADD COLUMN stability      REAL;   -- S; NULL = never seen
ALTER TABLE review_status ADD COLUMN difficulty     REAL;   -- D 1–10
ALTER TABLE review_status ADD COLUMN graduated_date REAL;   -- sticky flag = non-NULL
```
Kept legacy (no longer gate the bar): `interval_days`, `learning_state`,
`distinct_correct`, `mastered_example_ids`. Still live: `suspended`,
`last_review_date`, `next_review_date`. The graduated count reads the live
`graduated_date IS NOT NULL` flag — exact, never the log.

**v4 backfill** (one-time, idempotent, forward-only):
1. Seed FSRS state from existing spacing: `S <- max(interval_days, ε)` (the old
   interval is a stability proxy — the day-gap it had survived); `D <- default
   nudged by learning_state` (.learned easier, .new mid).
2. Re-derive graduation: `graduated_date <- last_review_date` iff `S >= 21d`.
   Suspended elements keep graduated. Massed interval-1 elements → no flag → en
   cours.

**`mastery_log`** (pace feed) is left untouched in v4 — new graduations append going
forward; pre-migration pace stays approximate (already documented forward-only since
v2/v3). The bar count is exact from the live flag; only the 14-day *pace* window is
approximate at the boundary and ages out on its own.

## Finish-estimate rewire (`ProgressEstimate`)

Mostly input renames — the value type's shape holds:
- `mastered` → **`graduated`** count (live flag). Segments: maîtrisé=graduated ·
  en cours=seen−graduated · à venir=unseen.
- **`fragile`** = new annotation (graduated AND `R(now) < 0.80`); subset of
  maîtrisé, does not change segment math; drives the ⚠ chip only.
- Pace = graduation events/day from `mastery_log`; finish = graduate all 500.
- Early-state gate (≥3 days history AND ≥3 window events) unchanged.

## FSRS params

Ship the published **FSRS-6 default weight vector** as a constant
(`FSRS.defaultParams`, ~21 weights). No training. Tunable constants:
```
desiredRetention    = 0.90   // review when R decays to this
graduationStability = 21     // days; S bar for sticky maîtrisé
fragileRecall       = 0.80   // R floor before a graduate goes fragile
```

## Build sequence (subagent-driven: implement → spec review → code-quality review)

Build gate EXIT 0 (`-destination 'id=<sim-udid>'`, name:iPhone 16 is broken — see
CLAUDE.md), screenshot UI changes, commit per task, final whole-branch review.

| T  | Scope                                                                                          | Verified by |
|----|------------------------------------------------------------------------------------------------|-------------|
| T1 | `Core/FSRS.swift` pure value type: `next(S,D,elapsed,rating)`, `retrievability`, `interval`. Default params. No persistence/UI. | `_selfTest()` vs known FSRS reference vectors |
| T2 | v4 migration + S/D/graduated columns + backfill + `DataManager` FSRS read/write + graduation write-hook to `mastery_log` | migration idempotent; build |
| T3 | `gradeElement` binary→rating→`FSRS.next`; too-easy→Easy+graduate+suspend+undo toast; Apprendre intro-not-master loop; unlock gate→seen | build + sim |
| T4 | `BookViewModel`/`BookView` four buckets + fragile chip + `ProgressEstimate` rewire; Réviser = R≤0.90 fragiles-first | screenshot |
| T5 | Module element-list view + swipe "remettre en cours" demote + `DataManager.demote` | screenshot |

**Biggest risks:** T1 FSRS math correctness (mitigate: self-test against reference
vectors) and the T3 learn-loop reshape (Apprendre stops completing elements — real
UX shift; module unlock now gates on *seen*, not *mastered*).
