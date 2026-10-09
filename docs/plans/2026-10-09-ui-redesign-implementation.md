# UI redesign — SwiftUI implementation plan

*Written 2026-10-09. Read this first in the build session. The design source is
`design/motion.html` (open it in a browser) and the design history is
`design/UI_REDESIGN_HANDOFF.md`.*

## Goal

Move the app from the serif "Le Cahier" look to the approved **objects + motion**
direction: grotesk type, grayscale, live 3D objects and physics, sparse text.
**Every feature and control in the current app must survive.** The redesign
changes where controls sit and how they look, never whether they exist. The
user tests on device after each screen lands.

## Approved screens → app surfaces

| Concept in `motion.html` | Replaces | File(s) |
|---|---|---|
| 07 **Aimants** (word magnets) | drill input + chrome | `Features/Drill/*` |
| 05 **Ruban** (ribbon timeline) | History list | `Features/History/HistoryView.swift` |
| 02 **Cinétique** (kinetic module page) | `ModuleDetailView` + row-tap learn | `Features/Book/ModuleDetailView.swift` |
| 01 **Objet** (chrome star + orbit ring) | book home | `Features/Book/BookView.swift` |
| 06 **Tranches** (25 star slices) | module list on book home | new `Features/Book/SliceStackView.swift` |
| 03 **Gravité** (token pile) | "Aujourd'hui" screen behind the `fait :` line | new `Features/Today/TodayView.swift` |
| — (04 Mobile dropped) | Library: restyle only | `Features/Library/LibraryView.swift` |
| — | Settings: restyle only | `Features/Settings/SettingsView.swift` |

## Controls that must survive (inventory of the current UI)

Check this list off in each task's review. "Where" is the new home.

**Drill (`DrillSessionView` / `DrillView` / input views)**
| Control | Today | Where in the redesign |
|---|---|---|
| Exit ✕ (mid-session, keeps progress) | `DrillSessionView.exitBar` | top-left `✕`, as in 07 |
| Progress ring | `DrillView.header` | top-right ring, as in 07 |
| Back / forward chevrons (read-only revisit) | `DrillView.header` `navChevron` | keep beside the header label (`‹` / `›`) |
| Horizontal card swipe (carousel) | `DrillSessionView.dragGesture` | unchanged |
| Cue line | `promptBlock` | small label above the prompt |
| Always-on English translation | `promptBlock` | quiet line under the prompt |
| **Indice** (tap to reveal hint) | `assistRow.indiceButton` | assist row under the prompt, label style |
| **Écouter** (audio, `Speaker.shared.speak`) | `assistRow.listenButton` | assist row, same line as Indice |
| Auto-speak after answer (`settings.autoSpeak`) | `check()` | unchanged |
| Compact mode (<540pt: hide cue/translation/assists) | `contentStack(compact:)` | unchanged logic |
| Build-from-tokens input (duplicate-token safe, `displayBank` order) | `TokenBuilderView` | **07 magnets** (level tiles, springs) |
| Multiple choice | `ChoiceView` | same level tiles; tap springs the choice onto the line |
| Typed answer (`freeText`, keyboard Done) | `TypeAnswerView` | unchanged behavior, grotesk styling, underline field on the 07 baseline |
| **Vérifier → Suivant** fixed button | `actionButton` | fixed pill at the bottom, as in 07 |
| Correct: confirmation + auto-advance | `correctConfirmation` | weld + one `wght` wave, then auto-advance (lengthen the delay to ~0.9 s so the wave finishes) |
| Wrong: correct answer above Suivant | `correctAnswerHint` | "Réponse : …" under the baseline, wrong tiles dashed, line shakes |
| Review mode: Votre réponse / Réponse / explanation (bounded 220pt scroll) | `submittedAnswerBlock`, `reviewResultBlock` | unchanged content, restyled |
| **Trop facile — retirer** / pending state "Réponds correctement pour le retirer" / Annuler | `tooEasyControl` | small label button above the fixed button (left-aligned), same states |
| "Marqué trop facile" undo toast + Annuler | `DrillSessionView.tooEasyUndoToast` | unchanged, restyled pill |
| Leçon intro card + Commencer | `introCard` | restyle: big light title, ruleNote, black pill |
| Completion summary + Terminer | `completionSummary` | restyle; optional: score numeral with `wght` wave |

