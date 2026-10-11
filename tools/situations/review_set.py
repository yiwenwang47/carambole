#!/usr/bin/env python3
"""Export a small production Situation sample to the existing Test book.

The Test book's PilotContent decoder expects a flat glossary and dialogue list.
Production keeps words and elements separate; this script is the only adapter.
"""

from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path
import sys

sys.path.append(str(Path(__file__).resolve().parent))
from sitbook import ROOT, SITUATIONS, load_manifest_modules  # noqa: E402

WORDS = SITUATIONS / "words.json"
OUTPUT = ROOT / "carambole/Debug/testbook_situation.json"


def export(modules: dict | list[dict], words: dict, ids: list[str]) -> dict:
    """Export nine items (from any manifest modules) in the given D D S order."""
    if isinstance(modules, dict):
        modules = [modules]
    entries = {item["id"]: (element, item) for module in modules
               for element in module["elements"] for item in element["items"]}
    if len(ids) != 9 or len(set(ids)) != 9:
        raise ValueError("review set needs nine distinct item IDs")
    missing = set(ids) - entries.keys()
    if missing:
        raise ValueError(f"unknown review IDs: {', '.join(sorted(missing))}")
    items = []
    for item_id in ids:
        element, source = entries[item_id]
        item = copy.deepcopy(source)
        item["element"] = element["title"]
        items.append(item)
    pattern = ["standalone" in item for item in items]
    if pattern != [False, False, True] * 3:
        raise ValueError("review order must be D D S D D S D D S")
    for left, right in zip(items, items[1:]):
        if left["drills"][-1]["type"] == right["drills"][0]["type"]:
            raise ValueError(f"repeated boundary drill type: {left['id']} → {right['id']}")
    glossary = {entry["fr"]: ("* " if entry.get("spoken") else "") + entry["en"]
                for entry in words["words"]}
    return {"glossary": glossary, "dialogues": items}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ids", nargs=9, help="nine item IDs from any modules, ordered D D S three times")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    words = json.loads(WORDS.read_text(encoding="utf-8"))
    result = export(load_manifest_modules(), words, args.ids)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {len(result['dialogues'])} cards to {args.output}")


if __name__ == "__main__":
    main()
