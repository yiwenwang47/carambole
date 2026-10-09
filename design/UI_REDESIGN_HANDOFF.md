# Carambole UI redesign handoff

*Updated 2026-10-09, end of session 4. Start here.*

## TL;DR for the next session

The redesign is **merged to `main` and pushed** (session 4). Every screen is
built in the "objets + mouvement" language, with **colour**: three palettes the
learner picks under the library's `Couleurs →` page (Acide default, Iris,
Surimpression) and two drill styles (Plateau default, Cadres). Hard colour
rules from the user: white ground, ink text, colour on objects; any button or
large fill uses pale, saturation-capped colour; dark buttons are grey
(`AppColor.buttonDark`), never black. Design references:
`design/motion.html` (objects), `design/palettes.html`, `design/drill-colour.html`.

Still open (user did not ask for these yet): confirm on device that the Today
drop no longer stutters after `fait`; Iris star has no true iridescence (needs
the Metal toolchain for a CustomMaterial shader, ask before installing); Today
pile with ~40 tokens covers the title (could cap lower); 3D star and the open
book's ribbon link are still full-strength colour (user may want them paler);
T9 cleanup (dead `CaramboleStarMesh` glass/paper slice materials,
`DesignGalleryView`, unused `success`/`error` colours) and deleting the merged
`ui-t*` branches.

## Session 4 (2026-10-09): colour palettes, drill styles, merge

