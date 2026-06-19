# Content pipeline — French conjugation exercises at volume

Generates grammar-correct drill exercises for the app, by **decoupling grammar
from prose**:

```
verbecc (deterministic conjugation)         LLM sub-agents (natural language)
        │                                            │
   seeds.py  ── prepare.py ──► batch_NN.jsonl ──► [agent + agent_template.md] ──► raw/batch_NN.jsonl
   (verb×tense×person:                                                                │
    correct_form + real distractors)                                          finalize.py
        │                                                                             │
   the answer + options are LOCKED to the seed ──────► contract.py rejects any        ▼
   (LLM can only write sentence/translation/hint)      altered form        out/staging/NN_*.json + manifest
```

A hallucinated conjugation **cannot ship**: `contract.check_against_seed` requires
`answerTokens == [seed.correct_form]` and `set(tokenBank) == seed forms`, so any
exercise whose grammar drifts from the deterministic seed is dropped.

## Modules
- `conjugator.py` — verbecc wrapper → bare forms per (mood, tense). `SUPPORTED_TENSES`.
- `verbs.py` — `COMMON_VERBS` (112, frequency-ordered).
- `seeds.py` — `Seed`, `make_seeds`, `all_seeds`. 112×5×6 = **3360 grammar-correct seeds**.
- `prepare.py` — `seed_record` (+topicID/id), `write_batches`.
- `agent_template.md` — the generation prompt (LLM writes prose only).
- `validate.py` — `validate_exercise` (app `Exercise` schema + drill invariants).
- `contract.py` — `check_against_seed` (seed-fidelity, incl. `je`→`j'` elision).
- `topic_meta.py` — per-tense topic id/title/ruleNote.
- `assemble.py` — `build_topic`, `write_topics`.
- `finalize.py` — `accept` (validate+contract, drop bad), `group_topics`, `finalize_files`.

## Run it
```bash
cd tools
python3 -m pytest content_pipeline -q          # 57 tests

# 1. prepare batches (deterministic)
python3 content_pipeline/prepare_all.py --batch-size 100      # -> out/batches/batch_NN.jsonl

# 2. generate (Claude sub-agents): dispatch one agent per batch, each following
#    content_pipeline/agent_template.md, reading out/batches/batch_NN.jsonl and
#    writing out/raw/batch_NN.jsonl. 5 agents x 100 seeds = 500 exercises/session.

# 3. finalize (deterministic): validate + contract + group
python3 content_pipeline/finalize_all.py        # out/raw/ -> out/staging/NN_*.json

# 4. curate, then copy chosen topics into carambole/Resources/Topics/ + manifest.
```

## Proof run (committed sample in `out/staging/`)
6 verbs × {présent, imparfait} = 72 seeds → 3 agents × 24 → **70 accepted / 2
rejected** (bad subject pronoun, auto-dropped) → 2 topics, all schema-valid.

## Notes
- First verbecc call trains+caches an ML fallback model (~3s once).
- `out/batches/` and `out/raw/` are intermediate (gitignored); `out/staging/` +
  `out/sample_seeds.jsonl` are kept as evidence.
- Curation (final human/grammar review + chain ordering) is deliberately a
  separate step — generated topics land in `out/staging/`, never auto-shipped.
