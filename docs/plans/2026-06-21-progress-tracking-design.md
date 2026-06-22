# Progress tracking redesign — book completion bar + time-to-finish estimate

**Date:** 2026-06-21
**Branch:** `progress-tracking-estimate`
**Scope:** Give the learner an intuitive answer to four questions on the book home:
how much *new* did I learn today, how much did I *review* today, how *far through*
the book am I (%), and how much *more time* to finish. Minimal build — the data
mostly already exists; the gap is presentation plus one honest estimate.

## Research that shaped this

**Lingvist** (the reference app the user named) surfaces progress as three word
buckets — **learned · currently learning · "at-risk" (fading from memory)** —
plus daily/weekly graphs of words-learned and accuracy, and a weekly goal line.
Sources: [G2 reviews](https://www.g2.com/products/lingvist/reviews),
[Lingomee](https://lingomee.com/lingvist-review/),
[FluentU](https://www.fluentu.com/blog/reviews/lingvist/).

**Completion / estimate norms:** only ~8% of users finish full app courses, and
learners given **realistic, evidence-based timelines are 3.2× more likely to
finish** than those sold a marketing promise
([MOOC completion study](https://files.eric.ed.gov/fulltext/EJ1067937.pdf),
[OptiLingo](https://www.optilingo.com/blog/language-learning-secrets/estimating-times-to-fluency/)).
FSI "hours to fluency" framing is the wrong unit here. The right unit for *this*
app is **elements remaining ÷ the learner's actual recent pace = days left**.

Lingvist's three-bucket model maps directly onto Carambole's element states:
`maîtrisé` (mastered) · `en cours` (seen, not yet mastered) · `à venir` (not yet
introduced). That mapping is the visual spine of this design.

## Decisions (locked during brainstorming)

1. **Estimate basis = recent *actual* pace**, not the daily-goal setting. Honest
   and adaptive — skipped days slow it, grinding speeds it. Falls back to an
   "early state" message when there isn't enough history yet.
2. **Finish-line = element *mastered*** (`distinct_correct ≥ 3` **OR** `suspended`
   — the same `satisfiedIDs` gate the unlock chain already uses), not merely
   seen-once. So `% complete = mastered / total`, and the pace that matters is
   *mastery completions per day*.
3. **Headline visual = a segmented book bar** (three Lingvist-style buckets), not
   a ring or a numbers-only panel.
4. **Scope = bar + estimate only.** No new screens, `HistoryView` untouched. Add
   one lightweight `mastery_log` table for an honest pace. (Considered and
   deferred: enriching History with a mastered/day tone + cumulative trend; a
   dedicated Progrès dashboard with per-module grid and pace chart.)
5. **Fix the confusing daily zone while we're here.** The old book home stacked
   two look-alike lines — `Aujourd'hui · 6 new · 12 due` (to-do, ahead) directly
   above `6 appris · 12 révisés` (done, behind). Same shape, opposite meaning.
   The to-do counts move **onto the action buttons** (`Apprendre · 6`,
   `Réviser · 12`); one `fait :` done-line remains.

## Final book-home layout

```
Français — Fondations
████████░░░░▒▒▒▒▒▒▒▒▒▒  18% maîtrisé
 maîtrisé · en cours · à venir
90 / 500 · ≈ 55 j restants · ~15 août
─────────────────────────────────────
AUJOURD'HUI
  fait : 6 appris · 12 révisés   ›        (→ HistoryView)
  [ Apprendre · 6 ]   [ Réviser · 12 ]    (badge = queue; hidden at 0)
  révision par tour  10 · 20 · 50         (existing selector, unchanged)
```

## 1. Data layer — `CoreDataManager`, `user_version` 3

New table mirroring the existing `review_log`:

```sql
CREATE TABLE IF NOT EXISTS mastery_log(
  element_id TEXT PRIMARY KEY,   -- mastery happens once → PK on element_id alone
  day_start  REAL NOT NULL       -- Calendar.startOfDay timestamp of the crossing
);
```

- **Write hook:** inside `upsertReviewStatus`, after recomputing
  `distinct_correct` / `suspended`, if the element is now *satisfied* →
  `INSERT OR IGNORE INTO mastery_log VALUES(element_id, startOfDay(now))`.
  Idempotent; no cost once logged.
- **Migration `if version < 3` block** (additive only — per the house rule, never
  edit v1/v2, never DROP a user-data table): `CREATE TABLE IF NOT EXISTS …`, then
  **backfill once** — for every currently-satisfied element insert a row stamped
  at its `last_review_date` day (best available proxy; identical trick to the v2
  `review_log` backfill). Mastery-per-day before this migration is therefore
  forward-only — documented in-code and in Known tech debt, exactly as v2 was.
- **New read:** `fetchMasteryLog() -> [(elementID: String, dayStart: Date)]`.
- `fetchSeenElementIDs()` (exists) drives the `en cours` segment (seen − mastered).

No content/JSON changes.

## 2. Estimate math — `ProgressEstimate` (pure-logic, self-tested)

Inputs: `total`, `masteredIDs`, `seenIDs`, `masteryLog`, `today`,
`firstActivityDate`.

**Segments** (sum to `total`):
- `maîtrisé` = mastered count
- `en cours` = `seen − mastered`
- `à venir` = `total − seen`

**% complete** = `mastered / total`.

**Pace** (trailing, calendar-honest):

```
window     = 14 days
elapsed    = min(window, daysSince(firstActivityDate))   // don't ÷14 on day 5
masteredIn = mastery_log rows with day_start in [today−13 … today]
pace       = masteredIn / max(1, elapsed)                // elements / calendar-day
```

Dividing by *calendar* days (not study-days) is intentional: "how much more
**time**" means wall-clock, so skipped days correctly lengthen the estimate.

**Days-left** = `ceil((total − mastered) / pace)`. **Projected date** =
`today + daysLeft`, shown fuzzy (`finir ~15 août`). Format: `< 90 j` → "≈ N j";
`≥ 90 j` → "≈ N mois". Pace one decimal (`8,5/j`).

**States:**
- `mastered == total` → "Terminé ! 🎉", 100%, estimate suppressed.
- `masteredIn < 3` **or** `elapsed < 3` → no number; show
  *"Continue quelques jours pour estimer la durée."* (kills a wild "≈ 900 j" on
  day one). The same gate prevents divide-by-near-zero pace.

Deterministic → `#if DEBUG _selfTest()` with an injected `today` and a fixed UTC
calendar (the existing pattern). Cases: fresh install (early-state), steady pace,
near-done, all-done, skipped-days (low pace → longer estimate).

## 3. UI — `BookView` + `BookViewModel`

New summary block at the **top of the existing "Aujourd'hui" card**, above the
daily zone.

**Segmented bar:** one `GeometryReader`, width `W`, height ~12pt, masked by an
outer `Capsule`. Three sub-rects, widths `segment/total · W`. Palette:
`maîtrisé` = `AppColor.saffron` (solid) · `en cours` = `saffron.opacity(0.28)` ·
`à venir` = `AppColor.hairline`. A zero-width segment is skipped (no sliver); the
whole block hides when `total == 0`; `mastered == total` renders full saffron.

**Legend:** three small dots + labels in `Font.appLabel` `.uppercaseLabel()`.

**Stat lines** (`Font.appExplain`, graphite): line 1 `mastered/total · ≈ N j
restants · ~<date>`; collapses to the single early-state sentence when pace
isn't ready yet.

**Daily zone:** one `fait : N appris · M révisés ›` line (taps to `HistoryView`,
keeping the existing `learnedToday` / `reviewedToday`); to-do counts move onto the
buttons as badges (`Apprendre · newAvailableToday`, `Réviser · dueCount`), badge
hidden when 0. `révision par tour` selector unchanged.

**ViewModel:** `refresh()` already loads `satisfiedIDs`. Add published `total`,
`seenCount` (`fetchSeenElementIDs ∩ book`), and a computed
`estimate: ProgressEstimate` built from those + `fetchMasteryLog()` +
`firstActivityDate`. One extra query per refresh. Block is static (not tappable) —
History already provides the deep dive.

## 4. Edge cases + verification

Edge cases are folded into §2/§3 (zero segments, total 0, done, early-state, 0
badges, idempotent v3 migration so reinstalls keep data).

**Build via subagent-driven development** (house rule) — three tasks, each
implement → spec-compliance review → code-quality review → mark done:

- **T1 — Data:** `mastery_log` table, v3 migration + backfill, write-hook in
  `upsertReviewStatus`, `fetchMasteryLog`.
- **T2 — Logic:** `ProgressEstimate` pure type + `#if DEBUG _selfTest()`.
- **T3 — UI:** `BookView` / `BookViewModel` — segmented bar, estimate lines,
  button badges, single `fait` line.

**Gate:** `xcodebuild build … -destination 'id=<sim-udid>' CODE_SIGNING_ALLOWED=NO`
→ EXIT 0 (explicit device id — the `name:iPhone 16` destination fails here, sims
at 18.5 vs latest 26.5), launch self-tests pass, then screenshot-validate the bar
through the existing `CB_HARNESS` DEBUG harness and **revert + `simctl uninstall`
/ reinstall the clean build before judging** (the known stale-build gotcha).

## Known debt added

- **Mastered-per-day before the v3 migration is forward-only** (backfill seeds
  only one row per satisfied element at its last-review day). Same forward-only
  caveat as the v2 `review_log`; cumulative `% complete` is always exact, only the
  *daily mastery rate* history is approximate for pre-migration days.
