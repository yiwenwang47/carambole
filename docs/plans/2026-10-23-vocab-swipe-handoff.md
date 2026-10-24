# Vocab swipe book — handoff (2026-10-23)

Start here for the vocab swipe book (*Mots*). The full spec, with every user
decision, is `docs/plans/2026-10-23-vocab-swipe-plan.md`; read it before
writing code or content.

## 1. State

- Branch `vocab-swipe` (off `main` at the 2026-10-22 state). Not merged, not
  pushed.
- Phases 1–2 are done and approved by the user:
  - Layout mock: `design/vocab/vocab-swipe.src.html`, published at
    https://claude.ai/artifact/HgtXFFSV5CKDbbCS2ayhgi (v7 = approved layout).
  - Review set v1: `tools/vocab/drafts/sample_v1.json` → `design/vocab/review-v1.html`,
    published at https://claude.ai/artifact/2ApAfTxrGYrtPW9FDqU5ko. User: "works".
- 2026-10-23 later: phases 3–5 (bands 1–2) built and committed (`b1bfd13e`
  content, `6b58579e` engine + views). Engine API and view notes are in the
  plan doc. Review set v2: `tools/vocab/drafts/sample_v2.json`, published at
  https://claude.ai/artifact/KqmX6XvU5KydcVenntN4iy, awaiting the user.
- Decided 2026-10-23: pacing as built, review set v2 OK, `pron.` / `interj.`
  OK, swipe lesson = ungraded leçon 0, undo pill at the top, no lock label.
- Pending user calls: shelf mark (placeholder), placement start.

## 2. Next: phase 3 (engine) → 4 (views) → 5 (bulk content)

Phase 3, engine (pure, testable, `_selfTest` like `StudyScheduler`):
1. `Models/Vocab.swift`: `VocabEntry` (id, fr, pos, en, rank, fem?, register?,
   audioKey), `VocabBook` (bands → leçons), decoding from `Resources/Vocab/`.
2. `Core/VocabQueue.swift`: learn queue (armed words first, left swipe
   requeues 5 back until a right swipe), review queue (most overdue first, cap
   from settings, one requeue at the end), peek lock (after a peek only left).
3. Grading: right = `.good`, left = `.again`, up / armed clean = `TooEasyGate.resolve(removed: true)`
   (grades `.easy` + suspends), armed + peek/left = `TooEasyGate.resolve(removed: false)`.
4. `BookCatalog`: `BookKind.vocab`, descriptor `book_fr_mots`, scope
   `book_fr_mots`; `StudySettings` per-book ranges (new 10–20 default 10,
   review cap 200–300 default 250).

Phase 4, views (`Features/Vocab/`), port the mock exactly — don't "improve" it
without asking (memory: match mock):
- `VocabLessonView` (dictionary rows, tap = arm trop facile, play disc,
  Commencer), `VocabSessionView` (✕, big count, 4-card stack just below
  centre, top card swiped, new card enters at the bottom), `VocabSwipeCard`,
  swipe lesson on the first leçon, `.tooEasyUndo` pill.
- Audio through `Speaker` (bundled MP3 by key); keep the `.ambient` / per-clip
  session rules in CLAUDE.md.
- Add this book's trop facile variant (swipe up, no `TooEasyControl`) to the
  CLAUDE.md hard rule.
- Simulator check: record, build a contact sheet, Read the frames
  (`tools/sim/README.md`). Never test on the phone.

Phase 5, content: frequency import → filters (drop articles / personal
pronouns, one card per lemma) → bands of 100, seeded shuffle → glosses
authored in batches with a lint → audio via `fetch_audio.py` → credits →
register in `tools/situations/audio_books.json` → `tools/release_build.sh`.
Expressions: curated list, 2 per leçon. Show the user ~9-entry samples, never
a whole band.

## 3. Files on this branch

| Path | What |
|---|---|
| `docs/plans/2026-10-23-vocab-swipe-plan.md` | Spec + log |
| `design/vocab/vocab-swipe.src.html` | Mock source (`__AUDIO__`, `__EXTRA__`, `/*LESSON*/…/*END*/` placeholders) |
| `design/vocab/build.py` | Embeds clips as data URIs → `vocab-swipe.html` or, with `--draft`, a review page |
| `design/vocab/vocab-swipe.html`, `review-v1.html` | Built pages (published) |
| `tools/vocab/fetch_audio.py` | Lingua Libre first, TTS fill, trim + normalize; resumable; writes a credits report |
| `tools/vocab/drafts/sample_v1.json` | Review set v1 (entry schema reference) |

## 4. Commands

```bash
# audio for a word list (one headword per line) into a scratch dir
python3 tools/vocab/fetch_audio.py --words words.txt --out OUT --report OUT/report.json
# rebuild the mock / a review page from that dir
python3 design/vocab/build.py OUT
python3 design/vocab/build.py OUT --draft tools/vocab/drafts/sample_v1.json --out review-v1.html
# look before publishing (headless Chrome won't go under ~500 px wide)
(echo '<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'; cat design/vocab/review-v1.html) > /tmp/p.html
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --hide-scrollbars \
  --window-size=1000,1050 --virtual-time-budget=1500 --screenshot=/tmp/p.png file:///tmp/p.html
```

The session's MP3s lived in a scratch dir and are gone; re-run
`fetch_audio.py` (about a second per word now) before rebuilding a page.
Lexique 3: `http://www.lexique.org/databases/Lexique383/Lexique383.tsv`
(rank by lemma, `islem == 1`, `freqlemfilms2 + freqlemlivres`).

## 5. Gotchas

- Commons: exact-title lookups (`File:LL-Q150 (fra)-<speaker>-<word>.wav`, 50
  per `titles=` call) are the fast path; category listing and anonymous media
  downloads hit 429 with `retry-after: 600`. Keep the contact in the UA.
  lingualibre.org itself timed out on 2026-10-23.
- Google TTS access tokens last an hour; `fetch_audio.py` refreshes on failure.
- Clip keys fold accents (`réussir` → `voc_reussir`); check collisions when
  bulk-fetching.
- Lexique lists some lemmas under odd forms (`vacance` for vacances) and
  repeats lemmas under other parts of speech (être NOM, grand NOM): filter
  before banding.
- The mock's undo pill and requeue are simplified; the app must use the real
  `TooEasyGate` / `.tooEasyUndo` and FSRS.

## 6. Open, ask when relevant

- Credits screen design (Lingua Libre speakers + Lexique 3).
- Book title / mark on the shelf ("Mots" is a working title; book marks follow
  the studio process, see memory "Book icons = mark process").
- Which leçon a new learner starts at (band 1 is mostly words they know; trop
  facile helps, a placement start may be better).
