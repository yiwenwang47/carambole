"""Text-fit measurement with the bundled Manrope (PIL, variable font).

Mirrors SwiftUI word wrap closely enough for lint guards: greedy word wrap at
a width, line height from the font's hhea metrics, and the uniform shrink that
`.minimumScaleFactor` applies. Used by lint.py so content that would need more
shrink than a view allows fails before it reaches the app (dots are forbidden,
user 2026-10-24).
"""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from fontTools.ttLib import TTFont
from PIL import ImageFont

MANROPE = Path(__file__).resolve().parents[2] / "carambole/Resources/Fonts/Manrope-Variable.ttf"
_REF = 100  # measure at 100 px, scale linearly


@lru_cache(maxsize=None)
def _font(wght: int) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(MANROPE), _REF)
    f.set_variation_by_axes([wght])
    return f


@lru_cache(maxsize=None)
def _line_height_em() -> float:
    t = TTFont(str(MANROPE))
    hhea, upm = t["hhea"], t["head"].unitsPerEm
    return (hhea.ascent - hhea.descent + hhea.lineGap) / upm


def width(text: str, size: float, wght: int = 400) -> float:
    return _font(wght).getlength(text) * size / _REF


def wrap(text: str, size: float, max_width: float, wght: int = 400) -> list[str]:
    lines: list[str] = []
    cur = ""
    for word in text.split(" "):
        trial = f"{cur} {word}" if cur else word
        if not cur or width(trial, size, wght) <= max_width:
            cur = trial
        else:
            lines.append(cur)
            cur = word
    lines.append(cur)
    return lines


def fit_scale(text: str, size: float, box_w: float, box_h: float, wght: int = 400,
              step: float = 0.01) -> float:
    """Largest scale (<= 1) at which `text` wraps inside box_w x box_h, with no
    line wider than the box (a single long word must fit too)."""
    s = 1.0
    while s > 0.3:
        sz = size * s
        lines = wrap(text, sz, box_w, wght)
        if (len(lines) * _line_height_em() * sz <= box_h
                and all(width(ln, sz, wght) <= box_w for ln in lines)):
            return round(s, 2)
        s -= step
    return 0.0