**Book home (`BookView`)**
| Control | Where in 01 |
|---|---|
| Back to library `‹` (+ swipe-back) | top-left `‹ Fondations` |
| Settings gear → `SettingsView` sheet | top-right `Réglages` |
| % mastered + segmented bar + legend | `41 %` numeral + `128 / 312 maîtrisés`; the **orbit ring** is the bar (see T5 for segments) |
| Estimate line (3 states: done / estimate / "Continue quelques jours…") | top-right `Fin ~22 déc.`; early state shows `Fin —` with the long text in accessibility label |
| Fragile chip → starts Réviser | under `41 %`: `3 fragiles · à réviser` label (dashed underline) |
| **Apprendre** (newest unlocked module) with count | bottom-left `8 / Apprendre →` |
| **Réviser** with count | bottom-right `14 / ← Réviser` |
| Round-size selector 10·20·50 | small label under Réviser: `Tour · 20`, tap cycles 10 → 20 → 50 |
| "fait : N appris · M révisés" → History | label line above the divider, with `→`; opens **Gravité**, which links on to History |
| Module list (25 rows, locked state, mastered x/20) | swipe up / `25 modules ↑` → **Tranches** |
| ⓘ module detail | tap a slice → **Module page (02)** |

**Module detail (`ModuleDetailView`)** — element list with buckets (maîtrisé / fragile / en cours / à venir) and swipe-to-demote **Remettre en cours**. Keep both inside the 02 page (T4). Add the module's **Apprendre** button there (replaces "tap row to learn").

**History** — per-day learned/reviewed, "approximatives" footnote, empty state "Pas encore d'activité." Keep all (T3).

**Settings** — Éléments / jour stepper, Objectif de révision stepper, Lecture audio automatique toggle, Exporter ma progression (share sheet), Fermer. Restyle only (T8).

**Library** — book list, locked "Bientôt" books. Restyle only (T8).

## Decisions taken (defaults; the user can override after testing)

1. **Palette:** grayscale, as in the prototypes. Map the existing `AppColor` names to
   new values so every screen moves at once: `paper #F8F7F4`, `ink #141414`,
   `graphite #4A4A4A`, `hairline #E6E5E1`, add `g2 #8D8D8A`, `g3 #C8C7C3`.
   `saffron`/`saffronDeep` → ink tones. State is carried by **form**, not hue:
   solid = mastered/review, white/outline = new/in progress, **dashed** = fragile
   or wrong. Keep `success`/`error` defined but stop using them in redesigned
   screens. Color returns later, when the user asks (logo orange `#F26A1B`).
2. **Fonts:** Manrope (variable, display, weights 200–400 mostly) and Familjen
   Grotesk (small uppercase labels, tracking ~0.12em). Both OFL — include the
   license files. Register at launch with `CTFontManagerRegisterFontsForURL`
   (the project uses `GENERATE_INFOPLIST_FILE`, so avoid `UIAppFonts`/pbxproj
   edits). Variable weight: build `UIFont` from a descriptor with
   `kCTFontVariationAttribute` `[0x77676874 /* 'wght' */: value]` and wrap it in
   `Font(uiFont)`; expose `Font.display(size:wght:)` and `Font.label(size:)`.
3. **3D:** RealityKit `RealityView` (deployment target is iOS 18.5). Star =
   `MeshResource(extruding: Path, extrusionOptions:)` from the logo path (tips
   R=42, valleys r=17, one quadratic per lobe, `design/logo/README.md`). Torus
   ring and ribbon = `MeshDescriptor` (hand-built positions/normals/indices).
   Do not use SceneKit (deprecated direction) or Blender.
4. **Reduce motion:** every screen honours
   `@Environment(\.accessibilityReduceMotion)`: no ambient spin/sway/wave, springs
   snap, physics settles instantly.
5. **Module ticker content (02):** the prototype conjugates "aller". Real content
   has no conjugation tables, so the ticker cycles the module's **example
   sentences** (rendered French, answer tokens in weight 500). Works for all 25
   modules with no content changes.
6. **Prompt frame:** the drill's corner-bracket frame is dropped (07 has none).

## Gravité placement (decided 2026-10-09)

