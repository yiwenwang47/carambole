# Book 3 content checkpoint handoff

**Date:** 2026-10-15

**Branch:** `book3-pilot`

**State:** The user tried module 10 in the simulator and said, “works.” The user
asked to checkpoint this work. This file records the Test book draft. Production
Book 3 content, grading, audio, and progress do not exist yet.

## Start here

Read `CLAUDE.md` and `2026-10-15-book-3-curriculum-handoff.md`. Use the Test
book app for content review. The user does not want to read Markdown as the
review interface. The user does not need to review every module.

## Content at this checkpoint

- The Test book has 20 modules and 122 review cards: 10 in module 01, four in
  module 02, and six in each module from 03 through 20.
- The files are `carambole/Debug/testbook_book3.json` and
  `carambole/Debug/testbook_book3_02.json` through `_20.json`.
- Each later module uses word, dialogue, microtext, and rewrite cards. The
  sequence moves from familiar event reports to two-source synthesis.
- Harder words first appear in a context with English meaning choices. Later
  cards reuse the French expression. Familiar words do not get routine glosses.
- French source text stays visible on the blue block. Dialogue text has no
  white background boxes.
- These card counts are review samples. Do not use them as production quotas.

## Code and checks

- `carambole/Debug/Book3PilotView.swift` loads modules 01–20 by resource name.
- `carambole/Debug/DrillDemo.swift` lists available modules and accepts direct
  launch flags such as `CB_TB_OPEN=book3_10` and `CB_BOOK3_CARD=1`.
- `tools/pilot/Book3PilotTests.swift` checks module counts, IDs, card formats,
  model validation, and selected answer variants.
- Run the content check from the repository root:

  ```bash
  rtk proxy swiftc -D DEBUG carambole/Debug/Book3PilotModel.swift tools/pilot/Book3PilotTests.swift -o /tmp/book3-content-tests
  rtk proxy /tmp/book3-content-tests carambole/Debug/testbook_book3*.json
  rtk proxy rm /tmp/book3-content-tests
  ```

- Build the separate Test book with `CB_BUNDLE=wen.carambole.testbook` and a
  task-specific `CB_DD` path. See `tools/sim/README.md` for the simulator flow.
  Remove that derived-data path after installation. Keep the installed app.

## User decisions

- Focus on the material. Spend little time on layout.
- Increase difficulty a little at a time. Teach harder vocabulary explicitly.
- Use English meaning choices first for harder words, then French reuse.
- Keep the French source directly on the blue block.
- Use short app checkpoints. Module 10 works for the user.

## Next work

1. Review the 122 cards for French grammar, event continuity, answer uniqueness,
   and vocabulary reuse. The model checks do not judge every sentence.
2. Define the production schema, grading, answer variants, review unit, audio,
   and module size. Keep progress separate from Books 1 and 2.
3. Build one complete production module from this draft. Check it in the app
   before the other modules. Use module 18 if a later difficulty check helps.

Do not assume that the Test book draft already provides a production course.
