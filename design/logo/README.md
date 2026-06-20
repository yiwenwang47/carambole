# Carambole — logo

Geometric mark from the **carambole (starfruit) cross-section**: a 5-point star
whose signature is **smooth concave valleys between sharp rib tips** (one
quadratic bezier per lobe) — reads as fruit, not a generic sheriff star.

**Canonical logo: black star on white.** Palette is black / white / orange only.

## Geometry

- 5 outer rib tips at R=42, 5 inner valley points at r=17 (**r/R ≈ 0.40**)
- center (50,50) in a 100×100 viewBox, point-up
- path: `M tip0  Q valley_k tip_{k+1}` ×5 — 5 quadratic curves
- **soft-3 tips**: fill + round-join stroke (width 3) softens the apexes

## Palette

black `#000000` · white `#FFFFFF` · orange `#F26A1B`

## Deliverables (`final/`)

SVG (vector source) + PNG exports in `final/png/`.

| file | use |
|------|-----|
| `mark-black.svg` | **primary** mark, transparent |
| `mark-white.svg` / `mark-orange.svg` | reverse / accent, transparent |
| `mark-*-on-*.svg` | lockups on a background |
| `icon-{orange,black,white}.svg` | rounded-tile app icon, solid two-color |
| `appicon-{light,dark,tinted}.svg` | **iOS app icon**, full-bleed, opaque |

## Shipped in the app

- **App icon** — `appicon-{light,dark,tinted}.png` (1024, no alpha) →
  `carambole/Assets.xcassets/AppIcon.appiconset/`. Light = white/black (the
  canonical logo); dark = black/white; tinted = luminance source.
- **In-app mark** — `CaramboleMark: Shape` + `CaramboleLogo` view in
  `carambole/DesignSystem/CaramboleMark.swift` (pure SwiftUI vector, same
  geometry). Used as the masthead in `LibraryView` (the root shelf).

## Regenerate / rasterize

```bash
python3 gen_final.py                  # rewrites final/*.svg
# PNG, any size, from the vector:
inkscape final/mark-black.svg -w 1024 -h 1024 -o out.png
# iOS app icon needs NO alpha — flatten with RGB_8:
inkscape final/appicon-light.svg -w 1024 -h 1024 \
  --export-png-color-mode=RGB_8 -o appicon-light.png
```

`pick.html` → `pick.png` renders the variant proposal sheet via headless Chrome.