Gravité (03) is the **"Aujourd'hui" screen**, opened from the `fait : N appris ·
M révisés →` line on the book home (that line no longer goes straight to
History). It shows today's pile (white = new, black = review, dashed = fragile)
with the two start buttons at the bottom (`Apprendre 8`, `Réviser 14`) in place
of the prototype's single `Commencer`. Finishing an element removes its token on
return. The 01 `Apprendre` / `Réviser` buttons still start sessions directly (no
extra tap). History stays reachable from Gravité (`Historique →` label, top
right) so the old `fait :` → History path keeps one hop more, not zero.

## Tasks

Work in a **git worktree**, not the main checkout: from the repo root
`git worktree add ../carambole-ui-redesign -b ui-redesign main` (or the
`EnterWorktree` tool / `superpowers:using-git-worktrees` skill), and run every
build there. Use a separate `-derivedDataPath` (e.g. `/tmp/cb-ui-redesign`) so it
doesn't fight the main checkout's DerivedData. T0 must run **in the main checkout
first** (the `design/` files are untracked there, so a fresh worktree won't have
them): commit `design/` + this plan on `main`, then create the worktree. Follow the repo workflow in `CLAUDE.md`:
subagent per task → spec review (against this doc + the control inventory) →
code-quality review → build gate → simulator screenshot → commit. The user tests
on device after each screen task.

