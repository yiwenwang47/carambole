# Carambole UI redesign handoff

*Updated 2026-10-09, end of session 2. Start here.*

## TL;DR for the next session

Branch **`ui-redesign`** (worktree `../carambole-ui-redesign`, NOT merged, not
pushed; head `0c0bc40` + this doc). Every screen is built. **One open problem:
the library ribbon's SHAPE (08). The user hates the current one.** Fix that
first, with the user, on their phone. Then fine-tune the other screens, then T9
cleanup and merge.

### ▶ The ribbon problem (read all of this before touching it)

**What the user wants (their words, in order):**
1. "the ruban look from the artifact": the soft, organic paper ribbon.
2. A reference screenshot they sent: the **old 05 history ribbon**
   (perspective camera, ~550 pt tall for 30 days, large soft blobs of paper
   divided by small twisted pinches, a gentle S drift, one blob flashing its grey back).
   Source: `git show main:design/motion.html` → `<!-- 05 · ribbon history -->`
   script (line ~424), and the deleted Swift port:
   `git show 48ee276:carambole/Features/History/RibbonView.swift`.
3. **"One link per book! at least 3 books should fit in one page!"** Each
   book = ONE link of the chain (like one 05 blob), and ≥ 3 books per screen.
4. Verdict on the current build (`0c0bc40`, one link per book): "shape is
   terrible". The user did not say why. **Ask, or show 2–3 options, before
   coding.** Likely suspects: the `sin(πt)^0.7` envelope makes leaf or almond
   shapes (pointed ends, see the sim screenshot); the books-to-come links are
   long thin needles; there's no S drift and no grey-back flash, so it doesn't
   read like 05's paper.

