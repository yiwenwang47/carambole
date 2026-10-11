"""Shared paths and book-order helpers for the En situation tools.

Book order is module number, then element order inside the module, then item
order inside the element. Every tool ranks items with `item_ranks` so the
linter, the assembler and the audio script agree on what comes first.
"""

from __future__ import annotations

from collections.abc import Iterable
import json
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[2]
SITUATIONS = ROOT / "carambole/Resources/Situations"
DRAFTS = ROOT / "tools/situations/drafts"
CONFIG = ROOT / "tools/situations/modules.json"
MANIFEST = "situations_manifest.json"
MODULE_ID = re.compile(r"sit_(?:0[1-9]|1\d|2[0-5])")
_NUMBER = re.compile(r"^sit_(\d{2})(?:_|$)")


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def module_number(identifier: str | None) -> int | None:
    """Return 6 for `sit_06`, `sit_06_order` or `sit_06_order_d01`."""
    match = _NUMBER.match(identifier or "")
    return int(match.group(1)) if match else None


def load_config(path: Path = CONFIG) -> dict[str, dict]:
    """Module metadata keyed by two-digit number ("06")."""
    config = {}
    for entry in read_json(path)["modules"]:
        number = module_number(entry["id"])
        if number is None or not MODULE_ID.fullmatch(entry["id"]):
            raise ValueError(f"modules.json: bad module ID '{entry['id']}'")
        key = f"{number:02}"
        if key in config:
            raise ValueError(f"modules.json: duplicate module {key}")
        config[key] = entry
    return config


def manifest_files(situations: Path = SITUATIONS) -> list[str]:
    return list(read_json(situations / MANIFEST).get("moduleFiles", []))


def load_manifest_modules(situations: Path = SITUATIONS) -> list[dict]:
    """Production modules in book (numeric) order."""
    modules = [read_json(situations / name) for name in manifest_files(situations)]
    return sorted(modules, key=lambda m: module_number(m.get("id")) or 0)


def item_ranks(modules: Iterable[dict]) -> dict[str, tuple[int, int, int]]:
    """Map each item ID to its (module, element, item) book position."""
    ranks: dict[str, tuple[int, int, int]] = {}
    for module in modules:
        number = module_number(module.get("id")) or 0
        for e_index, element in enumerate(module.get("elements", [])):
            for i_index, item in enumerate(element.get("items", [])):
                ranks.setdefault(item.get("id"), (number, e_index, i_index))
    return ranks