**T0 — Commit the design artifacts, then make the worktree.** In the main
checkout: commit `design/` (motion.html, handoff, renders, rejected rounds) and
this plan as `docs: UI redesign prototypes + build plan`; leave the user's
uncommitted `project.pbxproj` signing change alone (don't stage it). Then create
the `ui-redesign` worktree as above. Note the worktree won't carry that local
signing change, so on-device installs from the worktree need the team set again
(`DEVELOPMENT_TEAM=QMV4SPL476` on the xcodebuild command line, not in the file).

**T1 — Tokens + fonts.** `DesignSystem.swift`: new palette values (decision 1),
font registration + `Font.display(size:wght:)` / `Font.label(size:)`, remap
`appDisplay/appPrompt/appTitle/appToken/appLabel/appExplain` to the grotesk
faces so untouched screens still compile and look coherent. `ProgressRing` stays
(grayscale). `PrimaryButtonStyle` → black 54pt pill (07/03 button).
`DesignGalleryView` updated. *Verify:* build, gallery screenshot.

**T2 — Drill: Aimants (07).** Highest daily use; land it first.
- `TokenBuilderView`: tiles are level capsules (white, 1pt ink border), laid out
  in a wrapping flow from `displayBank` order. Placed tiles move to the answer
  line (black fill) with `.spring(duration: 0.35, bounce: 0.3)` and a short scale
  pop; tapping a placed tile flies it back to its fixed home slot (homes never
  reflow). Use `matchedGeometryEffect` keyed by **bank index**, not the string,
  so duplicate tokens stay correct. Keep the existing bounded `.basedOnSize`
  scroll for very long banks.
- `ChoiceView`: same tile look; the chosen tile springs onto the line.
- Correct: placed tiles lose border/fill and tighten into one sentence (weld),
  unplaced tiles drop off-screen, one `wght` wave (300 → ~720) runs letter by
  letter, then the existing auto-advance.
- Wrong: line shakes (`phaseAnimator`, ~3 cycles), mismatched tiles turn dashed,
  "Réponse : …" appears; Suivant stays manual (unchanged rule).
- Light haptic per snap (`UIImpactFeedbackGenerator(.light)`), success haptic on
  correct.
- Everything in the drill inventory above stays.
*Verify:* build; screenshots of build / MC / typed / wrong / review / compact
(keyboard) states via the `CB_SCREEN` harness (revert it after; uninstall +
reinstall before judging).

**T3 — History: Ruban (05).** `RealityView` ribbon: oldest day at top, today at
bottom; width = learned + reviewed (eased between days); rest day = a full
**2π** twist (π leaves the grey back showing). Width direction = projection of
world Z perpendicular to the tangent (Frenet frames flip and crumple). Two-sided
paper: white front, grey back (duplicate mesh with flipped winding, or
`faceCulling = .none` + two materials). Vertical drag → day index with a
selection haptic per day; readout overlay (`Jeu. 8 oct. · 8 appris · 21
révisés`, default today); horizontal drag turns it; gentle sway, no spin.
Totals (appris / révisés), **Série N j** (compute the current streak from
`activities`), legend `Largeur = travail · torsion = pause`. Below the ribbon
(scroll down): the existing per-day list + "approximatives" footnote, so older
history and exact numbers stay reachable. Empty state kept. Data:
`HistoryViewModel.activities` (last 30 days for the ribbon).

**T4 — Module page: Cinétique (02).** Rebuild `ModuleDetailView` as the 02 page:
`‹ Module N` + ring (module mastery), title with the `wght` wave
(`TimelineView(.animation)`, per-letter `Font.display(wght:)`), the rule label,
the rolling ticker (decision 5, vertical roll every ~1.8 s), then the element
list with buckets and **swipe-to-demote kept**, then a fixed **Apprendre** pill
for this module (locked modules: disabled, "Verrouillé"). Entry: from Tranches
(T6) and, until T6 lands, from the existing ⓘ.

**T5 — Book home: Objet (01).** `RealityView`: chrome extruded star
(`PhysicallyBasedMaterial`, metallic ~0.85, roughness ~0.2, clearcoat; image-based
lighting from a neutral environment resource), slow turn, drag to turn with
inertia. **Orbit ring** = the progress bar: faint full track + dark arc for
*maîtrisé* + a bead at its end; optionally a lighter arc segment for *en cours*
so the 3 buckets of the current bar survive. Edge type per the inventory table.
Swipe up (or `25 modules ↑`) → Tranches. *Check on device that the chrome reads
well* (only headless renders so far).

**T6 — Table of contents: Tranches (06).** `RealityView` with 25 instances of one
thin extruded star (scale ~0.55 of the 01 star) on a thin ink skewer, module 01
at the bottom. Materials: chrome = mastered, white = in progress, faint glass +
grey outline = to come; selected slice gets an ink outline. Interaction:
vertical drag maps the finger to an index over the **closed** stack's screen
extent (prevents jitter while fanning), selection haptic per slice; the stack
fans open (slices above lift, selected lifts half and slides out, slowly spins);
horizontal drag turns the stack; tap or `Ouvrir →` → slice lifts, tilts to face
the camera, then push the 02 page (`matchedGeometry`/zoom transition). Readout:
number, title, ring + `En cours · 52 %` / `Maîtrisé` / `À venir` (locked:
`Verrouillé`, Ouvrir disabled). Default selection = newest unlocked module.
Spacing that read well in the prototype: slice radius 0.55, gap 0.17 (gap ≈ 0.3 ×
radius), camera low (~9° above the stack).

**T7 — Today: Gravité (03).** Placement as decided above. SpriteKit
`SpriteView` pill tokens with physics bodies (white = new, black = review,
dashed = fragile; labels = element names from today's new + review queues, same
sources as the 01 counts), `Secouer`, optional CoreMotion tilt. Header: `‹
Aujourd'hui`, date, `Historique →`. Bottom: `Apprendre N` / `Réviser M` pills
starting the same sessions as 01, plus the fragile chip if any. On return from a
session, refresh and let finished tokens leave (fade/fall out) rather than
rebuilding the pile.

**T8 — Library + Settings restyle.** Grotesk tokens, edge-type layout, no new
concept. All controls unchanged.

**T9 — Cleanup.** Remove dead "Le Cahier" bits no longer referenced (corner
bracket, serif font names), update `CLAUDE.md` design-system pointer.

## Gotchas carried over

- Build gate: `name:iPhone 16` destination fails; use `-destination 'id=<udid>'`
  (see `CLAUDE.md`). `-quiet` hides the success banner, judge by exit code.
- Taps can't be automated on the simulator here. Screenshot with the
  `CB_SCREEN` env-gated `#if DEBUG` harness, revert it, then uninstall +
  reinstall before judging the clean build.
- Trypophobia: no dot fields, halftones, perforations, clustered small circles.
  Single circles (ring, bead) are fine. Watch the drill tile bank and Gravité
  pile too: they are pills, never dots.
- Do not touch SRS/scheduler/content code; this is a view-layer change.
  `BookViewModel` may gain read-only helpers.
