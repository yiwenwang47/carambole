# Carambole UI redesign handoff

*Updated 2026-10-09 (end of the first build session). Start here.*

## TL;DR for the next session

Branch **`ui-redesign`** (worktree `../carambole-ui-redesign`, NOT merged to
`main`, not pushed) has the redesign built for every screen except two that the
user re-designed at the end of the session. Next session:

1. **Build 08 · Ruban → the library** (`Features/Library/LibraryView.swift`).
2. **Build 09 · Liste → History** (`Features/History/HistoryView.swift`, replacing
   the 3D ribbon page with a minimal list).
3. Then the user fine-tunes screen by screen in the simulator.
4. Then T9 cleanup + merge (see bottom).

Design source of truth: **`design/motion.html`** in the `ui-redesign` worktree
(the copy on `main` is older — it still has 05/06 and no 08/09). Open it in a
real browser. Concepts on the page now: **01 Objet, 02 Cinétique, 03 Gravité,
07 Aimants, 08 Ruban (library), 09 Liste (history)**.

## What is built (all on `ui-redesign`, build EXIT 0)

| Screen | Concept | Files | State |
|---|---|---|---|
| Tokens/fonts | — | `DesignSystem/DesignSystem.swift` (grayscale `AppColor`, `Font.display(size:wght:)`, `Font.label`, `.uppercaseLabel(color)`), `Resources/Fonts/` (Manrope + Familjen variable TTF + OFL), `PrimaryButtonStyle` (54pt black pill), `ProgressRing` (ink/g3), `WaveText` (one-shot wght wave), `LoopWaveText` (02 continuous wave) | done |
| Drill | 07 Aimants | `Features/Drill/MagnetBoard.swift` (tiles, matchedGeometry by bank index, weld + wave, shake + dashed, `FlowLayout`), `TokenBuilderView`/`ChoiceView` (thin wrappers), `TypeAnswerView`, `DrillView`, `DrillSessionView` (top bar ✕ · ‹ label › · ring) | done, user has seen it |
| Book home | 01 Objet | `Features/Book/BookView.swift`, `ObjetStarView.swift`, `DesignSystem/CaramboleStarMesh.swift` (RealityKit extruded star, orbit-ring meshes, studio IBL) | done; bottom line `Glisser vers le haut · 25 modules ↑` enlarged to 17pt at user request |
| Module list | (replaces dropped 06 Tranches) | `Features/Book/ModuleListView.swift` — numbered rows, status `x / 20` · `Maîtrisé` · `Verrouillé`; pushed from book-home bottom line / swipe up | done |
| Module page | 02 Cinétique | `Features/Book/ModuleDetailView.swift` (signature `ModuleDetailView(module:viewModel:)` kept) | done |
| Today | 03 Gravité | `Features/Today/TodayView.swift`, `TokenPileScene.swift` (SpriteKit) — opened from book home `fait : … →` | done |
| History | 05 Ruban (3D) | `Features/History/HistoryView.swift`, `RibbonView.swift` | **built but to be replaced by 09** — reuse `RibbonView`'s mesh code for 08 |
| Library | — | `Features/Library/LibraryView.swift` (edge-type restyle) | **to be replaced by 08** |
| Settings | — | `Features/Settings/SettingsView.swift` (edge-type restyle, `− 12 +` steppers) | done |

Navigation now: Library → Fondations → book home (01).
From 01: `Apprendre →` / `← Réviser` start sessions · `Réglages` sheet ·
`fait : … →` → Aujourd'hui (03) → `Historique →` → History · bottom line /
swipe up → module list → row → Cinétique (02) → `Apprendre` pill.

Every control in the plan's inventory survived (Trop facile + pending/Annuler,
Indice, Écouter, auto-speak, chevrons, carousel swipe, compact mode, review mode,
undo toast, intro/completion, round size `Tour · 20`, fragile chip,
swipe-to-demote, export, steppers, toggle). Per-screen deviations are listed in
the subagent reports summarized in git commit bodies.

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

- No gesture was ever tapped (automation can't tap): star drag/inertia, swipe-up,
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
