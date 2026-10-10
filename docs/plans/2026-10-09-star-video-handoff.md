# Star video + still ribbon — handoff (2026-10-09; updated 2026-10-10)

Work began on `perf-stutter-fixes`. Earlier commits on top of `c1d0347`:

- `bf8784a` perf: replace live 3D star with pre-rendered video loop
- `92b4105` perf: render library ribbon once to a still image

Earlier context and all measurements: `2026-10-09-stutter-handoff.md`.

## User rules (read first)

- Use simulators for routine tests. Use or install on the iPhone only when the
  user explicitly asks. The user requested an install on 2026-10-10.
  Memory: `no-phone-testing`.
- **Look at the frames yourself before you report a visual result.** A
  pixel-count scan is not a visual check. The original bug shipped because only a
  scan was run.
- Objects must show at once; do not delay or fade them in to hide hitches
  (memory `no-deferred-animation-start`).
- State every deviation from the old look (memory `match-mock-real-data-first`).

## Star playback and depth bugs — resolved 2026-10-10

The original `StarVideoLayer` put a frame-0 still **under** an alpha video.
The still showed through the moving star, making a second star visible.
`AVPlayerLooper` also showed a blank frame at each 8.73 s wrap, while the 2D
orbit stayed visible.

The final playback uses one persistent `AVPlayerItem` per palette. At the end,
it seeks that item to frame zero and resumes playback. A frame-0 image sits
**above** the video only until `AVPlayerLayer.isReadyForDisplay`; it then
hides. `StarLoopView` reveals the orbit and star together when either that
image or the video is visible. This prevents the orbit appearing alone while
the first video frame loads.

The ring still has a rear tube below the video and a front tube above it. The
progress sphere is drawn on its correct side of the star. When it is behind
the star, the front tube is clipped around its projected circle so the tube
cannot cover the visible sphere. The repair does not intentionally change
the star mesh, material, colour, or motion.

Visual checks on the iPhone 16 simulator:

- A 38 s loop recording was inspected across wraps; no blank or duplicate
  star was seen.
- A book-entry recording was inspected frame by frame: the orbit and star
  appear together.
- A full orbit recording was inspected for the sphere's front/back depth and
  overlap with the tube.

The signed Debug build was installed and launched on the user's connected
iPhone 18 Pro at the user's request. The user reported that it looks good.

The simulator checks establish visual behavior there. No new phone timing or
frame recording was taken during this repair.

## What was built

### Star (book home + colour page)

- `StarLoopView` replaces the old live `ObjetStarView`, which is deleted.
  - The star is an HEVC-with-alpha loop per palette:
    `Resources/StarVideos/star_{acide,iris,surimpression}.mov`, about 4 MB
    each, 900 px, 60 fps, 524 frames. That is half a turn, which loops
    seamlessly because the star is symmetric.
  - The orbit ring (live progress) is drawn in 2D with `Canvas` inside a
    `TimelineView`. Back half under the video, front half over it. The tube
    width follows perspective, with a soft gloss band and a bead with a
    highlight. The bob is a 2D offset.
  - Geometry numbers shared with the renderer: `StarVideoGeometry`.
- Players are shared per palette, prewarmed in `LibraryView.onAppear`, and
  paused while a page covers the book (`starLive` → `active`). Drag-to-turn
  was dropped; the user OK'd this.
- Generator: DEBUG-only `StarVideoRenderer` (`CB_RENDER_STAR=1`). See
  `tools/star_video/README.md`. The committed loops were rendered on the
  iPhone GPU.
- Known deviations from the old live star:
  - No start tilt that settles. The old star started tilted 0.35 rad and
    settled to 0.
  - The ring is 2D: the gloss is approximated and the bead highlight is
    fixed.
  - Ring spin phase follows the wall clock.

### Library ribbon

- `LibraryRibbonImage` / `LibraryRibbonRenderer` in `LibraryRibbon.swift`.
  The old scene is rendered once per (geometry, palette, scale) with
  `RealityRenderer` and shown as an image. There is no sway now; the user
  asked for this. `LibraryRibbonMotion` and `ribbonLive` are gone.
- The environment light is set to `intensityExponent` 1.4, matched to the
  live view's brightness on the simulator. The lime is slightly less
  saturated than before, and the folds are flatter because the still shows
  the rest pose, not mid-sway.
- When a picture is already shown, a re-render (new data or a new palette)
  waits 450 ms so it never lands mid-slide.
- Checked on the simulator: the ribbon is present on every library frame of
  a full tour. **Not checked on the phone.**

## Measurements (phone, one run, before the no-phone rule)

| switch | 3D star | video star |
|---|---|---|
| push_book | 170 ms | 81 ms |
| push_book2 (warm) | 109 ms | 53 ms |
| push_colors | 116 ms | 71 ms |
| pop_book | 75 ms | 110 ms (ribbon still live then) |

The cause, from the Time Profiler (`tools/perf/profile.py --burst`,
`gap.py`): every new RealityView pays its first-frame setup on the main
thread (render graph and targets), then blocks in
`RenderThread::waitForFramePacing`. Our Swift code was about 20 ms of it.
RealityKit has no pause API.

The still-ribbon effect on pops has not been measured.

## Tools

- `tools/perf/apply_hooks.py` and `apply_hooks.py --revert`. Revert undoes
  only the hooks and keeps other uncommitted work.
- Simulator runs: Release build with
  `SWIFT_ACTIVE_COMPILATION_CONDITIONS=PERF_HARNESS CODE_SIGNING_ALLOWED=NO`,
  launch with `SIMCTL_CHILD_CB_PERF=1`, record with
  `xcrun simctl io <sim> recordVideo`. Simulator timing is not phone timing;
  use it for correctness and visuals only.
- A full-screen star test screen with fixed numbers (76 % / 5 %, Iris) was
  used. It was a temporary RootView patch and is not committed; re-add it
  behind `#if PERF_HARNESS` if needed.
- Frame tools used this session (scratchpad, not committed): `sheet.swift`
  (contact sheets), `scan.swift` (per-frame dark-pixel jumps). The scan
  misses light-coloured problems such as this bug.

## Other follow-ups

1. Phone timing for the video star + still ribbon was not measured after this
   repair.
2. 120 Hz (`carambole-Info.plist`) was never A/B tested.
3. Today's token pile (`TokenPileScene`) is still a live RealityView.
4. `LoopWaveText` re-lays out every letter every frame; it is expensive.
5. The current signed Debug build is installed on the iPhone. Older generator
   files in its Documents folder were not inspected or removed. Use the phone
   again only if the user asks.