- Palette study: `design/palettes.html` (artifact https://claude.ai/artifact/RLB68X8GYpdZgQErLeaFCZ).
  Round 1 copied moodboard hexes onto flat SVG objects: rejected ("followed the
  examples too strictly"; star "looks weird"). Round 2+ derived palettes from
  lessons (colour as material, one loud + one quiet, black does the drawing,
  overprint) on the real three.js star + a line-for-line port of
  `LibraryRibbon.swift` with real data. Kept: **Acide** (lime + more sky),
  **Iris** (pearl star + lilac + more pistachio, star made lighter),
  **Surimpression** (softened pink/blue, multiply overlaps). Outremer dropped.
- Built in Swift, user picks: `DesignSystem/Theme.swift` (`AppPalette`,
  `AppTheme`, UserDefaults `carambole.palette`, default Acide);
  `Features/Settings/ColorSettingsView.swift` (live star preview + 3 rows),
  opened from the library's `Couleurs →` label (top right). Colour reaches: star
  body/ring/bead (`ObjetStarController.setPalette`), ribbon paper (front/back,
  to-come), Today pills (+ multiply in Surimpression), placed/wrong magnets,
  `ProgressRing`, Today start-pill counts. `AppColor.paper` is now pure white.
- Iris has no real iridescence: RealityKit PBR has none, `sheen` tinted it olive,
  and a CustomMaterial shader needs the Metal toolchain (not installed; ask the
  user before `xcodebuild -downloadComponent MetalToolchain`).
- Today drop glitch after tapping `fait`: star RealityView now detaches while
  Today is pushed (`starLive`, controller re-attaches entities); drop waits
  0.4 s for the push; tokens spawn one per 30 ms; pill textures cached; walls
  rebuilt only on real size change; physics step capped at 1/40 s.
  Sim log check: no runaway tokens. User to confirm on device.
- Later in session 4: Surimpression roles swapped (blue loud, pink quiet);
  placed magnets use a much paler colour; RULE from the user: any coloured
  button or large fill is saturation-capped (`AppTheme.buttonFill/quietFill/
  tint`, HSL S ≤ 45 %, L ≥ 82 %) and dark buttons are grey `AppColor.buttonDark`
  (#3A3A3A), never black. Drill colour (`design/drill-colour.html`): user chose
  to build **Plateau (default)** and **Cadres**, picked under Couleurs →
  Exercices (`DrillStyle`, UserDefaults `carambole.drillStyle`). Plateau = pale
  lesson slab with the module number, pale tray under the word bank, round
  Indice/Écouter, pale filled buttons. Cadres = framed Indice/Écouter + answer
  well in the deep colour, dark buttons with a pale arrow disc
  (`DrillButtonStyle`). Deviation from mock: Plateau's Indice/Écouter stay in
  the prompt's assist row (not inside the tray). Installed on the phone.
- "Juste" after a correct answer was there but read as a relabelled Vérifier
  (same pale fill, 1 s). Now a white pill with a 2 pt deep-colour outline + ✓
  and a small pop (`CorrectPill` in DrillView); the Plateau tray no longer
  changes colour on a correct answer.
- Merged `ui-redesign` → `main` and pushed at the end of the session.

## Session 3 (2026-10-09): ribbon, star, Today, book home

Everything here is on the phone (iPhone 18 Pro) and committed.

| Commit | Change | User verdict |
|---|---|---|
| `ae3032e` | Ribbon link shape: 9 pt flat neck at the pinch, round `sin^0.8` shoulders over 20 % of the link, wide belly, two edges that wobble independently (seeded sines per book), spine drift so links lean. A book's 30-day total sets its belly on a scale shared by all books; daily data only changes the outline by about ±12 %. | "shape is ok now" |
| `9c32023` | Ribbon shading: 10-column mesh bowed across its width, analytic normals, key + fill lights, back paper `#8d8d8a`, roll inside each link, ±28 pt twist at each boundary. Books to come are opaque with more self-light (RealityKit's transparent blending rendered them unlit). | "good" |
| `311d343` | Wider links (started 82–103 pt, to come 68 pt; axis 84 pt from the right) and stronger shading (curl 0.6, roll 0.7, key 1000 / fill 120, no self-light on started books). | accepted |
| `7ae834c` | 01 star: hand-built `objetMesh` (three.js ExtrudeGeometry numbers: depth .34, bevel .14 × .1, 96 samples per lobe, 12 bevel rings, mitred sharp tips). RealityKit's chamfer had left sawtooth notches at the tips. About 10 % bigger than before, like the prototype. | not yet judged |
| `d2369a6` | Today (03) token drop: gravity 2200 pt/s² (was 1100), tokens enter at 900 pt/s downward; 20 tokens settle in about 1 s. `fait :` line bold ink. | not yet judged |
| `5be680b` | Book home: swipe-up removed; only the bottom line `25 modules →` opens the module list. `fait :` line Familjen 14/650 ink. | not yet judged |

Ribbon tuning knobs, all in `LibraryRibbon.swift`: `startedBase`/`startedGain`/
`toComeBelly` (width), `shoulder`/`neck`/`twistHalf` (pinch), `wobble` amps
(edge roughness), `roll`/`curl` + light intensities + `emissiveIntensity`
(shading). `_selfTest()` asserts the pinch, belly range, belly order and twist
count, so update it when you change the shape.

What the user did NOT want: grey-back "flipped" links (offered, not taken:
a whole grey link could look like a state); ribbons whose per-day data makes
jagged edges. Rejected ribbon attempts from session 2: tight coil
(`4b27242`), flat discs (`0822164`), jagged relative width (`f623437`), one
book per screen (`d0a2611`), almond links (`0c0bc40`).

**How to iterate on a 3D look (worked well in session 3):**
1. Prototype the shape in a small Python/matplotlib script with the same math
   and the user's real data (`design/phone-data/real-30d.json`); compare with
   the user's reference image side by side.
2. Port to Swift; render in the sim through a temporary `#if DEBUG`
   `Views/ZZHarness.swift` + a `RootView` hook on env `CB_SCREEN`
   (`SIMCTL_CHILD_CB_SCREEN=…`); tune lighting values in a loop (template file +
   `sed` + build + screenshot); crop and zoom screenshots to check edges.
3. Check the real screen (text overlap), delete the harness,
   `git checkout RootView.swift`, install on the phone, commit.
Mechanics to keep: ribbon RealityView inside the scroll content; orthographic
camera, `OrthographicCameraComponent.scale` = HALF extent (`W·k/2`);
k = 0.0076; sway only.

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

The ribbon was finished in session 3 (above). Also: `OrthographicCameraComponent.scale`
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
- Grayscale only; state by form (solid / outline / dashed). Colour = next session.
- The user tests on the **iPhone 18 Pro** (install every accepted change; see
  "Phone" above). The simulator (`7C7BA0A7-…`) is for screenshots before that.

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
- Session 3 changes not yet judged on the phone: star mesh, faster token drop
  (gravity also affects tilt/throw/Secouer), `25 modules →` tap only.
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
