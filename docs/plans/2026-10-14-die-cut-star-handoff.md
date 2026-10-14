# Handoff: die-cut star, ribbon dropped (2026-10-14)

Shipped on `main` (merge `9cc8bfb4`, pushed). The Release build is installed on
the iPhone 18 Pro. The user has not reviewed it on the phone yet.

## What changed

1. **The star is a die-cut card** (commit `54cb9895`).
   - Shape: the carambole star outline, grown by a white border with round
     tips. Card thickness 0.08 (it was 0.05 in the trial; the user asked for
     "slightly thicker").
   - Face: the palette's star colour, with the quiet colour printed a little
     off register over one lobe (multiply, 90 %).
     - Acide: lime face, sky overprint.
     - Iris: lilac face (`tokenNew`), pistachio overprint. It reads grey.
     - Surimpression: blue face, pink overprint.
   - Edges are smooth. The user rejected torn edges: "ragged looks creepy".
   - Code: `carambole/DesignSystem/StarCard.swift` (mesh, face texture,
     materials). `StarVideoRenderer` renders it into
     `Resources/StarVideos/star_<palette>.mov`.
   - The Colors page text no longer says "acrylic" or "iridescent".
2. **The library ribbon is gone** (commit `20601f46`).
   - `LibraryRibbon.swift` is archived in `docs/archive/code/`. It is not
     compiled. The README there lists the call sites to restore.
   - The user rule is **archive, never delete**.
   - The shelf keeps the old 200 pt book slots (`LibraryView.Slot`).
   - The ribbon colours are still in `Theme.swift`, unused.

## Why

The flat cut-paper language marks did not match the glossy 3D star and the 3D
paper ribbon. The user decided:

- Drop the ribbon.
- Keep the star as the app's only 3D object.
- Give the star a flat, printed finish.

They liked the **ink card** (black face, the marks' exact recipe) too, but chose
the colour card to "bring more color to the app".

## Trial looks (DEBUG only)

| Flag | Effect |
|---|---|
| `CB_RENDER_STAR=1` | re-render the shipped card loops into Documents |
| `CB_RENDER_STAR=ink` / `objet` | render the ink card / the old acrylic star into `star_<look>_<palette>.mov` |
| `CB_STAR_VARIANT=ink` / `objet` | play that trial loop on the book page |

To regenerate the loops, follow `tools/star_video/README.md`. The committed
loops were rendered in the **simulator** (Mac GPU). The old loops were rendered
on the phone, so check the colours on the phone.

## Mocks and recordings

- Mock with four star finishes next to the marks, plus the home page:
  https://claude.ai/artifact/KoG5B5dkqq2mWohL6q6AKZ
- Simulator recordings, card vs ink on the book page (card at 0.05 thick):
  https://claude.ai/artifact/NaZDuP1kAmwMhfAg3n8ZjC

## User rules from this session

- The home page has **no book counts** (00 / 02) above English / Français.
  The saved `design/studio/prefs/layout-specimen.json` still has them, so
  ignore that.
- No ragged or torn edges on the star.
- Archive removed code, never delete it.
- Keep the marks as they are: the numerals inside them and their faint edge
  stay.

## Open items

- **Phone review:** star colours and thickness rendered with the Mac GPU.
- **The shelf looks empty** without the ribbon. Watch for the user's reaction.
- **Overprint shape:** the off-register lobe runs tip-to-centre with straight
  sides, so it can read as a fold or shadow. On Iris it is grey. Reshape it or
  drop it only if the user asks.
- **Ink card as an option under Colors:** not built. The user liked it.
- **Unused ribbon colours** in `Theme.swift` (`ribbonFront/Back`,
  `soonFront/Back`): kept in case the ribbon comes back.

## Follow-up, same day: home centring + book marks

- Home: the two language rows are centred vertically as a block, and the
  mark-to-name gap is 24 pt (`LanguagesView.Layout.nameX` 102).
- Shelf: each book has a die-cut mark on the right (`BookMarkView`,
  `DesignSystem/BookMark.swift`). Fondations = seed, En situation = guillemet «;
  a book to come draws its mark in greys. Same Cut paper / Script sticker
  recipes as the language marks, following the style picked under Colors.
- Colour = the "Pale" face: pale fill moved 30 % toward the palette colour (the
  full star colour was "too bright", the plain pale fill "a little too grey").
- A first pictogram mock (`design/book-icons.html`: arch, bubbles, cup) was
  rejected outright; book marks must look like the language marks. Record in
  `design/studio/PREFERENCES.md`.
