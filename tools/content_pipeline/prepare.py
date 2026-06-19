"""Prepare seed batches for the LLM generation step.

Each seed gets its topic id + a stable, unique exercise id attached, then seeds
are chunked into JSONL batch files (one batch per generation sub-agent).
"""
from __future__ import annotations

import json
import os
from dataclasses import asdict, is_dataclass

from content_pipeline.topic_meta import topic_id_for


def seed_record(seed) -> dict:
    """A seed dict enriched with `topicID` and a stable `id`."""
    d = asdict(seed) if is_dataclass(seed) else dict(seed)
    topic_id = topic_id_for(d["mood"], d["tense"])
    rec = dict(d)
    rec["topicID"] = topic_id
    rec["id"] = f"{topic_id}_{d['verb']}_{d['person_index']}"
    return rec


def write_batches(seeds, batch_size: int, out_dir: str) -> list[str]:
    """Write enriched seeds to `out_dir/batch_NN.jsonl`; return the file paths."""
    os.makedirs(out_dir, exist_ok=True)
    records = [seed_record(s) for s in seeds]
    paths: list[str] = []
    for i in range(0, len(records), batch_size):
        chunk = records[i : i + batch_size]
        path = os.path.join(out_dir, f"batch_{i // batch_size:02d}.jsonl")
        with open(path, "w", encoding="utf-8") as f:
            for rec in chunk:
                f.write(json.dumps(rec, ensure_ascii=False) + "\n")
        paths.append(path)
    return paths
