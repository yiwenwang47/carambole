# Vocab swipe book *Monnaie courante*: handoff (updated 2026-10-24)

Start here for the vocab swipe book. It was called *Mots* (working title);
its id stays `book_fr_mots` and its data file stays `mots.json`. The full
spec, every user decision, the engine API and the view notes are in
`docs/plans/2026-10-23-vocab-swipe-plan.md`. Read it before you change code
or content.

## 0. Hard rule (user, 2026-10-24)

**Never cut text with « … » dots**, in the app or the mocks. That covers
`.truncationMode`, `.byTruncatingTail`, `text-overflow: ellipsis`, and a
`lineLimit` + `minimumScaleFactor` that runs out of room. When text in a
new or changed view could be too long, **ask the user exactly what to do**
(shrink, wrap, widen, rewrite). Don't choose a fallback yourself. Put this
rule in every subagent brief. Long vocab headwords shrink to fit
(`.minimumScaleFactor(0.7)`); measure with the bundled font to confirm that
0.7 is always enough.

## 1. State (2026-10-24)

- **Merged to `main` and pushed 2026-10-24** (fast-forward, `efd49692`).
  Follow-up no-dots work is on branch `truncation-fixes` (see §2).
- Content:
  - Bands 1–10: 1,000 ranked words + 200 expressions, in 100 leçons.
  - Clips: 1,189 (1,124 Lingua Libre, 65 TTS).
  - Checks: `lint.py` reports 0 errors; `audio_release_gate.py` reports 0
    unresolved for both books.
  - The book is **complete at band 10.** Words past rank 1,000 will be a
    DIFFERENT book (user); never extend this one.
- The user approved:
  - mock v7, republished 2026-10-24 as v8 from the rebuilt file (no lock
    label, no card tag, headwords shrink to fit):
    https://claude.ai/artifact/HgtXFFSV5CKDbbCS2ayhgi
  - review sets:
    - v1: https://claude.ai/artifact/2ApAfTxrGYrtPW9FDqU5ko
    - v2: https://claude.ai/artifact/KqmX6XvU5KydcVenntN4iy
    - v3: https://claude.ai/artifact/1dgzYJEV3ELPrhJm1GxBpo
    - v3 was approved together with the band 3–10 rules: celui / lequel
      merges, two « neuf » cards, madame / mademoiselle with no article,
      reflexive headwords, fam. / vulg. labels.
- In the app (simulator-checked on iOS 27.0):
  - **Shelf:** book 03 « Monnaie courante » with the bitten coin mark (Pale
    face, `BookMark.swift`). The two-line title is hard-broken
    (`BookDescriptor.shelfLines`).
  - **Leçon 0 « Comment glisser »:** an ungraded swipe lesson, then a
    practice round. It is Sommaire row 00, and it comes before leçon 1
    until it has been done once.
  - **Placement « Où commencer ? »:** runs after leçon 0.
    - It shows 5 words per band and stops at the first band with 2 or more
      misses.
    - It starts the learner at that band's first leçon.
    - It is ungraded and can be retaken from the Sommaire
      (`Core/VocabPlacement.swift`).
  - **Leçon page:** dictionary rows.
    - **Tapping a row arms trop facile** (the « Trop facile » row label stays;
      user 2026-10-24).
    - A long headword shrinks to fit (0.7).
  - **Session:**
    - The stack holds 4 cards. A small left drag peeks, far left = `.again`,
      right = `.good`, up = trop facile.
    - After a peek, right and up rubber-band back, with no label.
    - **Cards carry no « Trop facile ? » tag** (removed 2026-10-24). Swipe up is
      the only marking action on a card. An armed card looks like any other
      card and resolves on its first swipe (clean right → removed with undo;
      anything else → reset).
    - Every headword fits the card at full size at 390 and 402 pt (widest:
      « donner un coup de main », 259 of 266 pt).
  - **Mock-match fixes (2026-10-24):**
    - The ✕ is drawn as two bars (`VocabCloseGlyph`).
    - The play disc shrinks to 0.92 while its clip plays.
      `Speaker.playBundled(key:onEnd:)` is new; its `onEnd` is optional and
      Books 1–2 don't pass it.
  - **Undo pill:** on the ✕ row for this book (`.tooEasyUndo(insets:)`).
  - **Pacing:**
    - One leçon per session.
    - Only words count toward the 10–20 daily cap. After the cap, the done
      panel offers « Encore une leçon ».
    - Review cap: 200 / 250 / 300, default 250.
- **Credits screen (all books, 2026-10-24):** Settings (home, bottom right)
  → About → Credits (`Features/Settings/CreditsView.swift`,
  `Models/Credits.swift`). It lists:
  - Lexique 3;
  - Lingua Libre: the speakers with their clip counts, the licence counts
    (673 CC BY-SA / 404 CC0 / 47 CC BY) and an « All recordings » page that
    links every clip to Commons;
  - Google TTS, for 65 Monnaie courante words and for Books 1–2;
  - the fonts Manrope and Familjen Grotesk (OFL).
  The data file is `Resources/Vocab/mots_credits.json` (renamed from
  `credits.json`, since Xcode flattens resources). `build_lists.py assemble`
  writes it and `lint.py` checks it.
