# Fixer spec: Book 2 content (one fixer per draft half)

You apply independent judge findings to ONE draft half of Book 2 (*En situation*).

**Repo:** `/Users/yiwenwang/Documents/CMU/research/personal/carambole/carambole` (main checkout).

**Files you may edit:** your half's elements draft `tools/situations/drafts/NN_<slug>_<half>.json` and its `_words.json`, both named in your task. Edit nothing else. Do not touch:
- any other draft
- `carambole/Resources/`
- the tools code
- `assemble.py` (don't run it either)

Don't commit. Other fixers work on the other halves at the same time.

## Read first

- The judge spec: `tools/situations/agents/judge.md` (the rules)
- Your judge reports (named in your task)
- `tools/situations/README.md`
- `docs/plans/2026-10-11-book-2-cafe-handoff.md` §3

## What to apply

- **Severity.** Apply every MUST and SHOULD. Apply a NIT when it is clearly right and cheap; skip it otherwise.
- **Disagreeing.** Reject a finding only if applying it would create a new error, and say why in your report.
- **Re-check every fix** against all the judge-spec checks. A fix must not introduce answer echo, cue leaks, untaught words or hidden valid replies. It must not break the line limits: 10 words per dialogue line, 8–14 words per standalone line, 3 lines per dialogue including the built reply.
- **Place labels.** A standalone label names the setting the cue describes, plus « · phrase seule ». Examples:
  - « Sur le palier · phrase seule »
  - « WhatsApp · Mme Dumas · phrase seule »
  - « Appel · Inès · phrase seule »
  - « Texto · Léa · phrase seule »
  - « Les copains · groupe · phrase seule », only for real group-chat lines

  Fix every standalone in your half, not just the flagged ones.
- **Reply drills.** Check EVERY reply drill in your half, not only the flagged ones.
  - Enumerate the sequences buildable from the bank that are valid French and fit the prompt.
  - Each must be in `accepted`. If one shouldn't count, change the bank or the prompt so it can't be built.
  - The model equals `accepted[0]`.
  - No accepted reply may still count as right with its last tile dropped. The Swift model test checks this.
- **Robin's gender.** Robin is a woman, so her lines are feminine only. Use masculine forms only as decoys. Add "You're a woman." to the cue when the answer hinges on it.
- **Glosses.** Each word has one gloss for the whole book. Before you propose a change, read the current entry in `carambole/Resources/Situations/words.json`. Many glosses are already widened (*fais, va, café, là, bien, combien, encore, voilà…*). Do NOT edit an existing entry: list proposed changes in your report for the coordinator.
- **New word entries.** You MAY add a word that isn't in any words file yet to your own `_words.json`, with `firstSeen: null`, if it is a base inflection. If the key already exists in `words.json`, copy that entry byte for byte instead.
- **Corriger.** The error word may sit inside a set phrase, because the app splits it out. The single word itself still needs a gloss entry.
- **Moving a taught word.** You may move a taught word's `firstSeen` within your half. Keep the newWords, printed-line, recurrence and Mot rules.

## Validate

1. Both checks must be clean for your half:
   ```sh
   rtk python3 tools/situations/lint.py --draft --no-audio --module <your elements draft> --words <your words draft>
   ```
2. Full check: in your scratchpad, at `<scratchpad>/fix_<NN>_<half>/`, build a scratch copy that wraps your elements with the module header from `tools/situations/modules.json`. Run `lint.py --no-audio --module` on it, with `carambole/Resources/Situations/words.json` merged with your words file (your entries win). Errors that only come from the other half's moves being missing are expected.
3. If practical, run Grammalecte on your rendered lines (see `tools/situations/deep_lint.py`).

## Report

- Findings applied and skipped, with the reason for each skip
- Extra fixes you found yourself
- Gloss changes for the coordinator
- New word entries added
- Lint results
