# Drill types: spot-the-error + second try on build (2026-10-10)

## Why

User feedback: building a whole sentence takes too long and punishes one slip
as hard as a blank answer; multiple choice is too easy. From a second-language
acquisition view, a drill should make the learner retrieve **only the grammar
point**, inside a sentence that forces meaning ("focus on form"). Whole-sentence
build tests order, agreement, spelling and memory at once, so a miss does not
say what failed. MC can be solved by elimination.

Ladder we are moving toward, per element (easy → hard): interpretation →
listen/discriminate → **spot the error** → partial build / transformation →
full build (rare). This change ships the first two pieces that need no new
authoring of sentences.

## 1. Spot the error (`InputMode.spotError`)

A full French sentence with exactly ONE wrong word. Learner taps the wrong word,
then picks its fix from 3 options.

- **Data.** `Exercise.spot: SpotError?` = `{ tokens, wrongIndex, options }`.
  `tokens` is the corrupted sentence as shown; `answerTokens` is the corrected
  sentence (so "Réponse : …", review mode and TTS all show correct French);
  `options` holds the correct token + 2 wrong fixes.
- **Flow.** Tap a word. Right word → it gets a dashed frame and the options
  appear. Wrong word → it shakes and dims (one miss). After 2 misses the error
  is shown for them. Options are hidden until the error is found, because the
  options themselves reveal the slot.
- **Grade.** Fix right + no miss → `.good`; fix right after a miss → `.hard`;
  fix wrong → `.again`.
- **No Écouter before the answer** — the audio would read the corrected sentence.
- **Correctness gate (authoring, not runtime).** A corrupted sentence must be
  ungrammatical (not just a different meaning: `Je leur parle` for "I speak to
  him" is valid French → rejected), have exactly one error, have a unique fix,
  and target the drill's rule. Items are derived offline from the existing
  grammar-trap banks, checked by Grammalecte + an independent judge + a human
  read. See the authoring probe results (session 2026-10-10).

## 2. Second try on build (`buildFromTokens`)

First wrong Vérifier no longer ends the drill:

- The longest correct leading run of tiles stays on the line, locked; the rest
  flash dashed, then fly home. Line under the baseline: "Encore un essai".
- Second Vérifier: right → weld, `.hard`; wrong → today's wrong flow (dashed,
  "Réponse : …", Suivant), `.again`.
- First-try right stays `.good`. "Trop facile" only removes on a first-try right.
- MC keeps one shot (a retry on 3 options is a coin flip). Typing unchanged for now.

`DrillView.onResult` now passes an `FSRS.Rating` (`.hard` was unused before).

## Test book

DEBUG only. A build with bundle id `wen.carambole.testbook` (own database,
named "Test book") opens a one-page test book: one session of spot-the-error
items, one session of long build drills to try the second-try flow.

## Authoring probe results (2026-10-10, two subagents)

**Spot the error from existing banks.** 6,738 candidate swaps → 328 pass every
automatic gate (~13/module; 07/13/24/01/08 high, 16/18/21/22 near zero).
Grammalecte: 62/62 flagged were truly wrong (high precision) but ~70% recall,
so only flagged items are kept. Biggest reject class (~75%): two places to fix
("Je lui parlent" → fix the verb OR the subject). Making the subject pronoun
untappable would recover ~1,256 subject–verb items. Pipeline: candidates →
surface filter (elision/contraction) → Grammalecte flag whose suggestion is the
original word → one-fix probe → LLM judge → ~10 % human check.

**Baseline of past LLM authoring.** 80 random drills: no conjugation /
agreement / translation errors; 2 had a distractor that is also correct
(`amis`/`amies`, `là`/`ici`). Add a lint: fill each blank with each distractor,
send Grammalecte-clean ones to a judge.

**New types.** Transformation: code computes answer + distractors, LLM writes
only noun phrases/prose (≤0.5 % error; ~35 % of distractors need a judge —
word order and valency are invisible to Grammalecte). Interpretation: code
flips the one cue to make a "twin" that must differ visibly, be grammatical and
flip the answer; human reviews every item. Watch: l' hides gender, lui/leur
hide gender, fait + infinitive never agrees, si = "whether"/habit, vu/vue sound
identical (agreement items are text-only). Partial build + morpheme build:
fully programmatic.

## Book 1 rollout (2026-10-10, session 2)

**1. Bank lint** (`tools/bank_lint.py`, on main as `a1fb133`). Every distractor
goes into its slot (`tools/swaps/`); each swap Grammalecte leaves clean needs a
reviewed verdict in `tools/bank_lint_reviewed.json`. 3,327 swaps judged by 8 LLM
judges + hand review: 100 second answers. 77 were prompts that never said who
speaks — fixed with a **cue** («Un homme parle», «À un ami (tu)», «Un groupe
mixte», «Poli (vous)»), keeping the contrast the drill teaches in the bank; 20
were true alternatives (là/ici, dans la ville, la médecin…) — distractor
replaced. Run it after any bank or prompt edit; `--export` feeds judges,
`tools/bank_fix.py` applies fixes + verdicts, `--prune` drops stale entries.

**2. Spot pipeline** (`tools/spot/candidates.py` → judges → `tools/spot/apply.py`).
715 candidates (one per drill) → 437 accepted and written as `spot` on the
example. Judges rejected mostly off-topic errors (an article slip in a verb
drill). Every one of the 264 judge-written explanations and all 175 kept ones
were read by hand (2 errors fixed, 2 items rejected, 47 English lines added).
Tier 2 items lock the subject pronoun (`spot.locked`). `lint_topics` checks the
fix restores the drill's own sentence.

**3. Ladder** (`Core/DrillLadder.swift`). Retry after a miss in this session →
spot; stability < 1 day → spot; < 3 days → spot 1 in 3; else the authored drill.
The spot form keeps the drill's cue and bracketed prompt notes ("(une femme
parle)"). Harness: `CB_LADDER_SPOT=1` serves the spot form.

**Open:** many drills' French `explanation` field is written in English (futur
simple, possessifs, subjonctif, si — judges found ~150). Worth a pass.
