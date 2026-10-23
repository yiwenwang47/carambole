# Vocab swipe book — plan (2026-10-23)

Branch `vocab-swipe`. Scoped with the user on 2026-10-23. Every decision below
is the user's unless marked "Claude default"; the user accepted the Claude
defaults shown with review set v1 ("works"). Start a new session at
`docs/plans/2026-10-23-vocab-swipe-handoff.md`.

## Goal

Throughput vocabulary: single words and short expressions only. Learn 10–20
new words a day (the learner can take more), review 200–300. No typing, no
choices: swipe only. FSRS scheduling, same as the other books.

## Shape

- New book on the shelf, working title *Mots* (`BookKind.vocab`, element IDs
  `voc_…`, settings scope `book_fr_mots`). Own progress, settings, due queue
  and history. One element = one word or expression. No schema migration:
  grades go through `ElementGrader.grade` into `review_status` / `review_log`.
- Direction: French → English recognition only.

## Content

- Newly authored lists. **Grouped by frequency, never by theme** (user: theme
  grouping is "a terrible idea"). Rank = Lexique 3 lemma frequency
  (`freqlemfilms2 + freqlemlivres`; CC BY-SA, credit it).
- Frequency bands of 100 words; words are **randomized within a band** with a
  fixed seed, so leçon membership is stable across installs. Leçon = 10
  entries; module = one band (band 7 = ranks 601–700 = leçons 61–70).
- Expressions: 2 per 10-entry leçon, ordered by how common they are (Claude
  default). Curated list; no corpus rank.
- Claude defaults: drop articles and clitic/personal pronouns (le, je, se…);
  one card per lemma; a second part of speech (le pouvoir vs pouvoir) gets its
  own card only when the meaning really differs. Familiar / vulgar words stay,
  labelled `fam.` / `vulg.` (film-subtitle frequency ranks slang high).
- Entry fields (`tools/vocab/drafts/sample_v1.json`): `id`, `fr` (headword with
  article), `pos` (n.m., n.f., v., adj., adv., prép., conj., loc.), `en`,
  `rank`, optional `fem` (irregular feminine: doux → douce), optional
  `register`.
- English gloss style: short, main senses split by `;`, a usage note only when
  it helps (« à mon avis = in my opinion »).
