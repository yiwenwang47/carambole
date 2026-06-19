# Generation agent — French conjugation exercises from locked seeds

You turn deterministic conjugation **seeds** into natural drill exercises for a
French-grammar app. The grammar is ALREADY decided by the seed — you only write
the sentence and the English helper text. You must NEVER change a verb form.

## Input
A JSONL file of enriched seeds (path given to you). Each line:
```json
{"verb":"parler","mood":"indicatif","tense":"présent","person_index":0,
 "pronoun":"je","correct_form":"parle","distractors":["parles","parlons","parlez"],
 "topicID":"indicatif_present","id":"indicatif_present_parler_0"}
```

## Output
Write a JSONL file (path given to you), ONE exercise object per input seed, in the
same order. Each object has EXACTLY these keys:

| key | how to set it |
|-----|----------------|
| `id` | copy `seed.id` |
| `topicID` | copy `seed.topicID` |
| `type` | always `"conjugate"` |
| `inputMode` | always `"multipleChoice"` |
| `cue` | copy `seed.verb` (the infinitive) |
| `answerTokens` | `[seed.correct_form]` — copy verbatim, do not alter |
| `tokenBank` | the four strings `seed.correct_form` + `seed.distractors`, in a MIXED order (do NOT always put the answer first). Copy each string verbatim — same accents, no additions, no removals |
| `prompt` | **you write this** (see rules) |
| `translation` | **you write this** — accurate English of the full sentence with the verb filled in |
| `hint` | **you write this** — short English nudge about the ending/rule; do NOT reveal the answer |
| `explanation` | **you write this** — short English "why this form" (shown after answering) |
| `_seed` | copy the entire input seed object verbatim (used for verification) |

## Prompt rules (the only real craft)
- A short, natural, beginner-level French sentence.
- Use `seed.pronoun` as the subject, LITERALLY (capitalize if sentence-initial:
  je→Je, il→Il, ils→Ils…). Do NOT swap in a noun or `on` — the subject must be the
  exact pronoun so it can be verified. The only allowed change is correct elision
  of `je`→`j'` before a vowel (j'ai, j'étais).
- Put `___` exactly where the conjugated verb goes.
- End with the infinitive cue in parentheses: `(parler)`.
- Make the sentence fit the tense's typical meaning (imparfait → ongoing/habitual
  past, futur → future, etc.).
- Do NOT reveal the conjugated answer anywhere in the sentence or hint.
- Accents must be correct everywhere.

## Worked example
Seed:
```json
{"verb":"parler","tense":"présent","pronoun":"je","correct_form":"parle",
 "distractors":["parles","parlons","parlez"],"topicID":"indicatif_present",
 "id":"indicatif_present_parler_0", ...}
```
Output line:
```json
{"id":"indicatif_present_parler_0","topicID":"indicatif_present","type":"conjugate",
 "inputMode":"multipleChoice","cue":"parler","answerTokens":["parle"],
 "tokenBank":["parlons","parle","parlez","parles"],
 "prompt":"Je ___ français tous les jours. (parler)",
 "translation":"I speak French every day.","hint":"je form of an -ER verb ends in -e.",
 "explanation":"With 'je', a regular -ER verb takes the -e ending: parle.",
 "_seed":{"verb":"parler","mood":"indicatif","tense":"présent","person_index":0,
   "pronoun":"je","correct_form":"parle","distractors":["parles","parlons","parlez"],
   "topicID":"indicatif_present","id":"indicatif_present_parler_0"}}
```

## Hard constraints (output is auto-rejected otherwise)
- `answerTokens` must equal `[seed.correct_form]`.
- `set(tokenBank)` must equal `{seed.correct_form} ∪ seed.distractors` — exactly, no invented forms.
- `prompt` must contain `___` and the subject pronoun.
- `cue` must equal `seed.verb`.
Every exercise that violates these is dropped by the validator. Follow them exactly.
