# Truncation fixes handoff (2026-10-24)

Branch `truncation-fixes` (off `main`, **not merged, not pushed**; merge or
push only when the user says). Hard rule: never truncate with « … » anywhere;
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

## 2. Decided, not built yet

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

## 3. Still open, ask the user

- **Armed Leçon row** (`carambole/Features/Vocab/VocabLessonView.swift`,
  `row(_:index:)`): user leaned B (headword wraps, « N.F. TROP FACILE » on the
  first line's baseline) but **still doesn't like it** and will revisit in a
  new session. Mock section 1 shows Today / A / B. Don't build until they
  choose. Ask what bothers them in B before making new variants.
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
