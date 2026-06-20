#!/usr/bin/env python3
"""Merge agent-authored English explanations back into a module.

Reads a map {exampleId: "English explanation."} and sets `ex["explanationEN"]` on
each matching example. Everything else (explanation, answerTokens, prompt, banks,
structure) is left byte-for-byte; the new key is appended last in each example
object, so the diff is one added line per example. Validates before writing:

  - every example in the module either already has a non-empty explanationEN or
    gets one from the map (no example left without an English explanation)
  - every provided value is a non-empty string

Re-serializes with the same style-preserving writer used by tools/distractors so
the diff stays minimal.

Usage: python3 tools/explanation_en/apply.py <module.json> <map.json>
Exit 0 = written, 1 = validation error (module left untouched).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path


def dumps_cb(obj, ind: int = 0) -> str:
    """Serialize matching the authored style: dicts and object-arrays are pretty
    printed (2-space), but arrays of scalars stay inline (`["je", "suis"]`)."""
    sp, sp2 = "  " * ind, "  " * (ind + 1)
    if isinstance(obj, dict):
        if not obj:
            return "{}"
        items = [f"{sp2}{json.dumps(k, ensure_ascii=False)}: {dumps_cb(v, ind + 1)}"
                 for k, v in obj.items()]
        return "{\n" + ",\n".join(items) + "\n" + sp + "}"
    if isinstance(obj, list):
        if not obj:
            return "[]"
        if all(not isinstance(x, (dict, list)) for x in obj):
            return "[" + ", ".join(json.dumps(x, ensure_ascii=False) for x in obj) + "]"
        items = [f"{sp2}{dumps_cb(x, ind + 1)}" for x in obj]
        return "[\n" + ",\n".join(items) + "\n" + sp + "]"
    return json.dumps(obj, ensure_ascii=False)


def main() -> int:
    module_path = Path(sys.argv[1])
    emap = json.loads(Path(sys.argv[2]).read_text())
    module = json.loads(module_path.read_text())

    errors: list[str] = []
    for el in module["elements"]:
        for ex in el["examples"]:
            xid = ex["id"]
            existing = ex.get("explanationEN", "").strip()
            if existing:
                continue  # already authored — leave it
            value = emap.get(xid)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{xid}: no English explanation provided")
                continue
            ex["explanationEN"] = value.strip()

    if errors:
        print(f"APPLY FAILED ({len(errors)} error(s)) — {module_path.name}:")
        for e in errors:
            print(f"  ✗ {e}")
        return 1

    module_path.write_text(dumps_cb(module) + "\n")
    print(f"APPLIED — {module_path.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
