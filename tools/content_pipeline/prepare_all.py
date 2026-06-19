"""Prepare seed batches for the full corpus (deterministic step).

Usage: python3 content_pipeline/prepare_all.py [--batch-size 100] [--out DIR]
Writes out/batches/batch_NN.jsonl, then print the agent-dispatch instructions.
"""
from __future__ import annotations

import argparse

from content_pipeline.conjugator import SUPPORTED_TENSES
from content_pipeline.prepare import write_batches
from content_pipeline.seeds import all_seeds
from content_pipeline.verbs import COMMON_VERBS


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--batch-size", type=int, default=100)
    ap.add_argument("--out", default="content_pipeline/out/batches")
    args = ap.parse_args()

    seeds = all_seeds(COMMON_VERBS, SUPPORTED_TENSES)
    paths = write_batches(seeds, args.batch_size, args.out)

    print(f"{len(seeds)} seeds -> {len(paths)} batches in {args.out}")
    print("\nNext: dispatch one generation sub-agent per batch, each following")
    print("content_pipeline/agent_template.md, reading the batch and writing")
    print("out/raw/<same-name>.jsonl. Then run finalize_all.py.")


if __name__ == "__main__":
    main()