- Display: article in parentheses after the word, dictionary style:
  « confiance (la) », « odeur (l') », « tromper (se) »; adjectives
  « doux, douce »; register after the part of speech (`n.m. · fam.`).
- Content review in small sets (~9 entries) before bulk authoring. v1 approved.

## Audio

- Every entry has audio. Source: **Lingua Libre** recordings on Wikimedia
  Commons (CC BY-SA → credits screen in Settings with speaker + file title).
  Missing entries: **Google TTS** (`fr-FR-Neural2-F`, Book 1/2 pipeline).
- Lingua Libre recordings are bare words; keep them (user). The article is not
  voiced; adjectives voice the masculine only (Claude default).
- Every clip is edge-trimmed and run through
  `tools/situations/normalize_audio.py`; register the book in
  `tools/situations/audio_books.json` so `tools/release_build.sh` gates it.
- Coverage: 992 of the top 1,000 Lexique lemmas have a recording from the 16
  most prolific French speakers; review set v1 was 9/9 (expressions too).
- The Commons User-Agent carries the user's contact email (user approved);
  without it, upload.wikimedia.org blocks for 10 minutes after a few files.

## Leçon page

- Classical dictionary layout in the app's style, **not** toast slice; airy
  rows (user: earlier version "too crowded"), the list scrolls, Commencer
  stays at the bottom. No swiping here. No audio-source labels.
- Row: headword (+ article in parentheses), small part-of-speech label,
  English gloss on its own line, play disc. Tap a row to mark it trop facile
  (pale lime row).

## Drill

Mock: `design/vocab/vocab-swipe.src.html` (approved layout).

- Top: ✕ only (no header bar, no progress line), then the big remaining count
  with « à réviser » / « à apprendre » and the session stats.
- **Four cards at most**, all styled the same (no highlighted card), on the
  pale tint tray, 18 pt apart, sitting just below the screen's centre.
- The **top card** is the one swiped; the others slide up and a new card
  enters at the bottom after every swipe.
- Every card has a **play disc** (Book 2 style: pale `quietFill` disc, ink
  triangle, no outline). Playing never counts as a peek.

| Gesture | Result |
|---|---|
| Drag left partway | English slides in on the pale underlay. Release → snaps back. This is a **peek**. |
| Swipe left past threshold | `.again` ("I still need the meaning"). Learn: back 5 cards later (dashed outline) until swiped right. Review: back once at the end (Claude default). |
| Swipe right (no peek only) | `.good` ("I know it"). |
| Swipe up (no peek only) | **Trop facile** → grade `.easy` + suspend + undo pill. |
| After a peek | Right and up are **locked** (rubber-band back); only left. |

Grading is binary otherwise: `.good` or `.again`.

- **No Trop facile button** in the drill: swipe up is trop facile (user).
- **Swipe lesson** on the first leçon only: the top card moves by itself
  through peek / far left / right / up, with captions in the count area;
  touching a card ends it.

## Trop facile (hard rule, shared logic)

- Swipe up = trop facile resolved on the spot (clean by definition).
- Marking a row on the Leçon page **arms** that word; armed words come first
  in the session, tagged « Trop facile ? ». A clean right swipe or swipe up →
  suspend + undo pill; a peek / left swipe → clean records, then it is a
  normal word.
- Implemented through `TooEasyGate.resolve` and `.tooEasyUndo`; never forked.
  When building, add this book's variant (swipe up instead of
  `TooEasyControl`) to the CLAUDE.md hard rule.

## Pacing

- New: 10–20 per day (setting, default 10), then a "One more leçon" button.
- Reviews: all due, most overdue first, capped at a setting in 200–300
  (default 250), one continuous stack the learner can leave any time; overflow
  rolls to the next day.
- `StudySettings` needs per-book ranges (today's 3–20 / 10-20-50 are Book 1's).
- Expectation: steady-state reviews ≈ 7–10 × new/day, so 15 new/day settles
  near 100–150 reviews; 300 is a cap, not a quota.

## Build pieces

- `Models/Vocab.swift`, `Resources/Vocab/*.json`, `BookCatalog` entry, routing
  in Library / Book / Today.
- `Core/VocabQueue.swift`: pure requeue spacing, review cap, peek-lock state,
  with `_selfTest`.
- `Features/Vocab/`: `VocabLessonView`, `VocabSwipeCard`, `VocabSessionView`
  (+ swipe lesson).
- `tools/vocab/`: frequency import + filters, band shuffle, lint (duplicate
  lemma, gloss present, noun article, no English in FR), `fetch_audio.py`
  (exists), audio index + credits.

## Phases

1. ✅ HTML mock (`design/vocab/vocab-swipe.src.html`, artifact
   https://claude.ai/artifact/HgtXFFSV5CKDbbCS2ayhgi) + Lingua Libre coverage.
2. ✅ Review set v1 (`tools/vocab/drafts/sample_v1.json`, artifact
   https://claude.ai/artifact/2ApAfTxrGYrtPW9FDqU5ko): approved.
3. Engine + self-tests.
4. Views, simulator check (frames).
5. Bulk lists + audio, release gate.

## Log

- 2026-10-23: plan saved; mock v1–v7 iterated with the user (layout above).
- 2026-10-23: Coverage probe: misses in the top 1,000 were sinon, lui-même,
  ok, manière, sauf, moi-même, épouser, vacance(s).
- 2026-10-23: review set v1 (9 entries, one per entry type), audio 9/9
  Lingua Libre; user: "works".
