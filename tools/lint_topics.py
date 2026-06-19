#!/usr/bin/env python3
"""Lint Carambole grammar-topic JSON against the Swift Codable contract.

Mirrors the decode + solvability rules so a bad token bank can't reach the app:
  - valid JSON; required topic + exercise keys present
  - `type` in {conjugate, fillBlank, genderArticle, wordOrder}
  - `inputMode` in {multipleChoice, buildFromTokens}
  - answerTokens is a MULTISET subset of tokenBank (bank chips are single-use by
    index, so a repeated answer token needs that many copies in the bank)
  - multipleChoice has exactly one answer token, present in the bank
  - non-empty translation + hint (the always-on English ease-in)
  - unique exercise ids; topicID matches the topic id
  - manifest lists exactly the present topic files; unique topic ids/sortOrders;
    every prerequisiteID resolves to another topic

Usage: python3 tools/lint_topics.py [carambole/Resources/Topics]
Exit 0 = clean, 1 = errors.
"""
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

VALID_TYPES = {"conjugate", "fillBlank", "genderArticle", "wordOrder"}
VALID_MODES = {"multipleChoice", "buildFromTokens"}
TOPIC_KEYS = {"id", "title", "sortOrder", "prerequisiteID", "ruleNote", "exercises"}
EX_KEYS = {"id", "topicID", "type", "prompt", "answerTokens", "tokenBank",
           "inputMode", "explanation"}


def lint(topics_dir: Path) -> list[str]:
    errors: list[str] = []

    def err(msg: str) -> None:
        errors.append(msg)

    manifest_path = topics_dir / "manifest.json"
    if not manifest_path.exists():
        return [f"missing manifest: {manifest_path}"]

    manifest = json.loads(manifest_path.read_text())
    listed = manifest.get("topicFiles", [])
    on_disk = sorted(p.name for p in topics_dir.glob("*.json")
                     if p.name != "manifest.json")
    if sorted(listed) != on_disk:
        err(f"manifest/disk mismatch: manifest={sorted(listed)} disk={on_disk}")

    topic_ids: dict[str, str] = {}
    sort_orders: dict[int, str] = {}
    prereqs: list[tuple[str, str]] = []  # (topic_id, prerequisiteID)

    for fname in listed:
        path = topics_dir / fname
        if not path.exists():
            err(f"{fname}: listed in manifest but not on disk")
            continue
        try:
            topic = json.loads(path.read_text())
        except json.JSONDecodeError as e:
            err(f"{fname}: invalid JSON — {e}")
            continue

        missing = TOPIC_KEYS - topic.keys()
        if missing:
            err(f"{fname}: missing topic keys {sorted(missing)}")
            continue

        tid = topic["id"]
        if tid in topic_ids:
            err(f"{fname}: duplicate topic id '{tid}' (also {topic_ids[tid]})")
        topic_ids[tid] = fname

        so = topic["sortOrder"]
        if so in sort_orders:
            err(f"{fname}: duplicate sortOrder {so} (also {sort_orders[so]})")
        sort_orders[so] = fname

        if topic["prerequisiteID"] is not None:
            prereqs.append((tid, topic["prerequisiteID"]))

        seen_ex: set[str] = set()
        for ex in topic["exercises"]:
            exid = ex.get("id", "<no-id>")
            tag = f"{fname}:{exid}"

            missing_ex = EX_KEYS - ex.keys()
            if missing_ex:
                err(f"{tag}: missing exercise keys {sorted(missing_ex)}")
                continue

            if exid in seen_ex:
                err(f"{tag}: duplicate exercise id")
            seen_ex.add(exid)

            if ex["topicID"] != tid:
                err(f"{tag}: topicID '{ex['topicID']}' != topic id '{tid}'")
            if ex["type"] not in VALID_TYPES:
                err(f"{tag}: bad type '{ex['type']}'")
            if ex["inputMode"] not in VALID_MODES:
                err(f"{tag}: bad inputMode '{ex['inputMode']}'")

            ans, bank = ex["answerTokens"], ex["tokenBank"]
            if not ans:
                err(f"{tag}: empty answerTokens")
            # multiset subset: each answer token needs enough copies in the bank
            need, have = Counter(ans), Counter(bank)
            for tok, n in need.items():
                if have[tok] < n:
                    err(f"{tag}: token '{tok}' needs {n} in bank, has {have[tok]}")

            if ex["inputMode"] == "multipleChoice" and len(ans) != 1:
                err(f"{tag}: multipleChoice must have exactly 1 answer token, "
                    f"has {len(ans)}")

            for field in ("translation", "hint"):
                val = ex.get(field)
                if not (isinstance(val, str) and val.strip()):
                    err(f"{tag}: empty/missing {field} (English ease-in required)")

    for tid, pre in prereqs:
        if pre not in topic_ids:
            err(f"topic '{tid}': prerequisiteID '{pre}' does not resolve")

    return errors


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
        "carambole/Resources/Topics")
    errors = lint(root)
    if errors:
        print(f"LINT FAILED ({len(errors)} error(s)):")
        for e in errors:
            print(f"  ✗ {e}")
        return 1
    print(f"LINT OK — {root}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
