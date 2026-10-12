# Simulator harness (visual checks)

Taps can't be automated on the simulator here (no idb/cliclick, Apple events
denied), so visual checks drive the app through DEBUG-only launch flags and
Darwin notifications, then look at screenshots / recorded frames. Everything
app-side is `#if DEBUG` and never ships in Release.

**Rules (learned the hard way, 2026-10-10):**
- Simulators only — never test, record or profile on the user's phone.
- Never test on empty progress: load a real database (`load-db`) or seed one
  (`CB_SEED_DEMO=1`).
- Look at the frames yourself (contact sheets), not just pixel-count proxies.
- Clean up: delete recordings once frames are extracted, delete any simulator
  you created, run `sim.sh clean`. **Don't use xctrace/Instruments** unless
  asked — it leaves 3–9 GB `instruments*.ktrace` files in `$TMPDIR` that never
  get removed (83 GB once filled the disk).
- The drill card is vertically locked; only the word-bank tray may scroll.

## `sim.sh`

```bash
tools/sim/sim.sh build                      # Debug build → $CB_DD (default $TMPDIR/cb-sim-dd)
tools/sim/sim.sh install
tools/sim/sim.sh load-db ~/Downloads/carambole-progress.sqlite   # real progress (Settings → Exporter)
tools/sim/sim.sh launch                      # normal app
tools/sim/sim.sh launch CB_DRILL_DEMO=el_si_synthese_01 CB_DRILL_PLACE=8 CB_DRILL_HINT_OPEN=1
tools/sim/sim.sh remote openBook             # navigate (see DemoRemote below)
tools/sim/sim.sh shot /tmp/x.png
tools/sim/sim.sh record /tmp/x.mov 20
tools/sim/sim.sh frames /tmp/x.mov /tmp/f 0 20 0.0333   # exact-time frames (30 fps)
python3 tools/sim/sheet.py /tmp/f /tmp/sheet.png --cols 8 --every 15 --scale 0.2
tools/sim/sim.sh clean
```

Default sim is the iPhone 18 Pro on iOS 27.0 (`CB_SIM` overrides). Only the iOS
27.0 runtime is installed. `CB_BUNDLE=wen.carambole.testbook` builds a separate
app next to the real one (own database), used for the hand-testing test book.

## App-side flags (`carambole/Debug/`)

| Flag / action | File | Effect |
|---|---|---|
| `CB_SEED_DEMO=1` | `DemoSeed.swift` | fill an EMPTY store with a mid-course learner: 381/500 mastered (76 %), 20 learned + 50 reviewed today, reviews due |
| `CB_TEST_BOOK=1` | `DrillDemo.swift` | root becomes a one-page "Test book"; its button opens the `CB_DRILL_DEMO` drill (+ a 2nd card with `CB_DRILL_HINT` if set). For the user to tap through |
| `CB_DRILL_DEMO=<example id>` | `DrillDemo.swift` | open straight into that drill (review mode, no Leçon) |
| `CB_DRILL_HINT=<text>` | `DrillDemo.swift` | override the hint |
| `CB_DRILL_PLACE=<n>` | `TokenBuilderView` hook | pre-place the first n answer tokens |
| `CB_DRILL_HINT_OPEN=1` / `CB_DRILL_HINT_CYCLE=1` | `DrillView` hook | hint open / toggling every 1.6 s (animation recording) |
| `remote openBook` `closeBook` `openModules` `closeModules` `openToday` `closeToday` `openHistory` `closeHistory` `openSettings` `closeSettings` `startReview` `closeSession` `nextPalette` | `DemoRemote.swift` + hooks in `LibraryView`, `BookView` | navigation without taps |
| `CB_RENDER_STAR=1` | `Features/Book/StarVideoRenderer.swift` | re-render the star videos (see `tools/star_video/`) |

Find an example id: `grep -l "<English prompt words>" carambole/Resources/Topics/*.json`.

## Typical checks

- **Star / ring motion:** load a real DB, `remote openBook`, record ≥ 70 s (the
  2026-10-10 bob bug only jumped every 64 s), add `remote openModules` /
  `closeModules` and a trip to Settings mid-recording; sheet at 1 fps plus a
  30 fps strip around anything suspicious.
- **Drill layout:** `CB_DRILL_DEMO` × `CB_DRILL_PLACE` × `CB_DRILL_HINT_OPEN`,
  and a `CB_DRILL_HINT_CYCLE` recording for the open/close animation.
- **Hand testing by the user:** `CB_BUNDLE=wen.carambole.testbook sim.sh build`,
  install, `launch CB_TEST_BOOK=1`. (Env only applies to `simctl launch`;
  opening the icon starts the normal library.)
