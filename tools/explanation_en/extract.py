#!/usr/bin/env python3
"""Extract every example in one module that needs an English explanation.

The post-answer banner shows the French `explanation`; we add a parallel English
`explanationEN` (a full bilingual explanation, distinct from the terse pre-answer
`hint`). For each example, emit a compact spec an authoring agent can read without
parsing the whole module: the prompt, the (immutable) answer, the French
explanation to render in English, and the existing terse English hint for tone.

The agent returns {exampleId: "English explanation."}; `apply.py` merges it back,
touching only the new `explanationEN` key. Examples that already carry a non-empty
`explanationEN` are skipped (idempotent re-runs).

Usage: python3 tools/explanation_en/extract.py <module.json>
Prints a JSON array to stdout.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    path = Path(sys.argv[1])
    module = json.loads(path.read_text())
    specs = []
    for el in module["elements"]:
        for ex in el["examples"]:
            if ex.get("explanationEN", "").strip():
                continue  # already authored — idempotent
            specs.append({
                "id": ex["id"],
                "prompt": ex["prompt"],
                "answer": " ".join(ex["answerTokens"]),
                "explanationFR": ex.get("explanation", ""),
                "hint": ex.get("hint", ""),
                "translation": ex.get("translation", ""),
            })
    json.dump(specs, sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
