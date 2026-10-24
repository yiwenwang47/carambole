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
| After a peek | Right and up are **locked** (rubber-band back, no label; user 2026-10-23); only left. |

Grading is binary otherwise: `.good` or `.again`.

- **No Trop facile button** in the drill: swipe up is trop facile (user).
- **Swipe lesson = leçon 0, « Comment glisser »** (user 2026-10-23): the top
  card moves by itself through peek / far left / right / up, with captions in
  the count area; touching a card ends it, then the learner practises on
  leçon 1's first 4 words. Ungraded (nothing graded, logged or counted). A new
  learner gets it before leçon 1 until it is finished once; it replays from
  the Sommaire (row 00). Leçon 1 itself has no animation.

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

## Engine API (phase 3)

Built 2026-10-23. Pure parts self-test at DEBUG launch (`VocabBook._selfTest`,
`VocabQueue._selfTest` in `caramboleApp.swift`).

- **`Models/Vocab.swift`**: `VocabEntry` (`id`, `fr`, `pos`, `en`, `rank?`,
  `fem?`, `register?`, `audio`) with display helpers: `displayWord`
  (« confiance », « doux, douce »), `displayArticle` (« (la) », « (l') »,
  « (se) », nil when none; set it smaller after the word, as in the mock),
  `displayFR` (one line, « confiance (la) »), `posLabel` (`n.m. · fam.`),
  `isExpression`. The article split is the mock's `head()` rule (le / la / les /
  se + space, l' / s'). `VocabBook` → `bands: [VocabBand]` → `lecons:
  [VocabLecon]` (`index` global, `band`) → `entries`; `lecon(index:)`,
  `entry(id:)`, `nextLecon(done:)`, `VocabBook.loadBundled()` (reads
  `Resources/Vocab/mots.json`; missing / broken file → `.empty`, logged). Bad
  entries (non-`voc_` id, empty field, duplicate id) are dropped on decode.
- **`Core/VocabQueue.swift`** (pure value type): build with
  `VocabQueue.learn(entries:armed:)` or `VocabQueue.review(due:cap:)`.
  Read `visible` (top card first, ≤ 4 `Card`s: `id` per presentation, `entry`,
  `armed` → « Trop facile ? » tag, `again` → dashed outline), `current`,
  `remaining` (big count), `stats` (`known`, `again`, `tooEasy`), `peeked`,
  `canSwipeRight` / `canSwipeUp` (false after a peek: rubber-band),
  `isFinished`, `mode`. Drive with `apply(.peek / .left / .right / .up)` →
  `.rejected` (snap back), `.peeked`, or `.swiped(Grade)`. Send `.peek` when a
  left drag passes the peek point (mock: 56 pt). After the undo pill's Annuler,
  call `undoTooEasy()` (stats only).
- **`Core/VocabStudy.swift`** (I/O): `VocabStudy.commit(grade)` after every
  `.swiped` (`.rate` → `ElementGrader.grade`; `.tooEasy` →
  `TooEasyGate.resolve`); on `.tooEasy(_, removed: true)` set the
  `.tooEasyUndo` pill's element id and bump its token, as Books 1 and 2 do.
  `VocabStudy.learnQueue(lecon:armed:)` (entries not yet answered right; all of
  them once the leçon is complete), `VocabStudy.reviewQueue(book:cap:)` (pass
  `settingsStore.settings.reviewRoundSize`), `VocabStudy.dueCount(book:)`.
- **Book plumbing**: `BookKind.vocab`, `BookCatalog.mots` (`book_fr_mots`,
  scope `book_fr_mots`), **not yet in `BookCatalog.all`** (add it in phase 4).
  `ContentLoader.loadBook(.mots)` maps bands → modules (`voc_band_<n>`, title
  « Mots 601–700 ») and entries → elements, so `BookViewModel` / History work
  on `voc_` ids. `StudySessionView` has a `.vocab` placeholder (a Fermer
  button) for phase 4 to replace with `VocabSessionView`.
- **Settings**: `StudySettings.Limits` (`.standard` for Books 1–2, unchanged;
  `.vocab`: new/day 10–20, default 10; review cap options 200 / 250 / 300,
  default 250). `StudySettingsStore(book:)` picks them; `store.limits` feeds
  `SettingsView`'s stepper range and round-size options.

