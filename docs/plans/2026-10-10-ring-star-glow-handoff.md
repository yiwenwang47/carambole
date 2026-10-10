# Handoff — ribbon launch twist, ring seam, star glow, push overlap (2026-10-10)

State: **all fixed on the simulator, uncommitted on `main`, installed on the
user's iPhone 18 Pro (Debug build, signed).** The user will check it on the
phone in a new session. If they're happy, commit (see the last section).

## 1. Library ribbon twisted a little on launch

- **Cause:** the ribbon is a still image drawn from `HistoryViewModel.days`.
  `days` started as `[]` and loaded async, so launch drew two different
  pictures (empty, then real data). The second was swapped in 450 ms later
  and the wider belly looked like a twist.
- **Fix:** `HistoryViewModel(loadImmediately: true)` (used only by
  `LibraryView`) fetches synchronously in `init`. The later async `load()`
  publishes equal data, so the key stays the same and nothing re-renders.
  Files: `Features/History/HistoryView.swift`, `Features/Library/LibraryView.swift`.
- **Verified:** sim launch recorded at 10 fps. The ribbon appears with the
  page and no pixel changes from 3.4 s to 8.8 s.
- **Cost:** `ContentLoader.loadBook()` (25 JSONs) plus two SQLite reads now
  run on the main thread before the first frame. Not measured. If the user
  reports slower launch, cache the book or store only the 30-day window.

## 2. Break in the orbit tube (circled in the user's screenshot)

The ring is drawn in two `Canvas`es: the back half under the star video, the
front half over it. The break was at the ring's left/right sides, where the
two halves meet (z = 0). Frame zooms turned up three separate causes, all
fixed in `Features/Book/StarLoopView.swift` (`OrbitRing`):

1. **Gloss streak jumped sides.** It was shifted straight up on screen, which
   runs *along* the tube where the tube is vertical, so the streak folded
   over itself. Now it shifts across the tube by only the upward part of
   the shift (`band`).
2. **Each tube switched halves at its own grid step**, so the pale tube under
   the arc peeked out as a dash. Now every tube is cut at the exact angles
   where the ring crosses z = 0 (`crossings`), with exact tangents, and has
   samples at ±`seamPad`. The front half overlaps the back by that one step.
3. **A pale 1-px line.** The full-ring track and the arc above it ended on
   the same seam edge. Their stacked antialiased edges let the track colour
   leak through. Now the track's overlap is shorter (`seamPad: 0.01` vs
   0.02), so its edge sits inside the arc's body.

Dead ends, not shipped: fading the gloss at the crossings (it was not the
cause, and it cost an offscreen layer each frame); drawing the track only on
the rest of the ring (its square end then showed over the arc's round cap
when the arc ended near a crossing).

- **Verified:** 20–30 s sim recordings with the demo seed. 1-px bright-line
  detector plus zoomed crops of both sides: clean in every frame (the few
  remaining detector hits are ordinary tube edges, inspected by eye).

## 3. Star had a very thin glow round its edges

- **Cause (measured):** RealityKit renders into `.bgra8Unorm_srgb` with
  alpha premultiplied in **linear** light. The video was tagged as
  premultiplied in sRGB space, so the compositor added too much colour at
  soft edges. In all three committed loops ~50–60 % of edge pixels had
  colour > alpha (by up to 87/255). Example: an edge pixel at α 0.5 composited
  as (218,238,160) instead of ≈ (150,163,111), which matches its opaque
  neighbour.
- **Fix:**
  - New `DesignSystem/SRGBPremultiply.swift`: a lookup-table conversion,
    applied in place.
  - `StarVideoRenderer` now applies it to every frame, so future renders are
    correct.
  - `LibraryRibbonRenderer` applies it too, because it had the same fault.
  - The committed loops were **fixed on the Mac, not re-rendered**, which
    keeps the iPhone-GPU look. Tool: `tools/star_video/fix_premultiply/main.swift`
    (decode → fix → re-encode, same settings). README updated. Never run it
    on loops that are already fixed.
- **Verified:**
  - Fixed loops: colour > alpha dropped to 0–14 pixels (≤ 6/255, compression
    noise).
  - 524 frames and 8.733 s, same as before.
  - Opaque interior: mean diff 0.1–1/255 against the originals.
  - Frame 0 composited over white, old vs new zoom: old has a pale fringe on
    dark edges, new blends cleanly.
  - Sim book page: no fringe.
- **Open:** the ribbon's fix loops over every pixel of a ~1206×2800 image on
  the main actor. Fine in Release. In Debug it may add tens of ms to the
  ribbon render; not measured. Easy follow-up: run it off-main before
  building the `CGImage`.

## 4. Opening the book: orbit showed before the star / overlapped it

- **Cause (seen in 60 fps frames):** BookView fades the page in
  (`.opacity(revealed ? 1 : 0)`). SwiftUI applies a container's opacity to
  each layer separately. Mid-fade the star video was see-through, so the
  back half of the ring showed through it and the ring read first.
- **Fix:** `.compositingGroup()` before the `.opacity` in `StarLoopView`. The
  star + ring now fade as one flattened layer.
- **Verified:** sim push recorded at 60 fps. Mid-fade the star stays opaque
  over the ring, and both arrive together.
- **Not checked:** the phone. The video layer's first-frame timing on device
  can differ from the sim (`isReadyForDisplay` → the poster cover hides).
  If the user still sees the ring alone for a frame on the phone, look at
  `StarVideoLayer`: the cover is hidden as soon as `isReadyForDisplay` is
  true, and the layer may not have drawn yet.

## For the next session

1. Ask the user what they saw on the phone for all four items.
2. If good, commit as separate commits:
   - `fix: library ribbon drawn once on launch`
   - `fix: orbit tube seam at the ring's sides`
   - `fix: star and ribbon edge glow (sRGB premultiplied alpha)`, including
     the three `.mov` files, the tool and the README
   - `fix: star and orbit fade in as one layer`
3. Update the CLAUDE.md "RECENT HANDOFFS" block.

Files touched: `Features/Book/StarLoopView.swift`,
`Features/Book/StarVideoRenderer.swift`, `Features/History/HistoryView.swift`,
`Features/Library/LibraryRibbon.swift`, `Features/Library/LibraryView.swift`,
`DesignSystem/SRGBPremultiply.swift` (new), `Resources/StarVideos/star_*.mov`,
`tools/star_video/README.md`, `tools/star_video/fix_premultiply/main.swift`
(new), this file.
