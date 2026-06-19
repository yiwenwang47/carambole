# Carambole Design System — "Le Cahier"

Visual direction for the French grammar trainer. **Evolves** the app's existing
point of view (stark editorial: ink-on-white, oversized type, left-aligned,
saffron #FFB879 accent, decorative corner brackets) into a refined **French
grammar-notebook** aesthetic. Every UI task (T5 DrillView, T6 TopicMap, T9 Review)
MUST consume this system — do not hand-roll colors/fonts.

Light mode first (the current app is light-only). No dark mode this pass.

## Palette  (define in `DesignSystem.swift` as `enum AppColor` → `Color`)

| Token        | Hex       | Use                                          |
|--------------|-----------|----------------------------------------------|
| `paper`      | `#FAF7F0` | App background (warm cream, NOT pure white)  |
| `ink`        | `#14110E` | Primary text, borders, primary button fill   |
| `graphite`   | `#6B655C` | Secondary text, uppercase labels             |
| `saffron`    | `#FFB879` | THE accent — progress, current marker, sweep |
| `saffronDeep`| `#E8915C` | Pressed/active accent                        |
| `success`    | `#5B8C5A` | Correct-answer state (muted sage)            |
| `error`      | `#C0563F` | Wrong-answer state (terracotta)              |
| `hairline`   | `#E2DBCD` | Rules, dividers, progress track, tile border |

Single accent discipline: saffron only. Sage/terracotta appear ONLY on answer
result state.

## Typography  (helpers in `DesignSystem.swift`, e.g. `Font.appPrompt`)

- **Display / prompt / topic title** → serif: `.system(size:, weight: .semibold, design: .serif)`
  (Apple "New York"). This serif is the signature — it makes it feel like a
  printed French textbook, not a generic app.
- **Token tiles** → `.system(.rounded)` medium, tactile.
- **Body / explanation** → `.system(design: .serif)` italic for the rule
  explanation; `.default` for plain body.
- **Labels** (the existing "SEARCH" style) → uppercase, kerning ≈ 2, small,
  `graphite`. Keep this treatment for section labels.
- Rough scale: prompt 30–34 serif · topic title 26–28 serif · token 20 rounded ·
  label/caption 13 uppercase tracked.

## Signature motifs

- **Corner brackets** — reuse the existing `BracketView` to frame the drill
  prompt. It is the brand mark; keep it.
- **Fill-in-the-blank slots** — the answer area renders as **underlined blanks**
  (paper worksheet). Empty = a saffron/ink underline; filled = the chosen token
  sitting on the underline. Tapping a filled slot returns the token to the bank.
- **Table des matières** — the topic map is a numbered editorial table of
  contents with `hairline` rules between rows, NOT a gamified candy map.
- Optional: an oversized accented glyph (é / ç) at low opacity as background
  texture on drill/topic screens. Use sparingly.

## Components  (foundations in `DesignSystem.swift`; composites built by T5/T6)

Built now in the design-system task:
- `AppColor` palette + `Color(hex:)` helper.
- `Font` helpers: `appPrompt`, `appTitle`, `appToken`, `appLabel`, `appExplain`.
- `Spacing` constants (e.g. `screenH = 40` matching current left padding).
- `PrimaryButtonStyle` — `ink` fill, `paper` text, rounded, pressed → `saffronDeep`
  (compose with existing `ScaleButtonStyle` press scale).
- Recolor `CircularProgressView` → `saffron` ring on `hairline` track.

Built by the consuming UI tasks (following this doc, not pre-built — YAGNI):
- `TokenTile` (rounded chip, paper fill, 1pt `ink` border, `ScaleButtonStyle`),
  used + faded state.
- `AnswerSlotRow` (underlined slots that fill with tokens).
- `StateBanner` (correct → sage tint + check; wrong → terracotta tint + correct
  answer + explanation in serif italic).
- `TopicRow` (number · serif title · state glyph: ✓ saffron / • saffron dot /
  lock graphite · hairline divider).

## Motion

- Topic map load: staggered row reveal (opacity + small y-offset, delay by index).
- Correct: saffron underline sweep under the slot row + `.success` haptic
  (`UINotificationFeedbackGenerator`).
- Wrong: brief shake on the slot row + `.error` haptic.
- Exercise → exercise: paper slide (move + opacity transition).

## Don'ts

- No pure-white background; no default sans for display (serif is the signature).
- No second accent color; saffron carries it.
- Keep left-aligned editorial composition and generous top whitespace (match the
  current home screen).
