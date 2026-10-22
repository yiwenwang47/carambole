# Book 3 content batch 03

**Historical drafting checkpoint.** Current production status:
`2026-10-16-book-3-production-handoff.md`.

**Date:** 2026-10-15

**Status:** Third Test book content pass; production Book 3 remains pending.

The 20 modules now contain 400 review cards, up from 280 after batch 02 and
122 at the original checkpoint. This batch added six cards per module. Module
counts range from 19 to 24. All earlier IDs remain stable.

The additions provide more practice and transfer for each module outcome:
concert sequence and evidence in 01–04, exhibit reference and priorities in
05–08, travel choices and conditions in 09–10, and increasingly qualified
responses, source comparison, causative roles, and synthesis in 11–20. New
sources are short messages, notices, dialogues, and connected paragraphs.

The Test book model check covers 20 modules, unique IDs, card structure,
format coverage, punctuation-free typed answers, and selected answer variants:

```sh
rtk proxy swiftc -D DEBUG carambole/Debug/Book3PilotModel.swift tools/pilot/Book3PilotTests.swift -o /tmp/book3-content-tests
rtk proxy /tmp/book3-content-tests carambole/Debug/testbook_book3*.json
rtk proxy rm /tmp/book3-content-tests
```

The 400 cards are an editorial review draft, not a production quota or a
finished course. A full French and answer-uniqueness pass, in-app difficulty
checkpoint, and production schema/grading decisions remain. Module 18 is the
planned later-stage content checkpoint.
