# Language marks + home page: user preferences

Source: `design/studio/prefs/*.json` (the user's saves; history in `history.jsonl`).
Latest update: 2026-10-14, round 4 review.

## Standing rules (rounds 1–3)

- App text is English. Only French book titles and subtitles stay in French.
- Each language mark is small, symbolic and fixed (it never changes with data).
  No national flags.
- Français = one ribbon link. English = a petal.
- The home page must look clearly different from the shelf. No "Pick a language" line.
- No 3D paper objects and no metallic glow: these are flat logo marks.
- The English shelf is empty apart from one greyed placeholder book.

## Marks, round 4 (die-cut, one style per reference)

| Style | Reference | Vote | Note |
|---|---|---|---|
| Acrylic charm | keychain | like | Charms are good, the **rings are bad**. Make them **more acrylic-like**. |
| Script sticker | Acne Studios | like | none |
| Riso sticker | Dorian Electra | **no** | none |
| Cut paper | horse poster | like | The **fringes look creepy**: change their shape or drop them. |
| Split block | Bradmead | **no** | **Too cliché.** Make something else from this poster. |
| Serif block | CloseCo | like | none |

Overall: the user leans **die-cut**. They want each mark to match one reference's
exact style (for this task this overrides "learn from refs, don't copy").

## Home layouts, round 4 (from drag positions)

Shared moves on both layouts:
- **Hid every secondary label**: `No books yet`, `2 books`, `Open →`, `Coming soon`,
  `books`, `2 languages`. Only the names, the book counts, the marks and the header are left.

Specimen:
- The book counts (`00`, `02`) moved from the far right to sit **above each name,
  near its left edge**, like a small superscript (x 92; the name starts at x 86).
- **More space between the two languages**: Français moved down about 50 pt
  (name top 140 → 327, marks 150 → 340).
- `Settings` stays at bottom right; `2 languages` is hidden.

Fields:
- Names moved **up** off the bottom of each half (English 318 → 257,
  Français 696 → 615) and from x 22 to x 26.
- The French count moved down 21 pt (420 → 441). The English count stayed at 118.
- Split line (380) and marks (x 216) unchanged.

Open questions (spacing is uneven, so may be unintended):
- Fields: number-to-name gap is 139 pt in English and 174 pt in French.
  Number top below the top edge of its half: 118 in English (where the header also sits)
  and 61 in French.
- Specimen: count at x 92 vs name at x 86. Is that optical alignment to the glyph, or a slip?

## Marks, round 5 review (2026-10-14 02:14)

| Style | Vote | Note |
|---|---|---|
| Acrylic charm | like | **Less shadow.** |
| Script sticker | like | none |
| Cut paper | like | "Good." Asked whether it brings in a new colour palette: the home page must stay **consistent with everything else**. |
| Serif block | like | Same palette concern as cut paper. |
| Echo stack | **no** | "Drop this." |

Decision taken in round 6 (please confirm): **no new palette.** Every mark takes its
colours from the app's own palettes (Theme.swift: Acide, Iris, Surimpression), so it
changes with Colors → like the star and the ribbon:
- Charm = loud colour acrylic on a quiet-colour field.
- Script = ink, with the sparkle in the loud colour.
- Cut paper = ink, with the quiet colour printed over it and numbers in the deep colour.
- Serif = black on the pale loud fill (the capped fill used for buttons).
- Fields planes = pale quiet (English) and pale loud (Français).

Layouts: no position changes since round 4. In Fields the user started a note
("the only problem with this l…") and then deleted it. Ask what it was.

## Decisions, 2026-10-14 (after round 6)

- **No new palettes.** Marks use only the app palettes (Acide, Iris, Surimpression).
- **Marks kept: Cut paper (default) and Script sticker.** Acrylic charm was "ok", not chosen.
  Serif block was dropped.
- **Home layout: Specimen.** Fields was dropped.
- All shapes are drawn in code (`marks.js`). The references were only looked at, never traced.
