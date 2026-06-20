# Authoring task — add English `explanationEN` to one grammar module

Working dir: `/Users/yiwenwang/Documents/CMU/research/personal/carambole/carambole`
You will be told ONE module file, e.g. `01_articles.json`. Call it `<FILE>`.

The drill app shows the French `explanation` after a learner answers. We are adding a
parallel English `explanationEN` so the post-answer explanation is bilingual. Your job:
author one English explanation per example in `<FILE>`.

## Steps

1. Extract the specs:
   ```
   python3 tools/explanation_en/extract.py carambole/Resources/Topics/<FILE>
   ```
   → a JSON array `[{id, prompt, answer, explanationFR, hint, translation}, ...]`.
   If it prints `[]`, the module is already done — report "already authored" and STOP.

2. For each spec author `explanationEN` = a faithful English rendering of `explanationFR`:
   - Same meaning and depth as `explanationFR` (the full French explanation) — NOT the
     terse `hint`. It explains WHY the answer is what it is.
   - Natural, learner-friendly English. Keep French grammar terms with no clean English
     equivalent (passé composé, imparfait, subjonctif, conditionnel, etc.); translate the
     rest (masculine/feminine, agreement, plural, before/after the noun, etc.).
   - French words/forms quoted in the French with « » → quote them in English with straight
     ASCII double quotes, keeping the French word itself in French. Example:
       FR: `« chien » est masculin, donc on utilise « un ».`
       EN: `"chien" is masculine, so it takes "un".`
   - One or two sentences, ending with a period. Don't reference the English translation line.
   - Non-empty for every id.

3. Write the map `{id: explanationEN, ...}` as UTF-8 JSON (real accented chars, not \uXXXX)
   to `/tmp/expEN_<FILE>.json` with the Write tool.

4. Merge:
   ```
   python3 tools/explanation_en/apply.py carambole/Resources/Topics/<FILE> /tmp/expEN_<FILE>.json
   ```
   Must print `APPLIED — <FILE>`. If it prints `APPLY FAILED`, add the missing ids and re-run.

5. Confirm done — this must now print `[]`:
   ```
   python3 tools/explanation_en/extract.py carambole/Resources/Topics/<FILE>
   ```

## Hard rules
- Do NOT change the French `explanation`, `answerTokens`, `prompt`, `tokenBank`, `hint`,
  `translation`, or any structure. Only `explanationEN` is added (apply.py enforces this).
- Do NOT edit any other file.

## Report back
Module filename · number of explanations authored · the final extract result (`[]` expected).
