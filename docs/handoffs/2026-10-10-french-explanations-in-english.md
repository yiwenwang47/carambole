# Handoff: French `explanation` fields written in English

**Status:** open, not started. Found 2026-10-10 while building spot-the-error items.
**Scope:** content only (JSON). No Swift change is needed.

## The problem

Every drill example in `carambole/Resources/Topics/NN_*.json` has two explanation fields:

| field | language | shown as |
|---|---|---|
| `explanation` | **French** | first line, ink colour |
| `explanationEN` | English | second line, grey, beneath it |

About **1,055 of 2,606 examples (40 %)** have English text in the French
`explanation` field, e.g.:

```json
"explanation": "Ville is singular, so votre.",
"explanationEN": "\"ville\" is singular, so \"votre\"."
```

So the learner reads the same idea twice in English, or (82 cases where both
fields are identical) only once, because `Exercise.displayExplanationEN`
hides an English line that repeats the French one. The course's design
(CLAUDE.md, "Locked design decisions" #5 and the bilingual-explanation rule in
`tools/lint_topics.py`) is French first, English beneath.

Correct examples already in the content, to match in tone and length:

```
01_articles  « Devant une voyelle, « la » devient « l' » : « l'eau ». »
05_negation  « « un » devient « de » à la négation. »
13_pc_avoir  « « ils ont joué » : ont, pas sont. »
17_pronoms   « « la » remplace un nom féminin devant une consonne. »
```

## Where it shows in the app

- `carambole/Features/Drill/DrillView.swift:470` `reviewResultBlock` shows the
  explanation when the learner revisits an answered drill (‹ back chevron).
- `carambole/Features/Drill/MagnetBoard.swift:373` `DrillMissExplanation` shows
  the explanation after a wrong answer in spot-the-error, and for every drill
  type in the DEBUG test book.
- `carambole/Models/Exercise.swift:103` `displayExplanationEN` hides an English
  line that repeats the French one (comparison ignores case, quotes and spaces).
  Once a French line is really French, the English line will show again.
- `Exercise.spotVariant` uses `spot.explanation` when the example's `spot`
  carries its own (a hand-checked French line written for that error);
  otherwise it falls back to the example's `explanation`.

## Find the affected drills

```bash
python3 tools/explanation_lang.py                 # count per module; exit 1 while any remain
python3 tools/explanation_lang.py --list          # one line per drill: id [category] text
python3 tools/explanation_lang.py --json out.json # full records incl. explanationEN
```

It is a heuristic over English vs French function words outside quoted French.
Categories: `english` (892), `mostly-english` (143), `mixed` (20, e.g.
"ne ... pas wraps the verb vends."). Treat its list as the work queue, but read
each line: it can miss a fully English line that uses none of its words, and a
formula-only line ("elle + habit- + -ait = elle habitait.") is deliberately not
flagged. Formula lines may stay as they are.

Worst modules: 08_possessifs 92, 16_imparfait 95, 24_subjonctif 96,
20_imperatif 94, 15_pronominaux 90, 09_ir_re 100, 18_y_en 84, 22_conditionnel 82,
23_relatifs 75, 14_passe_compose_etre 69, 19_comparatif 72, 02_etre 58,
21_futur_simple 49, 25_si 39; a few in 03, 06, 11, 13.

## The fix, per example

1. Rewrite **only** `explanation` as one short, plain French sentence (A1–B1
   learners) that says the same thing as `explanationEN`.
2. Leave `explanationEN` as it is, unless it is wrong. Leave every other field
   alone — `answerTokens`, `tokenBank`, `prompt`, `cue`, `spot`, ids.
3. Quote French forms with « » as the existing French lines do:
   `Avec « nous », la terminaison est « -ions » : « nous étions ».`
4. Explain the rule of THIS drill's answer (read `prompt`, `cue`,
   `answerTokens`). Several English lines are just a translation of the
   sentence ("'tu es sorti' = you went out."); replace those with the rule
   the drill teaches (here: « sortir » prend « être » au passé composé).
5. French must be correct: agreement, elision, accents, « » spacing as in the
   file (the files use a normal space inside « »).
6. Don't touch `spot.explanation` / `spot.explanationEN` — they were hand-checked.

## Editing the JSON safely

The topic files have a fixed style (pretty-printed objects, inline scalar
arrays). Write them back with the repo's serializer so the diff is just the
changed lines:

```python
import json, sys
sys.path.insert(0, 'tools/distractors')
from apply import dumps_cb                      # style-preserving serializer
m = json.load(open(path))
# … edit m['elements'][i]['examples'][j]['explanation'] …
open(path, 'w').write(dumps_cb(m) + '\n')
```

`dumps_cb` round-trips every current topic file byte for byte (checked 2026-10-10).

## Checks before handing back

Run from the repo root (`carambole/`). All must pass:

```bash
python3 tools/explanation_lang.py                       # 0 flagged (or each remaining one justified)
python3 tools/lint_topics.py carambole/Resources/Topics # LINT OK
python3 tools/deep_lint.py                              # 0 grammar errors (checks drill sentences)
python3 tools/bank_lint.py                              # 0 unreviewed, 0 also-correct
cd tools && python3 -m pytest swaps content_pipeline -q # all pass
```

`deep_lint.py` checks the drill SENTENCES, not explanations. Also run
Grammalecte over the new French explanations and read every flag:

```python
import json, glob, sys
sys.path[:0] = ['tools/vendor', 'tools']
from deep_lint import build_checker, flags_for
gc, opts = build_checker()
for f in sorted(glob.glob('carambole/Resources/Topics/[0-9]*.json')):
    for el in json.load(open(f))['elements']:
        for ex in el['examples']:
            for fl in flags_for(gc, opts, ex['explanation']):
                if fl['kind'] == 'grammar':
                    print(ex['id'], fl['rule_id'], '|', ex['explanation'])
```

Baseline before the fix: 315 grammar flags, mostly English text read as French.
Grammalecte will flag some quoted forms on purpose (an explanation may quote a
wrong form, e.g. « pas sont »). Those are fine; real grammar slips are not.

Then have a second reader (person or a separate model pass) read a sample —
at least 10 % per module — against `explanationEN` and the drill.

## Done when

- `tools/explanation_lang.py` reports 0, or each remaining hit is a formula /
  justified and listed in the PR description;
- all checks above pass;
- the diff touches only `explanation` lines (spot-check with
  `git diff --stat` and `git diff | grep '^[-+] ' | grep -v explanation`).

Optional follow-up: add `tools/explanation_lang.py` to the PostToolUse hook in
the workspace `.claude/settings.json` next to `lint_topics.py`, so new English
lines can't come back.