**What was tried and rejected (don't repeat):**
| Version | Commit | Why rejected |
|---|---|---|
| Prototype exact: 200 pt/book, width `0.05+0.4·v/30`, 2π twist per rest day | `4b27242`, `4bec50b` | Sim with sparse data: a tight coil. "too twisted" |
| One twist per run of rest days + `0.16+0.45·√(v/30)` | `0822164` | On the phone with real data (days of 64 to 80): flat **discs**, "nowhere close" |
| Relative width `0.05+0.32·v/max` | `f623437` | Edges jagged at ~7 pt/day. "creepy as fuck" |
| 560 pt per started book + 05 width `0.04+0.5·v/max` | `d0a2611` | Soft, but only 1 book per screen. "NOOO" |
| One link per book: 200 pt, Gaussian-smoothed days, `sin(πt)^0.7` envelope, twist only at boundaries | `0c0bc40` (current) | "shape is fucking terrible" |

**Key insight:** at 200 pt per book, 30 days is about 7 pt per day, too short
to show each day's width without jagged edges. 05 looked good at about 18 pt
per day. Inside one link you can't show 30 separate days. Show a smooth,
data-tinted shape, or drop per-day data from the shape entirely; ask the user.

**Real data (use it, the sim is nearly empty):**
`design/phone-data/real-30d.json` (git-ignored; also the raw DB
`design/phone-data/carambole.sqlite`, pulled from the phone). Last 30 days total =
`[0,0,0,0,0,0,10,11,0,8,30,0,0,0,0,0,0,0,64,0,0,0,8,0,76,0,45,73,80,0]`.
Sparse, bursty, many rest days. Every candidate must be rendered with THIS
data and shown to the user **before** installing.

**How to iterate on it (fast loop that worked):**
- Shape code: `carambole/Features/Library/LibraryRibbon.swift`
  (`LibraryRibbonGeometry`: `width(at:)`, `twist(at:)`, `spine`, `envelope`,
  `smooth`; + `_selfTest()` wired in `caramboleApp.swift`. Update it with the
  shape, since a failing assert kills the app at launch). Layout: `LibraryView.swift`.
- Temp harness: `carambole/Views/ZZHarness.swift` rendering
  `LibraryRibbonScene(geometry: LibraryRibbonGeometry(stretches: [.started(REAL), .toCome, .toCome], viewWidth:))`
  in a `ScrollView`, + `RootView` hook on env `CB_SCREEN`; launch with
  `SIMCTL_CHILD_CB_SCREEN=x`; screenshot with `simctl io … screenshot`. Delete +
  `git checkout RootView.swift` before committing.
- Best: prototype shapes as an HTML/three.js mock first (the user prefers
  judging HTML mocks before SwiftUI) and let them pick.
- Mechanics that ARE right and should stay: ribbon RealityView inside the
  scroll content; orthographic camera, `OrthographicCameraComponent.scale` =
  HALF extent (`W·k/2`); k = 0.0076; two-sided paper + edge tubes; sway only.

### Other session-2 facts
- **Star load fix (keep):** the ribbon RealityView is removed while a book is
  pushed (`ribbonLive` in `LibraryView`); left alive it delayed the 01 star's
  first frame ~5 s. User said "star still fails to load" after the fix, but the
  sim log showed the star built 0.2 s after their tap. Unconfirmed on the
  phone; ask.
- **Phone:** the user now tests on an **iPhone 18 Pro**,
  UDID `00008160-001A09920AA0000A` (CLAUDE.md lists an old iPhone 16). Install:
  ```bash
  xcodebuild -project carambole.xcodeproj -scheme carambole \
    -destination 'id=00008160-001A09920AA0000A' -allowProvisioningUpdates \
    DEVELOPMENT_TEAM=QMV4SPL476 -derivedDataPath /tmp/cb-device-ui build -quiet
  xcrun devicectl device install app --device 00008160-001A09920AA0000A \
    /tmp/cb-device-ui/Build/Products/Debug-iphoneos/carambole.app
  xcrun devicectl device process launch --terminate-existing \
    --device 00008160-001A09920AA0000A wen.carambole   # fails if phone locked
  ```
  Pull the DB: `xcrun devicectl device copy from --device <udid>
  --domain-type appDataContainer --domain-identifier wen.carambole
  --source Documents/carambole.sqlite --destination <file>`.
- 09 History list is built and was not complained about.

### Lessons (session 2)
- Never deviate from the approved mock silently: two of the rejections came
  from "improvements" I made without asking.
- The sim has almost no data, so it can't judge a data-driven shape. Use the
  phone's real data.
- When the user asks for a "look", show a side-by-side render against their
  reference before shipping to the phone. Five round-trips to the phone burned
  their patience.

Design source of truth: **`design/motion.html`** in the `ui-redesign` worktree
(the copy on `main` is older — it still has 05/06 and no 08/09). Open it in a
real browser. Concepts on the page now: **01 Objet, 02 Cinétique, 03 Gravité,
07 Aimants, 08 Ruban (library), 09 Liste (history)**.

## What is built (all on `ui-redesign`, build EXIT 0)

| Screen | Concept | Files | State |
|---|---|---|---|
| Tokens/fonts | — | `DesignSystem/DesignSystem.swift` (grayscale `AppColor`, `Font.display(size:wght:)`, `Font.label`, `.uppercaseLabel(color)`), `Resources/Fonts/` (Manrope + Familjen variable TTF + OFL), `PrimaryButtonStyle` (54pt black pill), `ProgressRing` (ink/g3), `WaveText` (one-shot wght wave), `LoopWaveText` (02 continuous wave) | done |
| Drill | 07 Aimants | `Features/Drill/MagnetBoard.swift` (tiles, matchedGeometry by bank index, weld + wave, shake + dashed, `FlowLayout`), `TokenBuilderView`/`ChoiceView` (thin wrappers), `TypeAnswerView`, `DrillView`, `DrillSessionView` (top bar ✕ · ‹ label › · ring) | done, user has seen it |
| Book home | 01 Objet | `Features/Book/BookView.swift`, `ObjetStarView.swift`, `DesignSystem/CaramboleStarMesh.swift` (RealityKit extruded star, orbit-ring meshes, studio IBL) | done; bottom line `25 modules →` (17pt) is the ONLY way to the module list — swipe-up removed at user request (2026-10-09); `fait :` line Familjen 14/650 ink |
| Module list | (replaces dropped 06 Tranches) | `Features/Book/ModuleListView.swift` — numbered rows, status `x / 20` · `Maîtrisé` · `Verrouillé`; pushed from the book-home bottom line only | done |
| Module page | 02 Cinétique | `Features/Book/ModuleDetailView.swift` (signature `ModuleDetailView(module:viewModel:)` kept) | done |
| Today | 03 Gravité | `Features/Today/TodayView.swift`, `TokenPileScene.swift` (SpriteKit) — opened from book home `fait : … →` | done |
| History | 09 Liste | `Features/History/HistoryView.swift` (3D ribbon removed; `RibbonView.swift` deleted) | done (session 2) |
| Library | 08 Ruban | `Features/Library/LibraryView.swift`, `LibraryRibbon.swift` (ortho RealityView inside the scroll content, self-tested geometry) | **built, ribbon SHAPE rejected — see TL;DR** |
| Settings | — | `Features/Settings/SettingsView.swift` (edge-type restyle, `− 12 +` steppers) | done |

Navigation now: Library → Fondations → book home (01).
From 01: `Apprendre →` / `← Réviser` start sessions · `Réglages` sheet ·
`fait : … →` → Aujourd'hui (03) → `Historique →` → History · bottom line
`25 modules →` → module list → row → Cinétique (02) → `Apprendre` pill.

Every control in the plan's inventory survived (Trop facile + pending/Annuler,
Indice, Écouter, auto-speak, chevrons, carousel swipe, compact mode, review mode,
undo toast, intro/completion, round size `Tour · 20`, fragile chip,
swipe-to-demote, export, steppers, toggle). Per-screen deviations are listed in
the subagent reports summarized in git commit bodies.

