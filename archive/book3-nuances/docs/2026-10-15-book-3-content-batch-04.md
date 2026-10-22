# Book 3 content authoring checkpoint

**Historical drafting checkpoint.** Current production status:
`2026-10-16-book-3-production-handoff.md`.

**Date:** 2026-10-15

**Status:** Planned review-card authoring target reached; production integration pending.

The 20 Test book modules contain 550 cards. Counts range from 24 to 30 per
module, with more practice in later modules. All original card IDs remain
stable. The four pilot formats are word in context, dialogue, microtext, and
rewrite. Cards progress from recognition through short production and transfer
across settings. The final batch added 150 cards to batch 03's 400.

After authoring, agents independently reviewed module ranges they had not
written. They checked French wording, answer support, vocabulary staging,
continuity, and repeated tasks. The concrete findings were corrected, including
the concert timeline, an impossible two-person booking, repair and delivery
roles, unsupported conclusions, and duplicate source/response tasks.

The model check verifies card structure, IDs, format coverage, typed-answer
punctuation, and selected answer variants:

```sh
rtk proxy swiftc -D DEBUG carambole/Debug/Book3PilotModel.swift tools/pilot/Book3PilotTests.swift -o /tmp/book3-content-tests
rtk proxy /tmp/book3-content-tests carambole/Debug/testbook_book3*.json
rtk proxy rm /tmp/book3-content-tests
```

This completes the planned content-drafting volume, not the production Book 3
course. The Test book cards still need the module 18 in-app difficulty checkpoint
and final product decisions for schema, grading, audio, review units, and
progress. The structural check cannot prove every semantic answer is unique or
every French phrasing is natural.

The updated Test book was built and installed in the iPhone 18 Pro simulator.
Module 18 launched with 29 cards; its first card was visibly loaded. The
temporary build and screenshot were removed, and the installed Test book remains
available for the user's content review.
