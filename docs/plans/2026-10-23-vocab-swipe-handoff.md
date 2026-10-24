# Vocab swipe book *Monnaie courante*: handoff (updated 2026-10-24)

Start here for the vocab swipe book. It was called *Mots* (working title);
its id stays `book_fr_mots` and its data file stays `mots.json`. The full
spec, every user decision, the engine API and the view notes are in
`docs/plans/2026-10-23-vocab-swipe-plan.md`. Read it before you change code
or content.

## 1. State

- Branch `vocab-swipe` (off `main` at the 2026-10-22 state). **Not merged,
  not pushed.** All work is committed; the tree is clean.
- Phases 1–5 are done for bands 1–10: 1,000 ranked words + 200 expressions,
  100 leçons, 1,189 clips (1,124 Lingua Libre, 65 TTS). `lint.py`: 0 errors.
  `audio_release_gate.py`: both books 0 unresolved.
- The user approved the following:
  - mock v7: https://claude.ai/artifact/HgtXFFSV5CKDbbCS2ayhgi
  - review sets v1: https://claude.ai/artifact/2ApAfTxrGYrtPW9FDqU5ko
  - review sets v2: https://claude.ai/artifact/KqmX6XvU5KydcVenntN4iy
  - review sets v3: https://claude.ai/artifact/1dgzYJEV3ELPrhJm1GxBpo
  - v3 was approved together with the band 3–10 rules: celui / lequel merges, two « neuf » cards, madame / mademoiselle with no article, reflexive headwords, fam. / vulg. labels.
- In the app (simulator-checked on iOS 27.0 with the test bundle):
  - **Shelf:** book 03 « Monnaie courante » with the **bitten coin** mark (Pale face, `BookMark.swift`). Its two-line title is hard-broken (`BookDescriptor.shelfLines`), spacing −6.7 → 37 pt pitch, on every iOS version.
  - **Leçon 0 « Comment glisser »:** an ungraded swipe lesson, then a practice round. It is Sommaire row 00. It comes before leçon 1 until it has been done once.
  - **Placement « Où commencer ? »:** runs after leçon 0. It shows 5 words a band; it stops at the first band with 2 or more misses and starts the learner at that band's first leçon. It is ungraded and can be retaken from the Sommaire (`Core/VocabPlacement.swift`).
  - **Leçon page:** dictionary rows; a tap arms trop facile.
  - **Session:**
    - a 4-card stack; peek = small left drag, far left = `.again`, right = `.good`, up = trop facile
    - after a peek, right and up rubber-band back, with no label
  - **Undo pill:** on the ✕ row for this book (`.tooEasyUndo(insets:)`). Books 1–2 are unchanged.
  - **Pacing:** one leçon per session; only the 10 words count against the 10–20 daily cap; after that, « Encore une leçon ». Review cap 200 / 250 / 300, default 250.

## 2. Open, ask when relevant

- Merge `vocab-swipe` → `main` and push: only when the user says so.
- Credits screen design (Lingua Libre speakers per clip + Lexique 3).
  The data is ready in `carambole/Resources/Vocab/credits.json`. It is a generic
  bundle name (Xcode flattens resources), so rename it before another book adds one.
- Bands beyond 10: only if the user asks. `ranked.tsv` holds the top 5,000;
  14 spare expressions are already in `expressions.json`.
- Known differences from the mock (all reported to the user):
  - the ✕ glyph
  - a long headword shrinks before it truncates
  - no "playing" state on the play disc
- `design/vocab/vocab-swipe.html` (built mock, published v7) still shows the
  removed lock label; only the `.src.html` was updated.

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
| `carambole/Resources/Vocab/mots.json`, `credits.json` | Book data, credits |
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
