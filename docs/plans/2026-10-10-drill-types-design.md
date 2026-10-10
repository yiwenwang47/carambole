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