Claude defaults in phase 3 (flagged to the user): review order = lowest FSRS
recall first (Book 1's order) for "most overdue"; the trop facile gate resolves
on the swipe (a peek only locks); an armed left swipe cleans records with no
extra `.again`; every left swipe grades `.again`, a later right grades `.good`
(as Book 1's learn loop); the entry id is the `exampleID`; review cap options
200 / 250 / 300.

## Views (phase 4)

Built 2026-10-23, port of mock v7 (`design/vocab/vocab-swipe.src.html`).

- **`Features/Vocab/VocabLessonView.swift`**: slab (« Leçon 1 · mots 1–100 »
  + big number), hint, dictionary rows (`VocabHeadword` + pos label + gloss +
  play disc), tap = arm (pale lime row, « Trop facile » label), Commencer ·
  N mots (N = pending entries) fixed at the bottom; locked module →
  « Verrouillé ».
- **`Features/Vocab/VocabSwipeCard.swift`**: the card (72 pt, 1.5 pt ink
  outline, dashed `fragile` [3, 2.5] when requeued, « Trop facile ? » tag),
  `VocabHeadword`, `VocabPlayDisc` (34 pt `quietFill` disc, mock triangle,
  `Speaker.playBundled`; dimmed when the clip is missing).
- **`Features/Vocab/VocabSessionView.swift`**: `VocabSessionModel`
  (`@StateObject`: leçon, armed set, live `queue` + drawn `display` that lags
  by the 0.26 s fly-out) and the view (✕, hero count / swipe-lesson captions,
  tray with ≤ 4 cards, underlay, done panel, gestures with the mock's
  thresholds and curves). Leçon 0 (`isSwipeLesson`): no Leçon page, the
  swipe lesson then 4 practice cards, nothing reaches `VocabStudy.commit`;
  done panel « Leçon 0 · Comment glisser » + « Leçon 1 ». Opens instead of
  leçon 1 while `VocabStudy.swipeLessonDone` (UserDefaults
  `settings.book_fr_mots.swipeLessonDone`) is false; `ModuleListView` row 00
  replays it (`VocabSessionView(swipeLesson: true)`). The mock's 0.5 s lead-in
  is gone (no Leçon page to fade from). No lock label after a peek.
- **Routing**: `BookCatalog.all` now has *Mots* (shelf slot 03, percent from
  its own `BookViewModel`); `StudySessionView` `.vocab` → `VocabSessionView`.
  `BookViewModel.moduleLearnElements` / `newAvailableToday` serve ONE leçon of
  the band (`vocabLecon(for:)` → `VocabStudy.nextLecon(in:)`), so Book home,
  module list and Aujourd'hui all open / count the same leçon.
- **Pacing (PROVISIONAL, Claude default pending the user)**: all in
  `Core/VocabPacing.swift`. One leçon per new-word session, never cut; only
  words (not `loc.`) count against `newPerDay`
  (`VocabStudy.wordsLearnedToday`). Done panel: under the cap « Leçon
  suivante »; at the cap « Terminer » + « Encore une leçon ». Apprendre on the
  book home is never blocked by the cap.
- **Shared trop facile**: `.tooEasyUndo` gained `onUndo:` (stats); the pill
  sits at the top like Books 1–2 (user 2026-10-23; the short-lived `edge:`
  parameter is gone).
- **Shelf mark**: `BookMarkShape.placeholder`, a plain torn disc with the
  number (no overprint), until the studio mark process picks one.
- **Simulator flags (DEBUG)**: `CB_OPEN_BOOK=book_fr_mots CB_START=learn|review`,
  `CB_VOC_ARM=n`, `CB_VOC_START=<s>` (press Commencer), `CB_VOC_SCRIPT=
  touch,peek,left,right,up,lock,wait,…` (+ `CB_VOC_SCRIPT_DELAY`),
  `CB_VOC_REVIEW_ALL=1` (band 1 as if due). Test install under
  `CB_BUNDLE=wen.carambole.enginetest`.
- Known mock-vs-app differences: see the 2026-10-23 phase 4 report (✕ glyph,
  balanced captions hard-broken, headword shrinks before it truncates, pill
  shape from the shared modifier).

## Log

- 2026-10-23: plan saved; mock v1–v7 iterated with the user (layout above).
- 2026-10-23: Coverage probe: misses in the top 1,000 were sinon, lui-même,
  ok, manière, sauf, moi-même, épouser, vacance(s).
- 2026-10-23: review set v1 (9 entries, one per entry type), audio 9/9
  Lingua Libre; user: "works".
- 2026-10-23: phase 3 engine: `Models/Vocab.swift`, `Core/VocabQueue.swift`,
  `Core/VocabStudy.swift`, `BookKind.vocab` / `BookCatalog.mots`, per-book
  `StudySettings.Limits`. Simulator build clean; launch self-tests pass.
- 2026-10-23: phase 4 views: `Features/Vocab/` (Leçon page, swipe card, session
  + swipe lesson), *Mots* on the shelf, provisional `VocabPacing`, placeholder
  shelf mark, `.tooEasyUndo(edge:onUndo:)`. iOS 27.0 simulator build clean;
  launch self-tests pass; frames checked against the mock in headless Chrome.
- 2026-10-23: user calls: swipe lesson → ungraded leçon 0 « Comment glisser »
  (Sommaire row 00, before leçon 1 until done once); undo pill back at the top
  (shared default); « Sens vu · glisse à gauche » lock label dropped (app and
  mock src); pacing, review set v2 and `pron.` / `interj.` accepted. Caption
  box now two natural Manrope lines, so the progress dashes clear « pour ».
