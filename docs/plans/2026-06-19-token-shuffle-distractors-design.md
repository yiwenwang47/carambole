# Token-bank shuffle + harder construis distractors — design

**Date:** 2026-06-19 · **Status:** ✅ shipped (commit `365f8fc`, committed + PUSHED to `main`)

## Problem

Construis (`buildFromTokens`) and multiple-choice drills presented their candidate
chips in the **authored order**. Two consequences:

1. **Construis solvable left-to-right.** Authoring emitted `tokenBank` as
   `answerTokens` (in answer order) + a trailing distractor. 70% of banks had the
   answer tokens as a strict prefix, so a learner could solve by tapping the chips
   in display order without reading.
2. **MC answer pinned to row 0.** The single correct choice sat at index 0 in
   **1162 / 1166** MC drills.
3. **Too few / too easy distractors.** Banks carried only ~1.24 extra tokens on
   average, often a random unrelated word rather than a grammatically tempting
   wrong form.

User ask: *"make the construis questions harder. more word candidates. and please,
at least shuffle the candidates… right now they follow the exact order of the
correct answer"* + *"multiple choice should shuffle too."*

## Decisions

- **Shuffle in code, not in content.** A render-time shuffle fixes every drill at
  once (1440 construis + 1166 MC), is robust to however JSON is authored, and
  protects all future content. Content authoring no longer needs to worry about
  bank order.
- **Deterministic + stable per `id`.** A random-per-render shuffle would reshuffle
  chips mid-interaction (SwiftUI re-renders) and flip layout when a drill is
  revisited read-only via review navigation. So: seed a PRNG from the exercise
  `id` (same approach as the existing `Exercise.typeBit`), giving one fixed order
  per drill that is identical across launches, processes, and revisits.
- **Distractors authored, sized ≈1.6× answer length.** User chose hand-authored
  grammar traps over a runtime same-topic pool, and a bank ≈1.6× the answer length
  (min +2 distractors). Authored traps target the specific grammar each sentence
  teaches; a code pool can't.

## Design

### 1. `Exercise.displayBank` (Models/Exercise.swift)

```
seed64(id)            = FNV-1a 64-bit hash of the id (now also backs typeBit)
deterministicShuffle  = Fisher–Yates driven by a splitmix64 stream off the seed
displayBank           = shuffle; reseed (+golden) and retry until guards pass;
                        last resort = a single rotation
```

Guards (`passesShuffleGuards`):
- result must differ from the authored `tokenBank` order (visible change for every
  drill);
- for multi-token answers (`buildFromTokens`), the first `answerTokens.count` chips
  must not equal `answerTokens` in order (not solvable left-to-right);
- MC (single-token answers) only needs to differ from authored order — a uniform
  shuffle, so the answer lands at any row with no learnable position bias.

`TokenBuilderView` and `ChoiceView` render `displayBank` instead of `tokenBank`.
The builder maps placed-chip indices through that same array, so duplicate tokens
(e.g. `["la","la"]`) stay correct.

Covered by `Exercise._selfTest()` (permutation / stability / guards / distinct
across ids / duplicate tokens / MC / tiny bank), wired into the launch `#if DEBUG`
self-test block in `caramboleApp.swift`.

### 2. Authored distractors (Resources/Topics/*.json)

Every `buildFromTokens` bank rebuilt as `answerTokens` + N distractors, where
`N = max(len+2, round(1.6·len)) − len`. Distractors are real, correctly-spelled
French **wrong forms** a learner might mis-pick, prioritized per the module's
grammar: wrong conjugation / tense, wrong article gender-number, wrong agreement,
wrong preposition, indicative-vs-subjunctive, qui-vs-que, etc.

Result across all 25 modules: avg extra distractors **1.24 → 2.62**, bank/answer
ratio **1.65×**.

### 3. Tooling (tools/distractors/)

- `extract.py <module.json>` → per-drill spec `{id, prompt, translation, answer,
  answerTokens, existingDistractors, need}` for each `buildFromTokens` example.
- An authoring agent (one per module) reads the spec, writes `{id: [distractors]}`.
- `apply.py <module.json> <distractors.json>` → rebuilds each bank, **validates**
  (every drill covered, exact `need` count, distractors distinct and ≠ answer
  tokens, multiset subset preserved), and writes back with a **style-preserving
  serializer** (scalar arrays stay inline) so the diff is only the changed
  `tokenBank` lines. Module left untouched on any validation error.

## Verification

- `tools/lint_topics.py` clean (Codable contract + multiset bank + required
  English ease-in).
- `xcodebuild build … -destination 'id=<iPhone16 sim udid>'` → EXIT 0.
- App installs + launches; all content decodes; `Exercise._selfTest()` (and the
  rest) pass at launch (no assertion crash).
- Sim taps are not automatable in this environment (no idb/cliclick, Apple-events
  denied), so the shuffle was demonstrated with a Python replica of the exact Swift
  algorithm against real drill ids — e.g. `je suis à la maison`: JSON bank
  `[je,suis,à,la,maison,es,est,le]` → rendered `[la,à,es,je,maison,est,le,suis]`.

## As-built notes / open

- A few modules keep **over-regularization traps** (`prendu` for *pris*, `etrai`
  for *serai*, `s'elle` for *si elle*) — wrong forms learners actually produce, but
  they do show a non-word on screen. Kept intentionally (harder); trivially
  strippable to real-forms-only later.
- The literal answer → advance → tap-back gesture on a physical device is still
  unverified (same automation block as the rest of the drill loop).