## Session 2 (2026-10-09): 08 + 09 built

See the TL;DR above for the ribbon. Also: `OrthographicCameraComponent.scale`
is the HALF extent. History footnote keeps the old wording (2 lines at
393 pt); list bottom inset 84 so it never overlaps.

## 08 · Ruban (library) — spec for the build

From `motion.html` 08 (see its markup + `<!-- 08 · library ribbon -->` script):

- Header: `Carambole` (lab ink, left) / `Bibliothèque` (lab, right) at top 66;
  big line `N livres` + grey `M ouverts` (40/250) at top 100.
- **One ribbon for all books**, running down the right side of the shelf
  (axis x ≈ 268 of 360, weave ±22, z-wobble ±0.3). Each book = one stretch of
  **200 pt**, starting at y 236. Book block on the left at stretch top + 34:
  `.lab` kicker (`01 · Grammaire A1 → B1`), title 32/250, then
  `Ouvrir →` (ink, underlined) + `41 %` for started books, `Bientôt` (g3 title)
  for books to come. `Fin de la bibliothèque` label at the end.
- Started book's stretch = its last 30 days (width = learned + reviewed on a
  SHARED scale across books `0.05 + 0.4·v/30` world units, eased between days;
  each rest day = full 2π twist). Books to come = narrow (0.12) faint strip
  (white 0.6 opacity, grey back 0.35, g2 edges). Full 2π twist at every book
  boundary. Started books sort first.
- **Ribbon lives INSIDE the scroll content** (as tall as the list), so the
  system scroll moves it — no JS/offset syncing (the first version synced via
  scroll offset and visibly lagged; the user flagged it). Orthographic camera,
  k = 0.0076 world/pt. Only animation: gentle sway `rotation.y = sin(t·.5)·.2`
  (none with Reduce Motion).
- iOS route: a `RealityView` (orthographic camera) as the background of the
  `ScrollView`'s content `VStack`, height = content height; reuse the
  width-direction / two-sided-paper mesh code from `Features/History/RibbonView.swift`.
  Data: per book, `HistoryViewModel.activities` scoped to that book (today only
  Fondations has content; Conversation / Intermédiaire are locked placeholders —
  keep them as "to come" stretches). Fondations row → `BookView(showBack: true)`
  as today.
- User asked "what if 10 books": the answer accepted was "the shelf just gets
  longer, every book same short stretch, started first". Open option if it looks
  busy: show last 14 days per book, or give started books a longer stretch.

## 09 · Liste (history) — spec for the build

From `motion.html` 09: `‹ Historique` / `30 jours`; totals 64/200 `appris` /
`révisés`; `Série N j` (lab ink, at top 214; streak helper already exists in
`HistoryView.swift` from the Ruban build — `HistoryViewModel.streak(...)` with a
self-test); ink rule at 252; one row per day newest first: date 15/400 left
(`Ven. 9 oct. · aujourd’hui`), `6 appris · 14 révisés` label right; rest days
grey with `Pause`; footnote label at bottom (`approximatives` note — keep the
existing wording/meaning). Nothing moves. Keep empty state "Pas encore
d'activité." and swipe-back. Remove the 3D ribbon from History (move the mesh
code to the library).

## Decisions made this session (don't re-ask)

