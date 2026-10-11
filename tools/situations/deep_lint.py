#!/usr/bin/env python3
"""Run the offline French grammar checker on correctly rendered Book 2 lines."""

from __future__ import annotations

import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from deep_lint import build_checker, canary, flags_for  # noqa: E402

MODULE = ROOT / "carambole/Resources/Situations/06_au_cafe.json"


def correct_surfaces(item: dict) -> list[str]:
    gap_choice = next((d["choices"][d["correct"]] for d in item["drills"]
                       if d["type"] == "complete"), None)
    lines = []
    for turn in item["turns"]:
        if turn.get("source"):
            continue
        line = turn["text"]
        if "___" in line and gap_choice is not None:
            line = line.replace("___", gap_choice)
        mark = turn.get("error")
        if mark:
            parts = line.split()
            for index, part in enumerate(parts):
                if part.strip(".,!?;:«»…") == mark["word"]:
                    parts[index] = part.replace(mark["word"], mark["fix"], 1)
                    break
            line = " ".join(parts)
        if "___" not in line:
            lines.append(line)
    if item.get("followUp"):
        lines.append(item["followUp"])
    for drill in item["drills"]:
        if drill["type"] == "reply":
            lines.extend(" ".join(answer) for answer in drill["accepted"])
        elif drill["type"] == "pick":
            lines.append(drill["choices"][drill["correct"]])
    return list(dict.fromkeys(lines))


def main() -> int:
    module = json.loads(MODULE.read_text(encoding="utf-8"))
    gc, opts = build_checker()
    if not canary(gc, opts):
        print("Grammalecte canary failed", file=sys.stderr)
        return 2
    errors = []
    count = 0
    for element in module["elements"]:
        for item in element["items"]:
            for line in correct_surfaces(item):
                count += 1
                for flag in flags_for(gc, opts, line):
                    if flag["kind"] == "grammar":
                        errors.append(f"{item['id']}: {flag['rule_id']}: « {line} » — {flag['message']}")
    for error in errors:
        print(error)
    print(f"situation deep lint: {count} rendered lines, {len(errors)} grammar flags")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
