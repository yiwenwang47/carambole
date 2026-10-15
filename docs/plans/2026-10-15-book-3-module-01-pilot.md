# Book 3, module 01: Test book pilot

**Status:** Review pilot in the simulator Test book. No production Book 3
schema, content size, or progress rule is fixed.

The user approved the source layout after removing white dialogue boxes. The
French sentences and speaker labels now sit directly on the blue block, inset
from its rounded corners. Keep this presentation in later Test book samples.

The ten learner-facing cards live in
`carambole/Debug/testbook_book3.json`, loaded by `Book3PilotView`. They cover
dialogue, microtext, rewrite, and word in context. Every card
shows its French source and one task. There is no separate top cue. Audio is
absent from this content pilot.

The first draft jumped across a concert, library, train, and street. On review,
the user said the vocabulary was too advanced. The revised pilot stays with
Léa, Théo, Inès, and a concert, all familiar from Book 2. It repeats a small
set of familiar words around the three module targets: *une panne*,
*s'interrompre*, and *au moment où*. The grammar target remains *imparfait*
for an action in progress versus *passé composé* for an event.

Harder expressions get English-choice vocabulary cards before reuse in French
reading or rewrite cards. The user asked to focus on material and vocabulary,
with little further time spent on layout.

Interpretation cards use choices. The two typed cards ask for a specified tense
and a complete short sentence. The pilot checks authored answers after
normalizing case, Unicode composition, whitespace, apostrophes, and terminal
punctuation; it keeps accents and tense significant. It does not save grades or
progress. Production typed grading needs a review of valid variants before it
can affect FSRS. The shared `TooEasyGate`, separate book progress, additive
migration rule, and all other constraints remain as stated in the
[curriculum handoff](2026-10-15-book-3-curriculum-handoff.md).

The Test book now has short review drafts for all twenty modules. Module 02
reuses the concert vocabulary and introduces the earlier-than relationship
with *plus-que-parfait*. The user need only review a few checkpoints, not
every module, before production decisions on schema, grading, module size,
audio, and graduation.
