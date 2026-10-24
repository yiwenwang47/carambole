# Truncation fixes handoff (2026-10-24)

**Merged into `main` and pushed 2026-10-24** (`3bc74731`, scroll fix
`30ac3321`); branch deleted; Release build installed on the phone. Hard rule: never truncate with « … » anywhere;
when text can overflow, ask the user what to do (memory
`no-ellipsis-ask-when-too-long`). Source audit:
`docs/reports/2026-10-24-truncation-audit.txt`.

Choices mock: https://claude.ai/artifact/C7fYdLDX49LBE7kkkbW3eG
(`design/vocab/overflow-choices.html`, v3).

## 1. Done (commit `b5628109`)

- **Peek gloss** → lint guard. `tools/vocab/lint.py` calls
  `tools/vocab/textfit.py` (PIL + Manrope variable font, mirrors SwiftUI word
  wrap and shrink). Box 15 pt / 180 × 72; fails below scale 0.8.
- **History `DayRow`** → `ViewThatFits`: counts drop under the date when the
  row is too narrow. Normal rows unchanged (sim-checked).
- **`TypeAnswerView`** → wrapping `UITextView` (`TypingTextField`), grows one
  line at a time, Return dismisses, pasted newlines become spaces. Sim-checked
  with `CB_DRILL_TYPE` (new `DrillDemo.typedText`). Keyboard and caret not
  checked (taps can't be automated). The old clear button is gone.
- **`ModuleDetailView`** deleted. `ModuleElementRows` / `ElementRow` moved to
  `Features/Book/ModuleElementRows.swift` (used by `DrillSessionView`).
  `TickerLine` and `LearnSession` deleted.
- Authored « … » in content (« ne ... pas » etc.) stays (user).

## 2. Built 2026-10-24

- **`MagnetTile` → B′** (user, 2026-10-24): a tile that can't fit the tray on
  one line wraps; the capsule shape is kept; one 1 pt ink border (no second
  outline); the wrapped tile hugs its widest line. Mock section 3, « B′ ».
  - Code: `carambole/Features/Drill/MagnetBoard.swift`, `struct MagnetTile`.
    Today: `.lineLimit(1)` + fixed `frame(height: MagnetBoard.tileHeight)`.
    Needs: no line limit, min height = `tileHeight`, vertical padding for the
    wrapped case, width capped at the tray width.
  - `MagnetBoard.reservedLineHeight` uses `MagnetTile.estimatedWidth` and
    assumes one-line tiles. Update it so a wrapped tile reserves its taller row,
    or the baseline jumps (drill card must never scroll whole; memory
    `drill-card-vertical-locked`).
  - No real tile wraps today, so test with a made-up long token (mock uses
    « Est-ce que vous parlez anglais avec eux? » in
    `el_questions_inversion_05`). Check the bank, placed and wrong styles.
- **Book 1/2 Trop facile footer** → keep today's layout (user reversed the
  earlier "drop it"). No code change.

- **MagnetTile B′ built:** `MagnetTile` = ViewThatFits (one-line capsule, or
  wrapped capsule 20 pt sides / 7 pt top-bottom); `MagnetBoard.reservedLineHeight`
  reserves the taller row (`MagnetTile.estimatedHeight`). Sim-checked bank,
  placed, wrong, weld with made-up 40- and 55-char tiles.
- **Weld text wraps:** `WaveText` lays words out in `FlowLayout`, each word sized
  at the resting weight (no re-wrap mid-wave) and never broken inside; the weld
  uses `matchedGeometryEffect(properties: .position)` so the morph doesn't
  squeeze the text into the tile frame. Known: at the wave crest bold letters
  briefly crowd the spaces (~0.2 s).
- **Leçon row → option B** (user, mock `design/vocab/lecon-pos-options.html`,
  https://claude.ai/artifact/4eMZuwWyE64hFXc4QaT8SK): part of speech in a 52 pt
  left margin on the headword baseline, register under it; headword wraps at
  full size (`VocabHeadword(wraps:)`, article glued by a no-break space; no
  real headword wraps even at 375 pt). « Trop facile » label and tap-to-arm
  removed: swipe a row left past half to arm (only marks; resolves on the
  first card as before), swipe again to disarm. Hint « Glisse à gauche un mot
  trop facile ». Sim harness: `CB_VOCAB_LECON` / `_ARMED` / `_DRAG` / `_SKIP`.
  The swipe is a UIKit pan (`LeftSwipeGesture`) that begins only on a leftward
  horizontal drag: a SwiftUI `DragGesture` on the rows blocked the list's
  scroll (phone bug, fixed and confirmed by the user 2026-10-24). The simulator
  can't drive scrolls or swipes; the user checks those on the phone.
- Checks passed 2026-10-24: vocab lint, lint_topics, bank_lint, situations
  lint, audio release gate, Debug + Release sim builds.

## 3. Still open, ask the user

- **Review sets v1–v3** (`design/vocab/review-v1..v3.html`) still use
  `text-overflow: ellipsis`. Rebuild with `design/vocab/build.py --draft`
  (needs a dir with `report.json` + MP3s; the old one may be gone).

## 4. How to check

- Sim harness: `tools/sim/sim.sh` (build / install / launch with `CB_*` /
  remote / shot). Use bundle `wen.carambole.enginetest` (`CB_BUNDLE`), not the
  real `wen.carambole`. `remote openHistory` works only after `openToday`.
- Simulators only, never the phone. Delete own builds/screens after
  (`CB_DD` build dir in the session scratchpad).
- Before merge: `python3 tools/vocab/lint.py`, audio gate, full build.
