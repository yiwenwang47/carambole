# Archived code

Not compiled (outside the synchronized `carambole/` folder). To revive a file,
move it back under `carambole/` and restore its call sites from git history.

- `LibraryRibbon.swift` — the 08 "Ruban" paper ribbon down the library shelf
  (one link per book, 30-day activity). Dropped 2026-10-14 when the star became
  a die-cut card: its 3D paper look no longer matched the flat language marks.
  Call sites removed in the same commit: `LibraryView.shelf(width:)` (image +
  `stretch(for:)` + the two `HistoryViewModel`s feeding it) and
  `LibraryRibbonGeometry._selfTest()` in `caramboleApp.swift`. Palette colours
  (`ribbonFront/Back`, `soonFront/Back`) are still in `Theme.swift`.
