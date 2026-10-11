#!/usr/bin/env python3
"""Assemble the two independently authored café drafts into production JSON."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DRAFTS = ROOT / "tools/situations/drafts"
OUT = ROOT / "carambole/Resources/Situations"
MOVES = ("order", "size", "available", "substitute", "takeaway", "usual", "mixup", "pay")


def read(name: str) -> dict:
    return json.loads((DRAFTS / name).read_text(encoding="utf-8"))


def assemble() -> tuple[dict, dict]:
    elements = read("06_cafe_first_half.json")["elements"] + read("06_cafe_second_half.json")["elements"]
    by_id = {element["id"]: element for element in elements}
    if len(by_id) != len(elements) or set(by_id) != {f"sit_06_{move}" for move in MOVES}:
        raise ValueError("draft elements must contain the eight unique café moves")
    module = {"id": "sit_06", "title": "Au café", "arc": "Le quartier",
              "goal": "Order, specify, accept a substitute, and pay.",
              "elements": [by_id[f"sit_06_{move}"] for move in MOVES]}
    words_by_key: dict[str, dict] = {}
    for filename in ("06_cafe_first_half_words.json", "06_cafe_second_half_words.json"):
        for word in read(filename)["words"]:
            key = word["fr"].lower()
            prior = words_by_key.get(key)
            if prior is not None and prior != word:
                raise ValueError(f"conflicting word entry '{key}': {prior} / {word}")
            words_by_key[key] = word
    words = {"words": [words_by_key[key] for key in sorted(words_by_key)]}
    return module, words


def main() -> None:
    module, words = assemble()
    OUT.mkdir(parents=True, exist_ok=True)
    for filename, payload in (("06_au_cafe.json", module), ("words.json", words)):
        path = OUT / filename
        path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
