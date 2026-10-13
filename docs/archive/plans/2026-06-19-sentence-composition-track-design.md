# Sentence Composition Track — Design

**Date:** 2026-06-19
**Status:** Approved (brainstorm). Ready to curate.
**Branch:** `sentence-composition`

## Goal

Shift the course start from verb-conjugation drilling to **sentence
composition**. The learner already knows words but struggles to assemble full
sentences (design decision #5). The first thing they touch should be building
real French sentences, not conjugating tables.

Replace the old placeholder verb topics (`01_etre_avoir_present` …
`04_imparfait`) entirely with a 4-topic **"Composer des phrases"** track.

## Scope

A linked track of 4 topics, unlock chain `01 → 02 → 03 → 04`, sharing one
daily-life vocabulary so tokens recur and compound.

| # | id | Teaches | prereq |
|---|----|---------|--------|
| 01 | `phrases_svo` | Subject + verb + object order; article+noun (un/une/le/la) | null |
| 02 | `phrases_adjectifs` | Adjective placement (post-noun default; petit/grand/beau pre-noun) + gender agreement | `phrases_svo` |
| 03 | `phrases_prepositions` | à / de / dans / avec — place & movement | `phrases_adjectifs` |
| 04 | `phrases_negation_questions` | ne…pas wrap; est-ce que / inversion | `phrases_prepositions` |

### Shared word bank (daily life)

- Nouns: `pomme, chat, chien, maison, café, ami, livre, eau`
- Verbs (pre-conjugated, present): `mange, parle, habite, aime, va, veut, a, est`
- Articles / adjectives / prepositions introduced per topic.

### Key design call — composition, not conjugation

Verbs are handed to the learner **already conjugated** as tokens. Topics 01–04
drill *word order + agreement + sentence structure*, NOT verb endings.
Conjugation as a skill is out of scope for this track (the old conjugation
topics are removed). This is the biggest deviation from prior content and is
intentional: it keeps the learner composing from day one.

## Exercise design

Each topic = 1 English `ruleNote` intro card + **6 drills**.

Default split per topic: **4 `buildFromTokens`** (compose a full sentence) +
**2 `multipleChoice`** (isolate a single decision point).

### Distractor strategy

Prior content's token banks barely exceeded the answer, making drills trivial.
New rule:

- `buildFromTokens` (`type: wordOrder`): `tokenBank` = answer tokens **+ 2–3
  controlled wrong tokens** targeting the lesson's likely error:
  - 01: wrong article gender (`un`/`une`), word-order bait.
  - 02: wrong adjective agreement (`grand`/`grande`), wrong position.
  - 03: wrong preposition (`à`/`dans`).
  - 04: misplaced `pas`, wrong question particle.
- `multipleChoice` (`type: genderArticle` or `fillBlank`): 1 answer + 3
  plausible same-category distractors.

### Difficulty ramp inside each topic

Drills 1–2 short (3–4 tokens, one decision). Drills 5–6 longer (6+ tokens, two
decision points).

### English ease-in (decision #5)

Every drill carries a subtle always-on `translation` plus a tap-to-reveal
`hint` naming the rule. `ruleNote` is a short English intro card per topic.

### Example (topic 01)

```json
{
  "id": "svo_02",
  "topicID": "phrases_svo",
  "type": "wordOrder",
  "prompt": "Construis : « She eats an apple. »",
  "cue": null,
  "answerTokens": ["Elle", "mange", "une", "pomme"],
  "tokenBank": ["Elle", "mange", "une", "un", "pomme", "mangent"],
  "inputMode": "buildFromTokens",
  "explanation": "Subject Elle + mange + une pomme (pomme is feminine).",
  "translation": "She eats an apple.",
  "hint": "Subject Elle + mange + une (pomme is feminine)."
}
```

### Grammar fidelity

These are not pure conjugations, so the content pipeline / verbecc does not
apply. Curate by hand: draft → grammar self-audit (gender, agreement, accents,
exact-match solvable) → user spot-check.

## Wiring & data fit (NO Swift changes)

The existing models already support everything:

- `ExerciseType` enum: `conjugate, fillBlank, genderArticle, wordOrder` — all
  used types map. `wordOrder` for builds; `genderArticle`/`fillBlank` for MC.
- `InputMode` enum: `multipleChoice, buildFromTokens`.
- `Exercise` Codable keys: `id, topicID, type, prompt, cue, answerTokens,
  tokenBank, inputMode, explanation, translation, hint`.
- `GrammarTopic` keys: `id, title, sortOrder, prerequisiteID, ruleNote,
  exercises`.

Steps:

1. Add `carambole/Resources/Topics/01_phrases_svo.json` …
   `04_phrases_negation_questions.json`.
2. Update `manifest.json` `topicFiles` to list ONLY the 4 new files.
3. Delete the 4 old topic JSONs.
4. The decoder skips any exercise with an unknown `type`/`inputMode`; lint each
   file against the enums before building.

### Reseed in dev

`TopicLoader.seedIfNeeded()` only seeds when `topicCount() == 0`. To load new
content: `xcrun simctl uninstall booted wen.carambole` then reinstall. This also
wipes `review_status` (clean SRS state — fine for dev).

## End-to-end verification

1. **Lint** — for every exercise: `answerTokens ⊆ tokenBank`, valid
   `type`/`inputMode`, non-empty `translation`/`hint`, exact-match solvable,
   unique ids.
2. **Build gate** — `xcodebuild build -project carambole.xcodeproj -scheme
   carambole -destination 'platform=iOS Simulator,name=iPhone 16'
   CODE_SIGNING_ALLOWED=NO` = EXIT 0.
3. **Boot sim + reseed** — uninstall/reinstall `wen.carambole`, launch.
4. **Screenshot walk** — home ("X new · Y due"), topic 01 intro card, a build
   drill, a correct answer, a wrong answer (confirm distractor engages), an MC
   drill, completion → topic 02 unlocked. Key shots repeated per topic.
5. **SRS smoke** — finish drills, confirm "Réviser" surfaces due items.

## Execution

Per repo discipline: subagent-driven (fresh implementer per topic → spec review
→ code-quality/grammar review → mark done), build gate EXIT 0 + screenshot per
topic, commit per topic.

Topic order: 01 first (validate the whole loop end-to-end on one topic before
mass-curating 02–04).
