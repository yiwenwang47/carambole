# Carambole — Learning Cycle & Schedule Design

**Date:** 2026-06-19
**Status:** Proposed (post-pivot). Drives the next implementation phase.

Captures how the daily learning loop should work, how it maps to the app, and how
to size the spaced-repetition schedule. Based on the user's target: ~20 new
grammar examples/day, ~200+ reviews/day, tunable pace, ~1–2 h/day.

A "grammar example" = one card. "I was" (j'étais) and "you were" (tu étais) are
two separate cards. One conjugation table ≈ 6 cards.

## 1. Learning cycle

```
new intake (capped)  →  short-interval reinforcement  →  long-interval review  →  mature
   ~20/day               1, 2, 4, 8... days apart         ...60, 120, 240 days     rare
        │                         │                              │
        └── fail anywhere ────────┴──────────────────────────────┘
                  card resets to interval 1, re-enters the churn
```

1. **Intake** — each day a HARD-CAPPED number of never-seen cards introduced.
2. **Reinforcement** — each card climbs an expanding-interval ladder.
3. **Daily review** — SRS surfaces everything due today (young + maturing + lapses).
4. **Lapse** — wrong → reset to interval 1. This is most of review volume.
5. **Maturation** — repeatedly-passed cards reach long intervals and retire.

Steady state: **daily load = N new + (~k × N) reviews**, k = touches/card to maturity.

## 2. App behavior — two knobs

The two existing surfaces ARE the two knobs:
- **Topic map** = new intake (learn). Today uncapped (whole topic at once).
- **Daily Review** = SRS review queue. Today uncapped; ladder `[1,3,7,16,35]` loops
  at 35 forever (unbounded mature load — must change).

Design rule (matches user intuition): **cap NEW, let REVIEW float.**
- New is the throttle: it sets long-term review load (≈ k×) AND course speed.
- Reviews are downstream of the schedule + lapses. Capping reviews builds "review
  debt" → retention breaks. Cap only as an emergency valve, with a visible
  "behind by N" signal.

## 3. Schedule sizing

**Core identity: review load ≈ k × new-rate.** With a ~9-step ladder + lapses,
k ≈ 10 → **20 new/day ⇒ ~200 reviews/day at maturity.** The user's two numbers are
the same system viewed twice — self-consistent.

**Ladder (replace `[1,3,7,16,35]`):** `1, 2, 4, 8, 15, 30, 60, 120, 240` days →
then mature (≈ yearly or graduate out). Growing intervals are required so mature
cards stop dominating the daily queue.

**Ramp (gentle, good):** review load fills as ladder stages populate.

| time     | stages filled | ~reviews/day (20 new, +lapses) |
|----------|---------------|--------------------------------|
| week 1   | 1,2,4         | ~60                            |
| month 1  | +8,15,30      | ~110                           |
| month 3  | +60           | ~150                           |
| month 6+ | +120,240      | ~190–210                       |

**Time check:** new ~30 s (intro+hint), review ~12 s. `20×30s + 200×12s ≈ 50 min`
core; ~60–75 min with thinking/lapses ⇒ **20/200 ≈ ~1 h.** For ~2 h push new→30 or
reviews→~400. The 1–2 h bracket is well-calibrated.

## 4. Is 20/200 balanced? Yes — one caveat

- 10:1 ratio is healthy / retention-heavy. ✓
- Cap-new / float-review is the correct asymmetry. ✓
- **Caveat = content supply, not scheduling.** 20 new/day = ~600/month = ~7,300/yr.
  App currently has ~20 exercises total. Sustaining intake is a CONTENT-GENERATION
  problem: needs templated/generated content (pronoun × verb × tense × example),
  grammar-audited. This is the real engineering lift (P5).

## 5. Tunability

- **Primary: `newPerDay`** (5–40, default 20). The one real pace control.
- **`reviewCap`** — optional ceiling for bad days; overflow deferred; show
  "behind by N". Default high/off.
- **Optional time-budget mode** — target minutes → back-solve `newPerDay`.
- Home shows "X new today · Y due" and respects caps (today it dumps all due).

## 6. Implementation changes to realize this

a. **Settings + daily-driven home** — `newPerDay`/`reviewCap`, a home that shows
   today's new + due counts and honors the caps.
b. **Decouple "introduce N new" from "finish a whole topic"** — intake should pull
   the next N unseen cards across the course, not require completing a topic.
c. **Ladder swap** — the growing 9-step ladder + graduation/long-tail in
   `SRSScheduler` (replaces the 35-day loop).
d. **Content pipeline** — generate volume (templated/LLM + grammar audit). The
   binding constraint on the whole schedule.

## Decisions (locked 2026-06-19)

- **Ladder: keep `[1,3,7,16,35]`** (NOT the years-long growing ladder). Goal is
  mastery within ~a month via many touches, not multi-year retention. Mature
  cards keep recurring at 35 days (no graduation) — fine because new is capped.
- **Overflow review.** When the due-stack empties before the daily review target,
  top up with not-yet-due cards (e.g. lowest-familiarity / soonest-due first) so
  the user can keep reviewing. "Weak accumulation is still accumulation" — a
  marginal extra touch beats idling. Overflow reviews still grade normally.
- **`newPerDay` = 20 default** (tunable 5–40), a HARD cap. Review is a *target*
  (~200) the user may EXCEED via overflow — not a hard cap. (No `reviewCap` v1.)
- **Content = generated**, not hand-templated: deterministic conjugation
  (verbecc) + LLM sub-agents, contract-validated. BUILT — see
  `tools/content_pipeline/` (57 tests, proof run 70/72 accepted).

## Still to build (app-side scheduler — separate branch)
a. Settings (`newPerDay`, review target) + a daily-driven home ("X new · Y due").
b. Decouple "introduce N new/day" from "finish a whole topic".
c. Overflow-review queue (top up past the due-stack toward the target).
(Ladder unchanged; `SRSScheduler` already `[1,3,7,16,35]`.)
