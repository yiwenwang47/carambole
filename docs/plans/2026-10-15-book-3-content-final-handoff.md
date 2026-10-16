# Book 3 content handoff

**Date:** 2026-10-15

**Integration:** merged into `main` on 2026-10-16; the `book3-pilot` branch can be removed.

**State:** 550 review cards across all 20 DEBUG Test book modules. Content
authoring volume is complete. Production Book 3 remains to be designed and
integrated.

## Start here

Read `CLAUDE.md` and `2026-10-15-book-3-curriculum-handoff.md` for the course
purpose and module outcomes. The cards live in
`carambole/Debug/testbook_book3.json` and
`carambole/Debug/testbook_book3_02.json` through `_20.json`. Review content in
the simulator Test book; the user prefers short app checkpoints over reading
Markdown or reviewing every module. Module 10 was approved at the earlier
checkpoint. Module 18 is the planned late-stage difficulty checkpoint.

## What the draft contains

- Module counts, 01–20: 26, 24, 24, 24, 25, 24, 28, 28, 29, 28, 28, 28, 29,
  30, 30, 29, 29, 29, 29, 29. These are review-card counts, not production
  quotas.
- Four formats in every module: word in context, dialogue, microtext, and
  rewrite. The progression moves from event sequence and reference through
  comparison, conditions, register, causative roles, and supported synthesis.
- Every drill has a visible French source and one compact task. Harder words
  start with an English meaning choice, then recur in French. Difficulty grows
  by adding one demand at a time and reusing earlier language.
- The first 122 cards retain their IDs. All 550 IDs are unique. The four
  authoring checkpoints are `2026-10-15-book-3-content-batch-01.md` through
  `2026-10-15-book-3-content-batch-04.md`.

After drafting, independent reviewers checked module ranges they had not
written. Corrections addressed concert chronology, booking capacity, repair
and delivery roles, unsupported conclusions, and repeated source/answer tasks.
This was a targeted editorial pass; a final native-level French and semantic
answer review remains useful before production.

## Verification and app state

From the repository root:

```sh
rtk proxy swiftc -D DEBUG carambole/Debug/Book3PilotModel.swift tools/pilot/Book3PilotTests.swift -o /tmp/book3-content-tests
rtk proxy /tmp/book3-content-tests carambole/Debug/testbook_book3*.json
rtk proxy rm /tmp/book3-content-tests
```

The model test checks all modules, card structure, IDs, format coverage,
punctuation-free typed answers, and selected answer variants. The last run
reported: `Book 3 content: 20 modules, 550 cards, schema and answer checks
passed`. The Test book was also built, installed, and launched in the iPhone
18 Pro simulator. Module 18 showed card 1 of 29. The installed app remains
available; its temporary build files and screenshot were removed.

These checks do not prove that every accepted answer is unambiguous or every
French line is natural.

## Next decisions and work

1. Get a short in-app content read of module 18 to judge the later difficulty
   ladder. Bring forward material issues only; a card-by-card user review is
   unnecessary.
2. Define the production card schema, answer variants and grading, source and
   answer length limits, vocabulary support, audio coverage, review unit,
   module/session size, and separate Book 3 progress. Reuse shared `TooEasy`
   behavior and follow the additive database migration rule in `CLAUDE.md`.
3. Convert and validate one complete production module before integrating the
   remaining modules. Run editorial and semantic answer review on the final
   production text. The Test book files are authoring material, not a shipped
   course.

This handoff covers Book 3 only. The Book 2 audio and tooling changes were
merged separately in the same integration.
