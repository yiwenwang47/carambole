# Book 3 content batch 01

**Date:** 2026-10-15

**Status:** Expanded Test book draft for content review. Production Book 3 is still pending.

The 20 modules now contain 220 cards, up from the checkpoint's 122. Counts range
from 10 to 15 per module and remain editorial samples, not production quotas.
All original card IDs are retained. The four pilot formats remain word in
context, dialogue, microtext, and rewrite.

The content pass adds connected sources, short rewrites, cautious attribution,
and later two-source conclusions. Modules 01–04 use one concert incident with a
consistent timeline. Later modules move through an exhibit, travel decisions,
community activities, repair services, and a garden proposal. Harder vocabulary
is introduced with English meaning choices before later French reuse.

The pilot test now checks all 20 modules, unique IDs, card structure, four-format
coverage, typed-answer punctuation, and selected answers without requiring the
old card counts. Run from the repository root:

```sh
rtk proxy swiftc -D DEBUG carambole/Debug/Book3PilotModel.swift tools/pilot/Book3PilotTests.swift -o /tmp/book3-content-tests
rtk proxy /tmp/book3-content-tests carambole/Debug/testbook_book3*.json
rtk proxy rm /tmp/book3-content-tests
```

This is a broader review draft, not a production course. Before shipping, do a
full French and answer-uniqueness review, establish the production content and
grading model, and check a complete module in the app. The module 18 content
checkpoint remains useful for judging later difficulty. See the curriculum
handoff for the learning outcomes and unresolved production choices.
