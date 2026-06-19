"""Finalize raw LLM output into validated, grouped topic JSON (staging).

Each raw line is an exercise dict plus an echoed `_seed`. We strip the seed,
enforce the seed-consistency contract, drop anything that fails, group survivors
by topic, and write topic JSON + a manifest to a staging dir (NOT the live app
content — curation is a separate, later step).
"""
from __future__ import annotations

import json
import os

from content_pipeline.assemble import build_topic, write_topics
from content_pipeline.contract import check_against_seed
from content_pipeline.topic_meta import TOPIC_META
from content_pipeline.validate import validate_exercise


def accept(lines: list[dict]) -> tuple[list[dict], list[dict]]:
    """Split raw lines into (accepted exercises, rejections).

    A rejection is `{"id": ..., "errors": [...]}`. Accepted exercises have the
    `_seed` echo removed.
    """
    good: list[dict] = []
    rejected: list[dict] = []
    for line in lines:
        seed = line.get("_seed")
        ex = {k: v for k, v in line.items() if k != "_seed"}
        if seed is None:
            errors = validate_exercise(ex) + ["missing _seed echo"]
        else:
            errors = check_against_seed(ex, seed)
        if errors:
            rejected.append({"id": ex.get("id"), "errors": errors})
        else:
            good.append(ex)
    return good, rejected


def group_topics(exercises: list[dict]) -> list[dict]:
    """Group accepted exercises by `topicID` into validated GrammarTopic dicts."""
    by_topic: dict[str, list[dict]] = {}
    for ex in exercises:
        by_topic.setdefault(ex["topicID"], []).append(ex)

    topics: list[dict] = []
    for topic_id, exs in by_topic.items():
        meta = TOPIC_META[topic_id]
        topics.append(
            build_topic(
                topic_id,
                meta["title"],
                meta["sortOrder"],
                None,  # prerequisite chain decided at curation time
                meta["ruleNote"],
                exs,
            )
        )
    topics.sort(key=lambda t: t["sortOrder"])
    return topics


def load_raw(in_dir: str) -> list[dict]:
    lines: list[dict] = []
    for fn in sorted(os.listdir(in_dir)):
        if not fn.endswith(".jsonl"):
            continue
        with open(os.path.join(in_dir, fn), encoding="utf-8") as f:
            for raw in f:
                raw = raw.strip()
                if raw:
                    lines.append(json.loads(raw))
    return lines


def finalize_files(in_dir: str, out_dir: str) -> dict:
    lines = load_raw(in_dir)
    good, rejected = accept(lines)
    topics = group_topics(good)
    manifest = write_topics(topics, out_dir)
    return {
        "raw": len(lines),
        "accepted": len(good),
        "rejected": len(rejected),
        "topics": len(topics),
        "rejections": rejected,
        "manifest": manifest,
    }
