#!/usr/bin/env python3
"""Carambole logo — final. Palette: black / white / orange only.
Dials: r/R=0.40, soft-3 tips. Emits production SVGs + presentation board."""
import math
from pathlib import Path

OUT = Path(__file__).parent / "final"
OUT.mkdir(exist_ok=True)
SIZE = 100
C = SIZE / 2
BLACK = "#000000"
WHITE = "#FFFFFF"
ORANGE = "#F26A1B"

R, r = 42.0, 17.0  # r/R = 0.405
SOFT = 3           # tip round via round-join stroke


def pt(a, rad):
    t = math.radians(a)
    return (C + rad * math.cos(t), C + rad * math.sin(t))


def f(x):
    return f"{x:.3f}"


def star_pts(R, r, rot=-90.0):
    return ([pt(rot + 72 * k, R) for k in range(5)],
            [pt(rot + 36 + 72 * k, r) for k in range(5)])


def path(R, r, rot=-90.0):
    outer, inner = star_pts(R, r, rot)
    d = f"M {f(outer[0][0])} {f(outer[0][1])} "
    for k in range(5):
        vx, vy = inner[k]
        tx, ty = outer[(k + 1) % 5]
        d += f"Q {f(vx)} {f(vy)} {f(tx)} {f(ty)} "
    return d + "Z"


def svg(body, bg=None):
    rect = f'<rect width="{SIZE}" height="{SIZE}" fill="{bg}"/>' if bg else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {SIZE} {SIZE}" '
            f'width="{SIZE}" height="{SIZE}">{rect}{body}</svg>')


def w(name, body, bg=None):
    (OUT / name).write_text(svg(body, bg))


P = path(R, r)


def mark(fill, soft=SOFT):
    stroke = (f' stroke="{fill}" stroke-width="{soft}" stroke-linejoin="round"'
              if soft else "")
    return f'<path d="{P}" fill="{fill}"{stroke}/>'


# --- primary marks (transparent bg = true logo asset) ---
w("mark-black.svg", mark(BLACK))
w("mark-white.svg", mark(WHITE))
w("mark-orange.svg", mark(ORANGE))

# --- on-background lockups ---
w("mark-black-on-white.svg", mark(BLACK), WHITE)
w("mark-white-on-black.svg", mark(WHITE), BLACK)
w("mark-orange-on-black.svg", mark(ORANGE), BLACK)
w("mark-black-on-orange.svg", mark(BLACK), ORANGE)

# --- app-icon tiles: solid two-color (opaque, iOS-safe, no alpha) ---
def tile(tile_fill, star_fill, rx=22):
    s = (f'<path d="{P}" fill="{star_fill}" stroke="{star_fill}" '
         f'stroke-width="{SOFT}" stroke-linejoin="round"/>')
    return (f'<rect x="4" y="4" width="92" height="92" rx="{rx}" '
            f'fill="{tile_fill}"/>{s}')

w("icon-orange.svg", tile(ORANGE, BLACK))     # orange tile, black star
w("icon-black.svg", tile(BLACK, WHITE))       # black tile, white star
w("icon-white.svg", tile(WHITE, BLACK))       # white tile, black star


# --- iOS app icon: FULL-BLEED square, opaque, no rounded corners (iOS masks) ---
def appicon(bg, star_fill):
    s = (f'<path d="{P}" fill="{star_fill}" stroke="{star_fill}" '
         f'stroke-width="{SOFT}" stroke-linejoin="round"/>')
    return (f'<rect width="{SIZE}" height="{SIZE}" fill="{bg}"/>{s}')

# light = chosen logo: white bg, black star
w("appicon-light.svg", appicon(WHITE, BLACK))
# dark mode: black bg, white star (idiomatic; same mark)
w("appicon-dark.svg", appicon(BLACK, WHITE))
# tinted: luminance source for the system tint — white star on black
w("appicon-tinted.svg", appicon(BLACK, WHITE))

print("final assets written to", OUT)
