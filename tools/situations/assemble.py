#!/usr/bin/env python3
"""Assemble independently authored module drafts into production JSON.

Drafts live in tools/situations/drafts as pairs:

    NN_<slug>_<part>.json        {"elements": [...]}
    NN_<slug>_<part>_words.json  {"words": [...]}

Module metadata (ID, title, arc, goal, output file, move order) comes from
tools/situations/modules.json. Usage:

    assemble.py            assemble every module that has drafts
    assemble.py 06 07      assemble only these modules

Every run rewrites the single book-wide words.json from the drafts of all
modules in the manifest plus the named ones, and adds the named modules to
situations_manifest.json in numeric order.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

sys.path.append(str(Path(__file__).resolve().parent))
from sitbook import (  # noqa: E402
    CONFIG, DRAFTS, MANIFEST, SITUATIONS, item_ranks, load_config, module_number, read_json,
)

OUT = SITUATIONS
DRAFT_NAME = re.compile(r"^(\d{2})_[a-z0-9]+(?:_[a-z0-9]+)*\.json$")
AGREE = ("en", "spoken", "audio")


def draft_files(drafts: Path = DRAFTS) -> dict[str, list[tuple[Path, Path]]]:
    """Map "NN" to its sorted (elements draft, words draft) pairs."""
    found: dict[str, list[tuple[Path, Path]]] = {}
    paths = sorted(p for p in drafts.glob("*.json") if re.match(r"^\d{2}_", p.name))
    names = {p.name for p in paths}
    for path in paths:
        if not DRAFT_NAME.match(path.name):
            raise ValueError(f"{path.name}: draft names are NN_<slug>_<part>.json (lowercase, digits, _)")
        if path.name.endswith("_words.json"):
            if path.name.removesuffix("_words.json") + ".json" not in names:
                raise ValueError(f"{path.name}: no matching elements draft")
            continue
        words = path.with_name(path.stem + "_words.json")
        if words.name not in names:
            raise ValueError(f"{path.name}: missing {words.name}")
        found.setdefault(path.name[:2], []).append((path, words))
    return found


def build_module(entry: dict, pairs: list[tuple[Path, Path]]) -> dict:
    module_id = entry["id"]
    elements = [element for draft, _ in pairs for element in read_json(draft)["elements"]]
    by_id = {element["id"]: element for element in elements}
    wanted = [f"{module_id}_{move}" for move in entry["moves"]]
    if len(by_id) != len(elements) or set(by_id) != set(wanted):
        raise ValueError(f"{module_id}: draft elements must be exactly the unique moves "
                         f"{', '.join(entry['moves'])}; got {', '.join(e['id'] for e in elements)}")
    return {"id": module_id, "title": entry["title"], "arc": entry["arc"],
            "goal": entry["goal"], "elements": [by_id[eid] for eid in wanted]}


def merge_words(sources: list[dict], ranks: dict[str, tuple]) -> dict:
    """Merge word entries from all drafts into one book-wide list.

    For a repeated `fr` key the entry with the earliest firstSeen in book order
    wins; null (base word) loses to any taught entry. `en`, `spoken` and
    `audio` must agree across all copies.
    """
    best: dict[str, tuple[tuple, dict]] = {}
    for word in sources:
        key = word["fr"].lower()
        first = word.get("firstSeen")
        if first is not None and first not in ranks:
            raise ValueError(f"word '{word['fr']}': firstSeen '{first}' is not an assembled item ID")
        rank = ranks[first] if first is not None else (float("inf"),)
        prior = best.get(key)
        if prior is None:
            best[key] = (rank, word)
            continue
        if any(prior[1].get(field) != word.get(field) for field in AGREE):
            raise ValueError("conflicting word entries for '" + key + "' (en/spoken/audio must agree):\n  "
                             + json.dumps(prior[1], ensure_ascii=False) + "\n  "
                             + json.dumps(word, ensure_ascii=False))
        if rank < prior[0]:
            best[key] = (rank, word)
    return {"words": [best[key][1] for key in sorted(best)]}


def assemble(numbers: list[str] | None = None, *, drafts: Path = DRAFTS,
             config_path: Path = CONFIG, situations: Path = OUT) -> tuple[dict[str, dict], dict, list[str]]:
    """Return ({file: module} to write, words, manifest moduleFiles)."""
    config = load_config(config_path)
    found = draft_files(drafts)
    targets = sorted(numbers) if numbers else sorted(found)
    for number in targets:
        if number not in config:
            raise ValueError(f"module {number}: add it to modules.json")
        if number not in found:
            raise ValueError(f"module {number}: no drafts named {number}_<slug>_<part>.json")
    manifest_path = situations / MANIFEST
    current = read_json(manifest_path).get("moduleFiles", []) if manifest_path.is_file() else []
    by_file = {entry["file"]: number for number, entry in config.items()}
    included = set(targets)
    for name in current:
        number = by_file.get(name)
        if number is None or number not in found:
            raise ValueError(f"manifest module {name} has no modules.json entry or drafts; "
                             "its words would be dropped from words.json")
        included.add(number)
    modules = {number: build_module(config[number], found[number]) for number in sorted(included)}
    ranks = item_ranks(modules[number] for number in sorted(modules))
    sources = [word for number in sorted(modules) for _, words in found[number]
               for word in read_json(words)["words"]]
    words = merge_words(sources, ranks)
    files = sorted(set(current) | {config[n]["file"] for n in targets},
                   key=lambda name: (module_number("sit_" + name[:2]) or 0, name))
    written = {config[n]["file"]: modules[n] for n in targets}
    return written, words, files


def _write(path: Path, text: str) -> None:
    if not path.is_file() or path.read_text(encoding="utf-8") != text:
        path.write_text(text, encoding="utf-8")
        print(f"wrote {path}")
    else:
        print(f"unchanged {path}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("modules", nargs="*", help="two-digit module numbers; default: all with drafts")
    args = parser.parse_args()
    numbers = [f"{int(n):02}" for n in args.modules] or None
    try:
        written, words, files = assemble(numbers)
    except ValueError as error:
        print(f"assemble: {error}", file=sys.stderr)
        return 1
    OUT.mkdir(parents=True, exist_ok=True)
    for filename, payload in [*written.items(), ("words.json", words)]:
        _write(OUT / filename, json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    manifest_path = OUT / MANIFEST
    manifest = read_json(manifest_path) if manifest_path.is_file() else {"book": "fr_en_situation"}
    if manifest.get("moduleFiles") != files:
        listed = ", ".join(json.dumps(name) for name in files)
        persona = (f'  "persona": {json.dumps(manifest["persona"], ensure_ascii=False)},\n'
                   if "persona" in manifest else "")
        _write(manifest_path, "{\n" f'  "book": {json.dumps(manifest.get("book", "fr_en_situation"))},\n'
               f"{persona}"
               f'  "moduleFiles": [{listed}]\n' "}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
