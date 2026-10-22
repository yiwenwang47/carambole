# Book 3 strip-down handoff

**Date:** 2026-10-22
**State:** design pilot approved in direction ("great"). No app code or content
has changed yet. The shipped *Nuances* (see
`2026-10-16-book-3-production-handoff.md`) is still the 550-card reading
version.

## Why

The user judged Book 3 poorly designed: too much text. **A drill must take no
more than about 5 seconds.** Measured on the shipped package (task + source +
choices):

| Format | Cards | Median words | Max |
|---|---|---|---|
| microtext | 212 | 60 | 104 |
| dialogue | 114 | 51 | 94 |
| word | 80 | 32 | 55 |
| rewrite (typed) | 144 | 25 | 55 |
| all | 550 | 44 | 104 |

Only 9 of 550 cards are under 15 words. At about 120 words per minute of L2
reading, the median card takes about 22 s.

## The pilot

- Live page: https://claude.ai/artifact/ArTDr7Ssi7Mmd1JHa5Ujc6 (private, same
  URL for further updates).
- Repo copy: `design/book3-pilot/`. Edit `nuances-pilot.src.html` (image
  placeholders `@@name@@`), then run `python3 design/book3-pilot/build.py` to
  produce the self-contained `nuances-pilot.html`. `shots/` holds the simulator
  frames (current Book 3 screens, plus `b1.jpg`, a strip of Book 1 drill frames).
  To republish to the same URL from a new session, publish
  `nuances-pilot.html` with that artifact URL as `url`.
