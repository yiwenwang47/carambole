# Book 3 content batch 02

**Historical drafting checkpoint.** Current production status:
`2026-10-16-book-3-production-handoff.md`.

**Date:** 2026-10-15

**Status:** Second Test book content pass; production Book 3 remains pending.

The 20 modules now contain 280 review cards, up from 220 after batch 01 and
122 at the original checkpoint. This batch adds three cards per module. Counts
range from 13 to 18. The new cards prioritize connected sources, inference,
short production, and conclusions that respect what the visible evidence does
and does not establish. Existing card IDs remain stable.

The concert sequence in modules 01–04 was corrected: Léa entered before the
outage and spoke with Théo when the music stopped. Théo had not seen her enter
and guessed she had just arrived. Inès's dated message establishes that Léa
was in the hall earlier. Later modules continue the exhibit, travel, personal,
bridge, repair, and garden settings from batch 01.

The Test book model check covers all modules, structure, unique IDs, format
coverage, punctuation-free typed answers, and selected answer variants:

```sh
rtk proxy swiftc -D DEBUG carambole/Debug/Book3PilotModel.swift tools/pilot/Book3PilotTests.swift -o /tmp/book3-content-tests
rtk proxy /tmp/book3-content-tests carambole/Debug/testbook_book3*.json
rtk proxy rm /tmp/book3-content-tests
```

This remains a review draft. The structural check does not replace a complete
French, answer-uniqueness, and difficulty review. The next content checkpoint
is module 18 in the Test book app; its result can guide production module size
and final text length. Production schema, grading, audio, and progress remain
outside this content batch.