- **Today pile pills (all books, 2026-10-24):** pills now take up to 2
  lines, with word wrap and no truncation.
  - All 1,900 labels fit in 2 lines with no text changed. 200 use 2 lines;
    all of them are from Books 1–2.
  - A two-line pill is 52 pt tall and as narrow as still gives 2 lines. The
    widest is 188 pt (« Terminaisons masculines : … »). The old cap was 176.
  - Join and leave use the same motion as before. The start height and a
    wall-safe start x are sized to each pill, and the Reduce Motion rows use
    the tallest pill.
  - `TokenPileScene._selfTest` lays out every label of every book.
  - Debug flags: `CB_TODAY_LONG=<n>` puts the n widest labels in the pile;
    `CB_TODAY_CYCLE=<secs>` makes 4 of them leave and join on a timer.
- **Mock** `design/vocab/vocab-swipe.src.html` + built `vocab-swipe.html`:
  - The lock label is removed.
  - The card tag is removed.
  - Headwords shrink to fit (`fitHead`, minimum 70%). This was checked in
    headless Chrome.

## 2. Open, ask the user when relevant

- **Branch `truncation-fixes`** (not merged): no-dots fixes and pending
  choices. Start at `docs/plans/2026-10-24-truncation-fixes-handoff.md`.
- **Rebuild review sets v1–v3:** `design/vocab/review-v1..v3.html` still use
  `text-overflow: ellipsis` on headwords (built before the rule). Rebuild
  with `design/vocab/build.py --draft`. The original mock audio dir lived in
  an old session scratchpad, so it may be gone; `build.py` needs a dir with
  `report.json` + MP3s.
- **Bands beyond 10:** these will be a new book. Don't add them here.
  `ranked.tsv` holds the top 5,000 for that book.

## 3. Files

| Path | What |
|---|---|
| `docs/plans/2026-10-23-vocab-swipe-plan.md` | Spec, engine API, views notes, log |
| `carambole/Models/Vocab.swift` | `VocabEntry`, `VocabBook` (bands → leçons), display helpers, loader |
| `carambole/Core/VocabQueue.swift` | Pure card stack (requeue, cap, peek lock, placement mode), `_selfTest` |
| `carambole/Core/VocabStudy.swift` | Builds queues from stored progress; commits grades via `ElementGrader` / `TooEasyGate` |
| `carambole/Core/VocabPacing.swift` | Daily-cap rule, `_selfTest` |
| `carambole/Core/VocabPlacement.swift` | Placement sampling + stop rule, `_selfTest` |
| `carambole/Features/Vocab/` | `VocabLessonView`, `VocabSwipeCard`, `VocabSessionView` (leçon 0, placement, sessions) |
| `carambole/Resources/Vocab/mots.json`, `mots_credits.json` | Book data, credits (Credits screen) |
| `carambole/Resources/Audio/voc_*.mp3` | Clips (`Speaker` finds them by key) |
| `tools/vocab/build_lists.py` | Lexique import (`rank`) and `mots.json` build (`assemble`) |
| `tools/vocab/lint.py` | Entry / audio / collision lint |
| `tools/vocab/fetch_audio.py` | Lingua Libre → TTS fill → trim + normalize, 24 kHz mono; resumable |
| `tools/vocab/data/` | `lexique_rules.json`, `glosses.json`, `expressions.json`, `ranked.tsv`, audio reports |
| `tools/vocab/drafts/sample_v1–v3.json`, `design/vocab/review-v1–v3.html` | Review sets |
| `design/studio/books.js`, `PREFERENCES.md` | Book marks incl. round 3 (coins) |

## 4. Commands

```bash
python3 tools/vocab/build_lists.py rank       # Lexique → tools/vocab/data/ranked.tsv
python3 tools/vocab/build_lists.py assemble   # glosses + expressions → mots.json
python3 tools/vocab/lint.py                   # 0 errors expected
python3 tools/situations/audio_release_gate.py
python3 design/vocab/build.py <clip dir> --draft tools/vocab/drafts/sample_vN.json --out design/vocab/review-vN.html
python3 design/studio/server.py               # studio on http://127.0.0.1:8765
```

DEBUG launch flags for simulator checks are in the plan doc's Views note
(`CB_VOC_ARM`, `CB_VOC_START`, `CB_VOC_SCRIPT`, `CB_VOC_REVIEW_ALL`). Install
the test build under the `wen.carambole.enginetest` bundle id so the user's app
data stays untouched. Simulators only, never the phone.

## 5. Gotchas

- **Commons:** exact-title lookups (`File:LL-Q150 (fra)-<speaker>-<word>.wav`,
  50 per `titles=` call) are the fast path. Category listing and anonymous media
  hit 429 with `retry-after: 600`. Keep the contact in the User-Agent. Some
  titles use a curly apostrophe (`s’il`).
- **Google TTS** tokens last an hour; `fetch_audio.py` refreshes them.
- **Clip keys fold accents:** `où` → `voc_ou_adv`, `sûr` → `voc_sur_adj`,
  `côte` → `voc_cote_nf`, `marché` → `voc_marche_nm`; `œ` → `oe`. Lint catches
  new collisions.
- **Lexique quirks:** odd lemma forms (`vacance`), repeated lemmas under other
  parts of speech, `oe` for `œ`, and « suis » counted under both être and
  suivre. These are handled in `lexique_rules.json`.
- **Rank** is the position in the filtered list, so band b = ranks
  100(b−1)+1 to 100b. Bands 1–2 membership is fixed (seeded); don't reshuffle.
- **SwiftUI ignores a negative `lineSpacing`** on a wrapped `Text`. For tight
  multi-line titles, use hard line breaks in a VStack with negative spacing.
