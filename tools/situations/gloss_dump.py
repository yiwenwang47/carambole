#!/usr/bin/env python3
"""Print every tappable French line of a module with the gloss each token shows.

For the gloss-in-context check (user rule 2026-10-12: every gloss must be right
in every drill). Segments like `lint.unglossed` / Swift `PilotText.segments`:
longest key first. Unglossed tokens print as `token=?`.

    python3 tools/situations/gloss_dump.py MODULE.json WORDS.json [--moves a,b]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from tools.situations.lint import tappable_lines, tokens  # noqa: E402


def segments(line: str, glosses: dict[str, str]) -> list[tuple[str, str]]:
    """Split a line into (key, gloss) pairs, longest key first.

    A `___` gap breaks phrases, as in the app (`Models/Situation.swift`).
    """
    if "___" in line:
        out: list[tuple[str, str]] = []
        for n, part in enumerate(line.split("___")):
            if n:
                out.append(("___", "(gap)"))
            out += segments(part, glosses)
        return out
    raw = tokens(line)
    phrases = sorted((k.split() for k in glosses), key=len, reverse=True)
    out: list[tuple[str, str]] = []
    i = 0
    while i < len(raw):
        match = next((p for p in phrases if raw[i:i + len(p)] == p), None)
        if match:
            key = " ".join(match)
            out.append((key, glosses[key]))
            i += len(match)
        else:
            out.append((raw[i], "?"))
            i += 1
    return out


def dump(module: dict, glosses: dict[str, str], moves: set[str] | None = None) -> str:
    rows: list[str] = []
    for element in module.get("elements", []):
        if moves and element["id"].rsplit("_", 1)[-1] not in moves:
            continue
        for item in element.get("items", []):
            rows.append(f"\n## {item['id']}")
            seen: set[str] = set()
            for line in tappable_lines(item):
                if not line or line in seen:
                    continue
                seen.add(line)
                pairs = " · ".join(f"{k}={g}" for k, g in segments(line, glosses))
                rows.append(f"- « {line} »\n  {pairs}")
    return "\n".join(rows)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("module")
    parser.add_argument("words")
    parser.add_argument("--moves", default="")
    args = parser.parse_args()
    module = json.loads(Path(args.module).read_text())
    words = json.loads(Path(args.words).read_text())["words"]
    glosses = {" ".join(tokens(w["fr"])): w["en"] for w in words}
    moves = {m for m in args.moves.split(",") if m} or None
    print(dump(module, glosses, moves))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
