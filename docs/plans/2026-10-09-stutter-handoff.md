# Stutter / animation hitches — handoff (2026-10-09)

Branch `perf-stutter-fixes`. **Status: partly fixed. The user still sees stutter
on device.** Read this before touching performance again.

## Symptom (user report)

- Animation stutters "sometimes" when switching pages.
- The screen stutters while scrolling up/down.
- After the last build (below), the user says "the stutter/glitches are back".

## What is committed on this branch

1. **Book star pauses under covering pages** (`BookView.swift`). The star's
   RealityView is removed while the modules list, Today or a drill
   (`fullScreenCover`) covers the book. It is re-added *immediately* when the page
   pops (no delay). Before this change, only Today paused it.
2. **120 Hz unlocked**: `carambole-Info.plist` (outside the synced `carambole/`
   folder, merged via `INFOPLIST_FILE`) sets
   `CADisableMinimumFrameDurationOnPhone = YES`. The `INFOPLIST_KEY_…` build
   setting does NOT work for this key; Xcode drops it silently. Before this, the app
   was capped at 60 fps on the 120 Hz iPhone 18 Pro.
3. **`tools/perf/`**: the measurement harness (see "How to measure").

## Tried and rejected by the user

- **Deferring the star / Colors star / library ribbon attach by ~0.4 s after a
  push, with a fade-in.** Rejected: "now the animations dont show up immediately".
  It also gained little: it cut push freezes only by 15–40 ms, and the book push
  stayed at about 140 ms. **Do not delay or hide on-screen objects to mask hitches.**
  Fix the cost instead (memory: `no-deferred-animation-start`).

## Measurements (iPhone 18 Pro, Release build, automated tour)

Each run uses the same scripted tour. Two meters run at once:
- **Instruments Animation Hitches** reports late frames while something animates.
- **The in-app main-thread meter** reports the worst single frame per segment. It
  catches the freeze *before* a slide starts, which Instruments mostly does not
  count as a hitch.

Instruments hitch time per segment, in ms, with the late-frame count in brackets:

| segment | base ×2 | ribbon off | wave static | star paused | Colors star off | deferral (rejected) ×2 |
|---|---|---|---|---|---|---|
| library_scroll | 50 (3) / 50 (3) | 17 | 50 | 17 | 50 | 33 / 67 |
| module_idle | 142 (17) / 125 (15) | 25 | 17 | **0** | 50 | 0 / 0 |
| module_scroll | 42 (5) / 142 (17) | 104 | 17 | **0** | 258 | 0 / 25 |
| whole tour | 292 / 325 | 246 | 108 | **46** | 433 | 50 / 275 |

Worst main-thread frame at page switches. A normal frame is 16.7 ms at 60 Hz:

| switch | baseline | star paused | deferral (rejected) |
|---|---|---|---|
| library → book | 148–153 | 154 | 139–145 |
| book → modules | 118 (11 late frames) | **61** | 60 |
| modules → module page | 77–82 | 73 | 77 |
| book → library (pop) | 125–127 | 78 | 80–84 |
| library → Colors | 105–113 | 115 | 90 |

The committed state is the **"star paused"** column plus 120 Hz. The combination
of star paused + 120 Hz has **not** been measured. Per-run data is in
`tools/perf/results-2026-10-09.json`.

Micro-benchmarks: building the star mesh takes 1–7 ms, so it is not the cause.
Creating the 520 variable-font weights cold takes 9–26 ms in total; they are
cached after that.

## What is still wrong (open work, in priority order)

