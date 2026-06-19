"""Topic assembler — shapes GrammarTopic dicts and writes them to disk.

`build_topic` is the final gate: every exercise is routed through the shared
`validate_exercise`, and a topic containing any malformed exercise is refused.
`write_topics` serialises topics to ``NN_<slug>.json`` plus a ``manifest.json``.
"""
from __future__ import annotations

import json
import os

from content_pipeline.validate import validate_exercise


def build_topic(
    topic_id: str,
    title: str,
    sort_order: int,
    prerequisite_id: str | None,
    rule_note: str,
    exercises: list[dict],
) -> dict:
    """Assemble a GrammarTopic dict, validating every exercise first.

    Raises ``ValueError`` listing the offending exercise ids (and their errors)
    if any exercise fails ``validate_exercise``.
    """
    offenders: list[str] = []
    for index, exercise in enumerate(exercises):
        errors = validate_exercise(exercise)
        if errors:
            label = exercise.get("id", f"<index {index}>")
            offenders.append(f"{label}: {'; '.join(errors)}")

    if offenders:
        raise ValueError(
            "cannot build topic "
            f"{topic_id!r}; invalid exercises: " + " | ".join(offenders)
        )

    return {
        "id": topic_id,
        "title": title,
        "sortOrder": sort_order,
        "prerequisiteID": prerequisite_id,
        "ruleNote": rule_note,
        "exercises": exercises,
    }


def write_topics(topics: list[dict], out_dir: str) -> dict:
    """Write each topic to ``out_dir/NN_<slug>.json`` and a ``manifest.json``.

    ``NN`` is the zero-padded ``sortOrder``; ``slug`` is the topic id. Returns the
    manifest dict ``{"topicFiles": [...]}`` (also written to ``manifest.json``).
    """
    os.makedirs(out_dir, exist_ok=True)

    topic_files: list[str] = []
    for topic in topics:
        filename = f"{int(topic['sortOrder']):02d}_{topic['id']}.json"
        path = os.path.join(out_dir, filename)
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(topic, handle, ensure_ascii=False, indent=2)
        topic_files.append(filename)

    manifest = {"topicFiles": topic_files}
    manifest_path = os.path.join(out_dir, "manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, ensure_ascii=False, indent=2)

    return manifest
