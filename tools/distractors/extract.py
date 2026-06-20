#!/usr/bin/env python3
"""Extract the buildFromTokens drills from one module that need harder distractors.

For each `buildFromTokens` example, emit a compact spec an authoring agent can read
without parsing the whole module: the prompt, the (immutable) answer, any existing
distractors, and how many NEW distractor tokens are needed to reach the target bank
size. The agent returns {exampleId: [distractor, ...]}; `apply.py` merges it back.

Target bank size = max(len(answer)+2, round(1.6*len(answer))) — so the bank is
~1.6x the answer length, with at least 2 distractors. `need` = target - len(answer)
(the bank is rebuilt as answerTokens + the agent's distractors, so existing weak
distractors are replaced, not accumulated).

Usage: python3 tools/distractors/extract.py <module.json>
Prints a JSON array to stdout.
"""
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path


def target_size(n: int) -> int:
    return max(n + 2, round(1.6 * n))


def main() -> int:
    path = Path(sys.argv[1])
    module = json.loads(path.read_text())
    specs = []
    for el in module["elements"]:
        for ex in el["examples"]:
            if ex.get("inputMode") != "buildFromTokens":
                continue
            ans = ex["answerTokens"]
            # existing distractors = bank minus the answer multiset
            extra = list((Counter(ex["tokenBank"]) - Counter(ans)).elements())
            need = target_size(len(ans)) - len(ans)
            specs.append({
                "id": ex["id"],
                "prompt": ex["prompt"],
                "translation": ex.get("translation", ""),
                "answer": " ".join(ans),
                "answerTokens": ans,
                "existingDistractors": extra,
                "need": need,
            })
    json.dump(specs, sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