1. **One-frame freezes of 75–155 ms at every page switch.** This is most likely
   what the user feels as "stutter when switching pages". It is main-thread work
   during the push/pop. Pausing the star does not fix it. Leads:
   - `BookView.onAppear → viewModel.load()`: check whether it is synchronous on
     the main thread. Library → book is the worst switch (about 150 ms).
   - `LibraryRibbonScene` rebuilds ALL ribbon meshes inside its `RealityView`
     make-closure on every attach (`ribbonLive` toggles on every push/pop, and
     `.id(...)`). The book star caches its scene in `ObjetStarController`; the
     ribbon does not. Give the ribbon a controller that keeps its entities, like
     the star. Likely culprit for pop → library (80–125 ms) and push → Colors.
   - RealityView creation itself costs about 20–45 ms; the deferral experiment
     showed this. Consider keeping one RealityView alive and moving entities,
     rather than creating and destroying views.
   - `ModuleDetailView` push (about 77 ms): `LoopWaveText.fit` measures text for
     each size step, plus `viewModel.refresh()` on appear.
   - **Next step:** run the harness under the **Time Profiler** template (swap the
     template name in `run.sh`), then read the main-thread stacks for the
     `push_book` / `pop_book` segments.
2. **120 Hz may make 3D scenes hitch more.** With the key on, RealityKit and the
   `TimelineView` wave can render at 120 Hz, which halves the frame budget to
   8.3 ms. The harness cannot verify this: its scroll is programmatic and
   ProMotion only goes to 120 Hz for touch-driven movement, and the harness's own
   `CADisplayLink` defaults to 60 Hz. If the user's "stutter is back" began with
   this build, A/B the 120 Hz key on the device first (remove `INFOPLIST_FILE`).
   Also consider capping the RealityViews and the wave to 60 Hz while keeping UI
   scrolling at 120 Hz.
3. **The title wave (`LoopWaveText`) costs a lot on its own**: it re-lays out
   every letter on every frame. With the star paused it measured clean, but it
   is fragile. Options: quantize weights to about 20 steps, cap the `TimelineView`
   rate (`.animation(minimumInterval:)`), pause it while scrolling.
4. Library scroll has about 50 ms of hitches per 6 s, from the ribbon. This is
   minor. The ribbon view is only about 70 pt taller than the screen, so the
   original "tall Metal surface" theory was wrong.

## How to measure (tools/perf/)

The harness is temporary. Patch it in, build Release with the `PERF_HARNESS`
flag, run, analyze, then revert:

```bash
cd carambole   # repo root
python3 tools/perf/apply_hooks.py
xcodebuild -project carambole.xcodeproj -scheme carambole -configuration Release \
  -destination 'id=00008160-001A09920AA0000A' -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=QMV4SPL476 SWIFT_ACTIVE_COMPILATION_CONDITIONS=PERF_HARNESS \
  -derivedDataPath /tmp/cb-perf build -quiet
xcrun devicectl device install app --device 00008160-001A09920AA0000A \
  /tmp/cb-perf/Build/Products/Release-iphoneos/carambole.app
tools/perf/run.sh base1                          # phone unlocked; about 3 min per run
tools/perf/run.sh nowave CB_PERF_STATIC_WAVE=1   # A/B switches: CB_PERF_NO_RIBBON,
                                                 # CB_PERF_STATIC_WAVE, CB_PERF_NO_COLOR_STAR
python3 -I tools/perf/analyze.py base1 nowave    # joins trace hitches to segments
git checkout -- carambole && rm -rf carambole/Debug   # REVERT: commit app changes first!
```

Gotchas learned:
- SwiftUI does not build its accessibility tree without VoiceOver/XCUITest, so
  `accessibilityActivate()` driving finds nothing. Navigation goes through the
  `perfCommand` notification hooks instead.
- os_signpost and Logger output are not captured by the Animation Hitches
  template. Segments are aligned through `mach_absolute_time` in `perf.json`
  against the trace's `time-info` table.
- `git checkout -- carambole` also reverts uncommitted app fixes. Commit or stash
  the real changes before you apply or revert the hooks.
- The tour leaves the user's data untouched. It only navigates and never taps
  Apprendre/Réviser.
- Afterwards, reinstall the normal Debug build (commands in memory
  `phone-device-install`).