- 04 Mobile dropped (earlier); **05 Ruban as history dropped → 09 list**;
  **06 Tranches dropped → plain module list** (`ModuleListView`); ribbon object
  moved to the library (08).
- Gravité stays behind the `fait :` line; History reached from Gravité's
  `Historique →`.
- Grayscale only; state by form (solid / outline / dashed). Colour later.
- Simulator, not device, for now: user tests on the **iPhone 16 (iOS 18.5)**
  simulator `7C7BA0A7-C367-4CD4-AAE5-462B1F754986`.

## How to run for the user (they asked for this repeatedly)

Xcode 27 has **no Simulator.app** — it's **DeviceHub**:
```bash
cd ../carambole-ui-redesign
xcodebuild build -project carambole.xcodeproj -scheme carambole \
  -destination 'id=7C7BA0A7-C367-4CD4-AAE5-462B1F754986' \
  -derivedDataPath /tmp/cb-ui-redesign -quiet CODE_SIGNING_ALLOWED=NO; echo EXIT $?
SIM=7C7BA0A7-C367-4CD4-AAE5-462B1F754986
xcrun simctl boot $SIM 2>/dev/null
xcrun simctl install $SIM /tmp/cb-ui-redesign/Build/Products/Debug-iphonesimulator/carambole.app
xcrun simctl terminate $SIM wen.carambole; xcrun simctl launch $SIM wen.carambole
open /Applications/Xcode.app/Contents/Applications/DeviceHub.app
```
Shut down any other booted sims first (`xcrun simctl list devices booted`) or
DeviceHub may show the wrong phone. Don't `simctl uninstall` unless needed — it
wipes the user's sim progress.

Screenshots without taps: temporary `#if DEBUG` env harness (`CB_SCREEN`) — a
`Views/ZZHarness.swift` + a `RootView` hook; launch with
`SIMCTL_CHILD_CB_SCREEN=<case>`; delete + `git checkout RootView.swift` before
committing. Headless Chrome for motion.html:
`"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new
--user-data-dir=<tmp> --use-angle=swiftshader --enable-unsafe-swiftshader
--window-size=1700,2000 --timeout=10000 --screenshot=<out> file://…/motion.html`
(wrap in `perl -e 'alarm 90; exec @ARGV'`; `--virtual-time-budget` hangs on the
rAF loops).

## Lessons from this session

- The user judges every screen directly against `motion.html`. When asked to
  "test in the simulator", say plainly which screens are built and which are
  still old; the user was (rightly) angry to open an unbuilt book home.
- The user prefers to see a proposal as an HTML mock in `motion.html` before
  SwiftUI (they chose this again for 08/09).
- Parallel subagents worked well with one git worktree + one simulator + one
  DerivedData path each, and a shared brief.

## Still open / unverified

- No gesture was ever tapped (automation can't tap): star drag/inertia,
  magnets spring/weld/shake, Gravité throw/Secouer/tilt, swipe-to-demote,
  ticker, edge swipe-backs. The user is testing these by hand.
- Chrome star looks flat mid-grey in the simulator (`intensityExponent` in
  `ObjetStarView`); judge on a real device later.
- **T9 cleanup** (after 08/09 + fine-tuning): remove dead code —
  `RibbonView` from History once moved, `CaramboleStarMesh` glass/paper slice
  materials left from Tranches, `DesignGalleryView` sanity, any `success`/`error`
  colour uses; update `CLAUDE.md` design-system pointer; then merge
  `ui-redesign` → `main` (user decides merge/PR/push).
- Leftover branches `ui-t3-ruban`, `ui-t4-cinetique`, `ui-t5-objet`,
  `ui-t7-gravite`, `ui-t8-restyle` are merged into `ui-redesign`; delete them at
  merge time.

## Hard constraints from the user (unchanged)

- **Trypophobia: never dot fields, halftones, perforations, honeycomb, bubble
  clusters, dense small circles.** Single circles (ring, bead) are fine.
- Light backgrounds; keep the circular progress ring; grayscale for now.
- Grotesk type: Manrope (display, light weights) + Familjen Grotesk (labels).
- Objects + motion + sparse text; static editorial layouts were rejected.

## References

- `../../img/IMG_0940–0943.PNG`: moodboard (chrome star, edge type around an object).
- Build plan + control inventory: `docs/plans/2026-10-09-ui-redesign-implementation.md`.
