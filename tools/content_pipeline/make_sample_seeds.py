"""Generate a sample seed corpus for the LLM-generation step to consume.

Produces seeds for the first ~8 common verbs across [présent, imparfait] and
writes them, one JSON Seed per line, to ``out/sample_seeds.jsonl``.

Run from the ``tools`` directory:

    python3 -m content_pipeline.make_sample_seeds
"""
from __future__ import annotations

import dataclasses
import json
import os

from content_pipeline.seeds import all_seeds
from content_pipeline.verbs import COMMON_VERBS

_NUM_VERBS = 8
_TENSES: list[tuple[str, str]] = [
    ("indicatif", "présent"),
    ("indicatif", "imparfait"),
]
_OUT_DIR = os.path.join(os.path.dirname(__file__), "out")
_OUT_PATH = os.path.join(_OUT_DIR, "sample_seeds.jsonl")


def main() -> None:
    verbs = COMMON_VERBS[:_NUM_VERBS]
    seeds = all_seeds(verbs, _TENSES)

    os.makedirs(_OUT_DIR, exist_ok=True)
    with open(_OUT_PATH, "w", encoding="utf-8") as handle:
        for seed in seeds:
            line = json.dumps(dataclasses.asdict(seed), ensure_ascii=False)
            handle.write(line + "\n")

    print(f"wrote {len(seeds)} seeds to {_OUT_PATH}")


if __name__ == "__main__":
    main()
