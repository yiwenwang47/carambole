# Carambole UI redesign handoff

*Updated 2026-10-09. This replaces the earlier handoff, which covered only the rejected `ui-concepts.html` round.*

## Current status

**Design landed (2026-10-09). Next: build.** Approved: 01 Objet, 02 Cinétique, 03 Gravité, 05 Ruban, 06 Tranches, 07 Aimants. 04 Mobile dropped. The SwiftUI build plan, with a full inventory of current controls that must survive (Trop facile, Indice, Écouter, etc.), is `docs/plans/2026-10-09-ui-redesign-implementation.md`. Start there; build in a git worktree. Gravité placement is decided (the "Aujourd'hui" screen behind the book home's `fait :` line). The user tests on device after each screen.

## Artifacts (all in `design/`)

| File | Status | What it is |
|---|---|---|
| `motion.html` | **Current. 01, 02, 03, 05, 06, 07 approved; 04 dropped.** | Six live concepts, one phone screen each, grayscale. Uses Three.js 0.160 (jsdelivr importmap), Matter.js 0.19 (cdnjs) and canvas. Open it in a browser with a real GPU. |
| `renders/motion-round3.png` | Reference | Static capture of `motion.html` in its settled states. It was rendered headless with SwiftShader, so the chrome looks flatter than on a real GPU and the animations are frozen. |
| `layouts.html` | Rejected | Round 1 layout study (directions A, B and C, five screens each). Kept as a record of what didn't work. |
| `renders/layouts-round1-rejected.png` | Reference | Capture of the page above. |
| `ui-concepts.html` | Rejected | Pre-2026-10-09 rounds (heavy Archivo type, pastel palettes, overlapping covers, giant cropped type, faded logo). |

## Approved concepts (`motion.html`)

1. **01 · Objet (book home).** A chrome 3D carambole star, extruded from the logo geometry (`design/logo/README.md`: tips R=42, valleys r=17, one quadratic curve per lobe), turns slowly in the middle of the screen. The **progress ring is a 3D ring orbiting the star**: a faint full track, a dark 41% arc and a bead at the end of the arc. Small type sits at the screen edges, after IMG_0943: 41 %, 128/312, finish date, `8 Apprendre →` and `14 ← Réviser`. Drag to turn the star.
   *iOS:* RealityKit `RealityView` with a procedural extruded mesh and an environment-lit metal material (or SceneKit). No Blender needed.
2. **02 · Cinétique (module).** A weight wave runs through the title, using Manrope's variable `wght` axis (200–720). Below it, the rule conjugates itself on a rolling ticker: "je vais partir → tu vas partir → … → elles vont partir". The element list stays quiet underneath.
   *iOS:* `TimelineView(.animation)` setting per-letter weight with `Font.custom` and the `wght` variation, plus a vertical roll transition for the ticker.
3. **03 · Gravité (today).** Today's 22 elements are physical pill tokens that fall into a pile above the `Commencer` button: white for new, black for review, dashed for fragile. You can throw them, and `Secouer` tosses them. Intended behavior (not built yet): finishing a drill removes its token.
   *iOS:* SpriteKit `SpriteView` with physics bodies. CoreMotion tilt is optional.
4. **04 · Mobile (library). DROPPED 2026-10-09.** The user felt the Calder mobile/balance didn't fit a consistent theme and polishing it would take too long; it is removed from `motion.html`. The library screen has no concept now.
5. **05 · Ruban (history).** The user asked what the ribbon is for; it was decorative at first. Its role now is a **readable timeline**: a paper ribbon with the oldest day at the top and today at the bottom. **Width** = that day's learned + reviewed work. Each **rest day** is a full twist that pinches the ribbon and briefly shows its grey back. Moving the pointer or finger vertically scrubs through the days and shows a readout (`Jeu. 8 oct. · 8 appris · 21 révisés`, default today), with a marker bar on the ribbon. Dragging sideways turns it. It sways gently and does not spin, so it stays readable.
   *iOS:* a RealityKit procedural `MeshResource` (~2k vertices), a `DragGesture` mapped to a day index with a selection haptic per day, and a SwiftUI overlay for the readout.

Rejected 2026-10-09 ("just bad") and removed from the page: **Pli** (module leaflet unfolding in CSS 3D) and **Verre** (liquid-glass lens over a small table of contents). Replaced by two new concepts, approved 2026-10-09 after one revision (06 gaps widened + tap-to-open; 07 tiles kept level):

6. **06 · Tranches (book table of contents).** A carambole cut crosswise gives star slices, so the 25 modules are 25 thin star slices on a skewer, module 01 at the bottom. Mastered = chrome (same material as 01), in progress = white paper, to come = faint glass outline. Vertical drag maps the pointer onto the *closed* stack's screen extent (so fanning open never jitters the pick); the selected slice fans the stack open, slides out and spins; the readout shows number, title and ring. Tap (no drag) or `Ouvrir →` = open: the slice lifts toward the camera, tilts to face it and the rest of the stack hides (stand-in for a matched transition into the 02 module page). Proposed answer to open question 2: swiping up on the 01 book home splits the chrome star into these slices.
7. **07 · Aimants (drill).** Keeps the standard drill layout but the token bank becomes level word tiles on under-damped springs (one overshoot per snap). Correct → tiles weld into plain text, distractors fall off-screen, one 02-style weight wave. Wrong → the line shakes, wrong tiles turn dashed, the answer appears below. Proposed answer to open question 3.

Removed: **Trame**, a halftone dot-field history screen. See the hard constraint below.

## Hard constraints from the user

- **Trypophobia: never use dot fields, halftones, perforations, honeycomb, bubble clusters or dense small-circle patterns.** Single circles such as the progress ring are fine.
- Backgrounds stay light. **Keep the circular progress ring.** In code, `DesignSystem/ProgressRing.swift` currently appears only in the drill header. The approved concepts use it on the book home (as the 3D orbit ring) and on the module page.
- Ignore color palettes for now. All prototypes are grayscale on purpose; color comes later, when the user asks.
- Use grotesk type: Manrope (variable, light weights 200–400) for display and Familjen Grotesk for small uppercase labels. Archivo was rejected. The shortlist is in `../../curated_free_fonts.md`.
- The drill (exercise) screen can stay standardized: prompt, tools, answer, then a fixed button. Explore freely on the other screens.
- Show proposals as HTML before changing any SwiftUI code.

## What the user rejected, and why

- `ui-concepts.html` rounds: too bold, cheap and business-like. Pastel palettes were a distraction. Overlapping covers, giant cropped type and a faded logo were graphic devices copied literally from the references.
- `layouts.html` round 1, static editorial layouts: A (typeset prose) was "too crowded", B (Swiss poster grid) "feels like a calendar", C (bento board) "feels like tetris".
- What worked was the shift to **live objects, physics and kinetic type with sparse text**. The user asked for "real, avant-garde graphic design, interesting animations, objects". Round 2 was "much better than the previous versions".

## References

- `../../img/IMG_0940.PNG`: moodboard collage, including a chrome star object, which inspired the chrome carambole.
- `../../img/IMG_0941.PNG`: large light type with an inline image.
- `../../img/IMG_0942.PNG`: overprinted poster with numerals pinned to the edges.
- `../../img/IMG_0943.PNG`: a hanging acrylic keychain object against the sky, with small type placed around it. This inspired 01 (object centered, type at the edges) and the dropped 04 (hanging objects).

## Product surfaces (unchanged code)

- Library `carambole/Features/Library/LibraryView.swift`: no concept (04 Mobile dropped 2026-10-09; needs a new idea in the shared theme).
- Book home `carambole/Features/Book/BookView.swift` (+ `BookViewModel`, `ProgressEstimate`): target **01 Objet**. The current segmented bar would become the orbit ring. The 25-module table of contents still needs a home ("Glisser vers le haut · 25 modules" is a placeholder).
- Module `carambole/Features/Book/ModuleDetailView.swift`: target **02 Cinétique**. Keep swipe-to-demote on element rows.
- Today / session start: target **03 Gravité**. No dedicated screen exists yet. Today's counts currently live on the BookView buttons.
- History `carambole/Features/History/HistoryView.swift` (+ `HistoryViewModel.activities`): target **05 Ruban**. The data per day is already there (learned / reviewed).
- Drill `carambole/Features/Drill/DrillView.swift`: standardized, not redesigned yet.
- Tokens: `carambole/DesignSystem/DesignSystem.swift` (serif "Le Cahier" tokens) will need replacing with the grotesk tokens. Manrope and Familjen need bundling as app fonts (check their OFL licenses).

## Resolved questions (2026-10-09)

1. Flow: library (restyle only) → book home 01 → swipe up → Tranches 06 → tap slice → module page 02. 01's Apprendre/Réviser start sessions directly.
2. Table of contents: Tranches (06), behind the 01 book home.
3. Drill motion: Aimants (07), with every existing drill control kept.
4. Chrome on a real device: the user will check after the T5 build.
5. Color: still grayscale; comes back when the user asks.
6. Gravité: the "Aujourd'hui" screen behind the book home's `fait :` line.

Build plan: `docs/plans/2026-10-09-ui-redesign-implementation.md`.

## Verification notes / gotchas

- Headless Chrome (`--use-angle=swiftshader`) runs only a few animation frames. To capture settled states, pre-step the physics (`Engine.update` in a loop) in a scratch copy. Never edit `motion.html` for this.
- `motion.html` respects `prefers-reduced-motion`. Keep that behavior in SwiftUI (`@Environment(\.accessibilityReduceMotion)`).
- Ribbon geometry: the width direction is taken from the projection of world Z perpendicular to the tangent, not from Frenet frames, which flip and crumple. Rest days add a **2π** twist; π leaves the grey back showing until the next pause.