- The pilot rebuilds module 1, group 1 (`nu_01_e01`, « Quand le concert
  s'arrête ») from its 5 current cards into 9 cards. The card data is the
  `CARDS` array in the page script; reuse it as the first real content batch.
- The page's lower section ("Earlier review") is the 2026-10-21 layout review
  of the *current* long cards. Most of it no longer matters if the cards are
  stripped. Keep it for reference only.

## Decisions (user, 2026-10-21/22)

**Book 3's goal is vocabulary + grammar (user, 2026-10-22).** Not reading
inference, tact or tone. The curriculum map's "Outcome" column
(`2026-10-15-book-3-curriculum-handoff.md` §5) only supplies the setting; test
its "Grammar and vocabulary" column. Each group: one grammar point + 2–4 words
from that column. Drop cards that test only inference or tone. *Nuances* is a
working title.

Card content:
- One or two short sentences with a blank. Reading is about 13 to 23 words,
  including options. The user asked for longer sentences than the first
  12-word draft.
- **Two drill types:** *Le mot juste* (4 options) and *Écris-le* (typing).
  The "pick the English definition" type was rejected hard. **Every
  multiple-choice option is French** (word, expression or form).
- Vocabulary blanks show the English meaning under the sentence (grey,
  in quotes) so only one option fits. Tense blanks rely on a cue in the
  sentence (*soudain*, *puis*, *elle n'a pas fini*).
- Typing cards show the English for the blank **plus the infinitive**, e.g.
  “was talking” · PARLER → `parlait`. Never make the learner infer the word
  from context alone. Answers have no punctuation (existing rule).
- Every blank passes the one-answer check: read the sentence with each wrong
  option filled in; each must be wrong French or contradict the cue. Example:
  « Léa a parlé à Théo quand la musique s'est arrêtée » is valid French, so the
  sentence needs a cue that rules it out.

Behaviour:
- **Multiple choice grades on tap**; no Vérifier. Typing checks on Vérifier.
- Trop facile stays (shared `TooEasyGate`), placed **directly above the
  option tiles**. After answering, that slot becomes Suivant.

Layout (also in memory `drill-mock-layout-rules`):
- Prompt at the top, answers **always at the bottom** in thumb reach. Four
  tiles in a 2×2 grid, labels on one line. No empty band between the prompt and
  the options.
- **Tile text alignment (2026-10-22, user leans B, not final):** the pilot's
  96 pt tiles with text bottom-left looked unbalanced. Comparison page:
  `design/book3-pilot/tile-alignment.html` (artifact
  https://claude.ai/artifact/4QxiUx99V6PoCsqKj1pjbS). B = 64 pt tiles, text
  left-aligned and vertically centred. Watch long labels (*s'est
  interrompu*, *Au moment que*): they can wrap at ~169 pt tile width; decide
  wrap vs `minimumScaleFactor` when building. Variant D (one column) is
  archived as **toast slice** in `design/archive/toast-slice/` for another use.
- The blank sits on the text baseline. The typing field is a **plain
  underline**, not a box.
- **Book 1 idiom for colour:** text stays ink; colour lives on objects.
  - Blank = pale lime well (`tileOn`) in the sentence; the answer lands in it as
    a lime magnet.
  - Options on the pale blue tray (`tint`), with ink-outlined tiles like
    Book 1's magnets. Correct = lime fill; wrong pick = dashed `fragile`
    outline.
  - Indice disc (`quietFill`), showing the group note on a pale card.
  - Header: drill type · n / N centred, progress ring on the right; group
    title as the small label above the sentence. « Juste ✓ » outlined pill on
    success; a pale card with the reason on a miss.
- **Écouter** disc on the right of the Indice row. Disabled until the blank
  is answered (Book 2 rule), then plays the full sentence with the answer
  filled in (hard rule: clips are complete).

Keyboard (typing cards):
- A custom in-app keyboard. **Layout = Apple's standard French AZERTY**:
  `azertyuiop` / `qsdfghjklm` / ⇧ `wxcvbn'` ⌫ / 123 · espace · Vérifier.
  Accents on long press (e é è ê ë, a à â æ, u ù û ü, i î ï, o ô œ, c ç,
  y ÿ); shift and a 123 layer work.
- **Style = Carambole:** a pale `tint` tray, white rounded keys, Manrope, no
  shadows, and Vérifier as a `buttonFill` pill in the return key's place.
  The user called an iOS-look keyboard "ugly"; the first custom draft with an
  accent row was rejected for not matching Apple's layout.
- Costs to plan for: no dictation or third-party keyboards; hardware
  keyboard (`.onKeyPress`) and VoiceOver labels must be built. Book 1's short
  typing could adopt the same keyboard later. That is not decided.

## Next steps

1. **Harder group test (done 2026-10-22, awaiting user review).** `nu_13_e03`
   « Relancer sur le point manquant » (6 cards, 32 to 82 words) became 9
   cards of 9 to 23 words, in the pilot page as group 2 (cards carry `g`).
   Findings: the "which detail is missing" skill fits as a question-word
   blank (« donne l'heure, mais pas le lieu … m'indiquer ___ » → où); indirect
   form (si / no inversion), link word (En revanche) and register (vous) fit.
   Whole-sentence choices (pick the polite question) do not fit 5 s or a tile;
   they are dropped in the pilot. The user decides whether to keep them as a
   rare long card type. Grammalecte flagged 1 of 27 wrong fills, so the
   one-answer check must be a human read. Options like « est-ce qu'il sera »
   are close to the tile width.
   **Redone the same day for the vocab + grammar goal:** a Leçon screen lists
   the group's 4 new words (*un délai, une démarche, préciser, relancer*; FR ·
   EN · Écouter) before card 1; cards 1–4 drill each word with the English cue;
   cards 5–9 reuse the words without English inside indirect-question grammar
   cards. Distractors are known look-alikes (*retard*, *prétendre*) so a new
   word is never one guess among four unknowns. The Indice note states the
   grammar rule. « la marche à suivre » (a real idiom) was caught by hand as a
   second right answer. Open: should each new word be its own FSRS element?
   Tile layout B is applied in the pilot.
2. **Content model.** Today's `NuanceCard` (`Models/Nuance.swift`) has
   format, source lines, task, response and feedback. The new card needs
   sentence with a blank (`pre`/`post`), `en` cue, `inf` (typing), 4 choices or
   accepted answers, and a one-line feedback. Groups and FSRS elements can
   stay (100 elements). Decide whether `NuanceMastery` (3 cards across 2
   formats) still makes sense with two drill types.
3. **Content gate.** Extend `tools/nuances/package.py --check`: exactly one
   blank, ≤ ~23 words read, exactly 4 French options for choice cards,
   typed answers without punctuation and with `en` + `inf`, and no option
   that fits the blank (needs a lint + a human read; see the one-answer check).
   Run `lint_topics.py`-style elision checks and Grammalecte (`deep_lint.py`)
   on the filled sentences.
4. **App.** Rebuild `NuanceSessionView` card layout per the decisions above.
   Add the keyboard as a shared view (`DesignSystem/` or `Features/Drill/`).
   Keep the card vertically locked (nothing scrolls). Verify in the iPhone 18
   Pro simulator with `CB_OPEN_BOOK=book_fr_nuances CB_START=learn
   CB_NUANCE_CARD=<id>` (main bundle; the testbook bundle always opens the
   Test book).
5. **Audio** (only if the user confirms Écouter for Book 3): build a
   complete `{key, text, voice}` clip index, generate, normalize
   (`normalize_audio.py`), register in `tools/situations/audio_books.json`, and
   pass `tools/release_build.sh`.
6. Review content with the user in **small sets (about 9 cards)** before
   converting all 100 groups.

## Housekeeping notes

- 2026-10-21 the `wen.carambole.testbook` simulator app was uninstalled
  during cleanup. That wiped any hand-test progress in it. Reinstall with
  `CB_BUNDLE=wen.carambole.testbook tools/sim/sim.sh build && … install` when
  needed.
- The main simulator app was reinstalled from `main` at that time; its data
  was kept.
