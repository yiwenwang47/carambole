#!/usr/bin/env python3
"""Merge agent-authored distractors back into a module's buildFromTokens banks.

Reads a distractors map {exampleId: [distractor, ...]} (the agent's output) and,
for each `buildFromTokens` example, rebuilds tokenBank = answerTokens + distractors.
Everything else (answerTokens, prompt, multipleChoice/freeText banks, structure) is
left byte-for-byte. Validates the result before writing:

  - every buildFromTokens example in the module has an entry in the map
  - rebuilt bank reaches the target size (max(len+2, round(1.6*len)))
  - distractors are distinct from each other and add no answer token (they are
    *wrong* forms; the answer multiset already lives in answerTokens)
  - answerTokens stays a multiset subset of the new bank (trivially, by construction)

Usage: python3 tools/distractors/apply.py <module.json> <distractors.json>
Exit 0 = written, 1 = validation error (module left untouched).
"""
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path


def target_size(n: int) -> int:
    return max(n + 2, round(1.6 * n))


def dumps_cb(obj, ind: int = 0) -> str:
    """Serialize matching the authored style: dicts and object-arrays are pretty
    printed (2-space), but arrays of scalars stay inline (`["je", "suis"]`). This
    keeps the merge diff to just the changed `tokenBank` lines."""
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
    dmap = json.loads(Path(sys.argv[2]).read_text())
    module = json.loads(module_path.read_text())

    errors: list[str] = []
    for el in module["elements"]:
        for ex in el["examples"]:
            if ex.get("inputMode") != "buildFromTokens":
                continue
            xid = ex["id"]
            ans = ex["answerTokens"]
            if xid not in dmap:
                errors.append(f"{xid}: no distractors provided")
                continue
            distractors = dmap[xid]
            want = target_size(len(ans)) - len(ans)
            if len(distractors) != want:
                errors.append(
                    f"{xid}: got {len(distractors)} distractors, need {want}")
                continue
            if len(set(distractors)) != len(distractors):
                errors.append(f"{xid}: duplicate distractors {distractors}")
                continue
            overlap = Counter(distractors) & Counter(ans)
            if overlap:
                errors.append(
                    f"{xid}: distractor(s) duplicate an answer token "
                    f"{list(overlap.elements())}")
                continue
            ex["tokenBank"] = list(ans) + list(distractors)

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
