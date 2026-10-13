# tools/distractors

Bulk-add harder grammar-trap distractors to `buildFromTokens` token banks in the
course JSON, without disturbing anything else in the file.

Why split into two scripts: the **linguistic** task (pick good wrong-form
distractors) is done by an LLM author; the **mechanical** task (parse 50 KB of
JSON, resize banks, validate, write back with a clean diff) is deterministic and
stays in code so a hallucination can't corrupt structure.

## Sizing

Target bank size = `max(len+2, round(1.6 · len))` where `len = len(answerTokens)`.
So bank ≈ 1.6× the answer length, with at least 2 distractors. `need` (distractors
to author) = target − len.

## Workflow

```bash
# 1. Extract a per-drill spec for one module (buildFromTokens only).
python3 tools/distractors/extract.py carambole/Resources/Topics/02_etre.json > /tmp/spec.json
#    Each entry: { id, prompt, translation, answer, answerTokens, existingDistractors, need }

# 2. An author (LLM agent) reads the spec and writes a map { exampleId: [distractor, ...] },
#    exactly `need` distractors per id — real French WRONG forms targeting that
#    sentence's grammar, distinct, never equal to an answer token.

# 3. Merge back. Rebuilds tokenBank = answerTokens + distractors, validates, and
#    rewrites the file touching ONLY the tokenBank lines.
python3 tools/distractors/apply.py carambole/Resources/Topics/02_etre.json /tmp/distractors.json
```

`apply.py` rejects (and leaves the module untouched) if any drill is missing,
a count is wrong, distractors aren't distinct, a distractor equals an answer token,
or the multiset-subset invariant would break. After applying, run
`python3 tools/lint_topics.py` and a build to confirm.

## Notes

- Bank **order** in JSON doesn't matter: `Exercise.displayBank` shuffles it
  deterministically at render time. These scripts only control bank **contents**.
- The merge uses a style-preserving serializer (scalar arrays inline, object arrays
  pretty-printed) so the git diff is just the changed `tokenBank` lines.
- Used 2026-06-19 to re-author all 1440 construis banks (avg extra distractors
  1.24 → 2.62). See `docs/archive/plans/2026-06-19-token-shuffle-distractors-design.md`.
