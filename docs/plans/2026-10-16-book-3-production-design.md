# Book 3 production design

**Status:** implemented 2026-10-16. See
`2026-10-16-book-3-production-handoff.md` for the integrated code state and checks.
The reviewed Test book cards remain the content source; production uses a
separate, validated bundle.

## Learner outcome

*Nuances* moves a learner who has finished *Fondations* and *En situation*
toward B2 reading and expression. Twenty ordered modules practice connected
French text, attribution, conditions, tact, and synthesis. Every task includes
its visible French source. The book makes no CEFR certification claim.

## Content and review unit

- Book ID: `book_fr_nuances`; module IDs: `nu_01` through `nu_20`; element IDs:
  `nu_XX_e01` through `nu_XX_e05`. IDs never overlap the first two books.
- Each module packages its 24–30 reviewed cards in authored order into five
  contiguous skill groups. The groups have specific French labels and short
  learning notes. A group, rather than an individual card, is the FSRS review
  unit. Card IDs stay as authored, so retries and history remain stable.
- A learning visit presents the next unseen group, up to three unseen cards in
  authored order. A review visit presents one card per due group: a previously
  missed card first, otherwise an unseen card, otherwise the least recent card.
  A group graduates only when FSRS stability reaches 21 days and the learner
  has correct answers on three distinct cards in at least two formats.
- Three choices are shuffled by stable card ID and presentation count. Typed
  answers use the authored accepted variants. Matching ignores case, extra
  whitespace, straight versus curly apostrophes, and terminal sentence marks;
  it preserves accents and word order. An exact accepted answer grades `good`
  on the first try. For a different but valid paraphrase, the learner can see
  the model and mark it equivalent; that grades `hard`. A second-try match also grades `hard`;
  an unsolved card grades `again`. This prevents a short variant list from
  rejecting every legitimate open-ended rewrite.
- “Trop facile” uses the shared `TooEasyGate`, `TooEasyControl`, and undo pill.
  It is armed before checking; a clean answer suspends and graduates the group,
  while a miss clears its progress and the session advances to the next group.
- The source is the only scrolling region on a card. Dialogue speaker labels
  stay visible on the blue source block. A card has one short task and feedback.

## Production bundle and validation

- `Resources/Nuances/nuances_manifest.json` lists 20 module files. Each module
  includes title, goal, five elements, and embedded cards. The DEBUG Test book
  JSON remains available for review, but Release loads only the production
  bundle. Production files are generated once from the reviewed source and
  may receive final editorial corrections before release.
- A content gate checks all files, global ID uniqueness, module and group
  counts, four-format coverage, answer shape, punctuation-free typed variants,
  source/task/answer length ceilings (350/150/120 characters), and all cards
  being assigned exactly once. Tests check matching, selection, grading, and
  one full module decode. Editorial review checks semantic answer support and
  natural French; the automated gate does not claim to prove either.
- The first English meaning choice for harder vocabulary remains in authored
  order. No hidden cue or automatic English text is added.

## App integration and storage

- Add `BookKind.nuances`, a shelf entry titled *Nuances*, and a dedicated
  source-card session. The existing book home, module list, FSRS scheduler,
  settings scope, Today and history counts use the new book's element IDs.
- Add a version 6 migration with an additive `nuance_card_log` table for card
  rotation and last result. Shared `review_status`, `review_log`, and
  `mastery_log` hold group progress; every reader scopes to the book's IDs.
  Existing migrations and all existing user rows remain untouched.
- Audio coverage for this first production version is **none**. The course
  tests reading and expression with visible text, so it has no speech control,
  bundled clips, or listening-only tasks. If speech is added later, register
  its clip index and pass the release audio gate before shipping.

## Waves and gates

1. Editorial pass of all 550 cards; run the pilot model test and review changed
   cards across module boundaries.
2. Package and validate one complete production module, then all 20. Test
   decoding and card selection before connecting UI.
3. Add persistent group/card progress, grading, and shared “Trop facile”. Test
   migration against a populated version 5 database.
4. Integrate shelf, module, session, Today, and history surfaces. Build and
   inspect the Test book and production Book 3 in the iPhone simulator, with
   module 18 as the late difficulty checkpoint. Do not install on the phone
   without a user request.
