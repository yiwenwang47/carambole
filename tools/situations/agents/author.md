# Author spec: one draft half (4 moves) of a Book 2 module

You write ONE half of one module. Your task message gives:
- the module number and slug;
- which half (moves 1–4 or 5–8);
- your two output files, `tools/situations/drafts/NN_<slug>_<half>.json` (`{"elements": [...]}`) and `NN_<slug>_<half>_words.json` (`{"words": [...]}`).

**Repo:** `/Users/yiwenwang/Documents/CMU/research/personal/carambole/carambole`

Write only your two files. Other authors work on the other halves at the same time. Never run `assemble.py`, never commit, and never edit `carambole/Resources/`.

## Read first (all required)

1. The batch plan and your module's matrix in `docs/plans/`. Follow the matrix rows: situation, channel, cast, drill types, new words, reuse.
   - The French in the matrix is a sketch; write the final, natural French yourself.
   - Deviate from a row only to fix a real problem, and list every deviation in your report.
2. `docs/plans/2026-10-11-book-2-content-handoff.md` §3 (rules), §4 (cast), §6 (JSON shape), §8 (item checklist).
3. `docs/plans/2026-10-11-book-2-cafe-handoff.md` §3: the error classes the judges find.
4. `tools/situations/agents/judge.md`: what the judges will check. Write so they find nothing.
5. `tools/situations/README.md` and `carambole/Resources/Situations/06_au_cafe.json`: the exact shape and the quality bar.
6. `carambole/Resources/Situations/words.json`: the existing glosses.

## Rules recap

- **Item order.** Each element is `sit_NN_<move>` with a `title`, a `note` (an English learner note) and 15 items in this order: `d01 d02 s01 d03 d04 s02 d05 d06 s03 d07 d08 s04 d09 d10 s05`.
- **Standalones.** Each move has one Construire, one Choisir le ton, one Corriger, one Transformer and one Mot en retour. Each standalone's `place` names the setting its cue describes, plus « · phrase seule ».
- **Cast.** Use the canonical names. Robin is a woman, so her lines are feminine only. Karim's, M. Ferrand's and Mme Dumas's *tu* / *vous* follow the judge spec.
- **Line limits.** Dialogue lines have at most 10 words. A dialogue has at most 3 lines, including the built reply. Standalone lines have 8–14 words.
- **Drills.** 1–2 per dialogue, no repeated type, no Répondre + Choisir together.
- **Choices.** Vary the slot of the correct answer, and keep `why` lined up with `choices`.
- **Reply drills.** Every valid buildable order is in `accepted`. The model equals `accepted[0]`. No reply may still count as right with its last tile dropped.
- **Spoken forms.** Accept the standard and the spoken form where natural; the model is standard. A spoken entry must be listed in `SPOKEN` in `lint.py`, so ask the coordinator to add any new one.
- **Typography.** French spaces before `?` `!` `:`, straight apostrophes, « » in English notes.
- **Words file.** One entry per tappable token or set phrase, including distractors and bank decoys: `fr`, `en`, `spoken`, `audio` (`sitw_<slug>`), `firstSeen`.
  - Copy existing entries from `words.json` byte for byte.
  - For a new base word, use the most general accurate gloss. It must be in *Fondations*; if it isn't, teach it or avoid it.
  - A gloss shows in every context, so make it wide ("do / make", not "make").

## Validate

1. Draft check:
   ```sh
   rtk python3 tools/situations/lint.py --draft --no-audio --module <draft> --words <words>
   ```
2. Full check: wrap your elements with the module header from `modules.json` in a scratch copy, merge `words.json` with your words file, and run `lint.py --no-audio --module` on it.
3. Run Grammalecte on your rendered lines.

## Report

- Lint results
- Item counts
- New words and their `firstSeen`
- Deviations from the matrix
- Base words added
- Doubts for the judges
