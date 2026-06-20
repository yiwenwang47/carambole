#!/usr/bin/env python3
"""Lint Carambole course JSON against the Swift Codable contract + content policy.

Content is a Book → Module → Element → Example tree, one JSON file per module
(see `ContentLoader` ModuleDTO/ElementDTO/ExampleDTO). This mirrors the decode +
solvability rules so a bad token bank or malformed module can't reach the app:

  Decode contract
  - valid JSON; required module / element / example keys present
  - `type` in {conjugate, fillBlank, genderArticle, wordOrder}
  - `inputMode` in {multipleChoice, buildFromTokens}
  - answerTokens is a MULTISET subset of tokenBank (bank chips are single-use by
    index, so a repeated answer token needs that many copies in the bank)
  - multipleChoice has exactly one answer token
  - non-empty translation + hint (the always-on English ease-in)
  - globally-unique module / element / example ids; element.moduleID is implicit
    (injected by the loader), so it is NOT required in JSON
  - manifest lists exactly the present module files; unique module sortOrders;
    unique element sortOrders within a module

  Content policy
  - each module has exactly 20 elements
  - each element has at least 5 examples
  - a freeText (typed) answer carries no punctuation the learner would type
    (`. , ? ! ; : « » … " ( )`) — see Exercise.isTypeable

Usage: python3 tools/lint_topics.py [carambole/Resources/Topics]
Exit 0 = clean, 1 = errors.
"""
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

# Punctuation a learner would have to type — barred from any typed answer
# (mirrors Exercise.untypeablePunctuation). Apostrophes/hyphens are intra-word.
UNTYPEABLE_PUNCT = set('.,?!;:«»…"()')

VALID_TYPES = {"conjugate", "fillBlank", "genderArticle", "wordOrder"}
VALID_MODES = {"multipleChoice", "buildFromTokens", "freeText"}
MODULE_KEYS = {"id", "sortOrder", "title", "ruleNote", "elements"}
ELEMENT_KEYS = {"id", "sortOrder", "label", "ruleNote", "examples"}
EXAMPLE_KEYS = {"id", "type", "prompt", "answerTokens", "tokenBank",
                "inputMode", "explanation"}

ELEMENTS_PER_MODULE = 20
MIN_EXAMPLES_PER_ELEMENT = 5


def lint(content_dir: Path) -> list[str]:
    errors: list[str] = []

    def err(msg: str) -> None:
        errors.append(msg)

    manifest_path = content_dir / "manifest.json"
    if not manifest_path.exists():
        return [f"missing manifest: {manifest_path}"]

    manifest = json.loads(manifest_path.read_text())
    listed = manifest.get("moduleFiles", [])
    on_disk = sorted(p.name for p in content_dir.glob("*.json")
                     if p.name != "manifest.json")
    if sorted(listed) != on_disk:
        err(f"manifest/disk mismatch: manifest={sorted(listed)} disk={on_disk}")

    module_ids: dict[str, str] = {}
    module_orders: dict[int, str] = {}
    element_ids: dict[str, str] = {}   # element id -> "file:elementId"
    example_ids: dict[str, str] = {}   # example id -> "file:exampleId"

    for fname in listed:
        path = content_dir / fname
        if not path.exists():
            err(f"{fname}: listed in manifest but not on disk")
            continue
        try:
            module = json.loads(path.read_text())
        except json.JSONDecodeError as e:
            err(f"{fname}: invalid JSON — {e}")
            continue

        missing = MODULE_KEYS - module.keys()
        if missing:
            err(f"{fname}: missing module keys {sorted(missing)}")
            continue

        mid = module["id"]
        if mid in module_ids:
            err(f"{fname}: duplicate module id '{mid}' (also {module_ids[mid]})")
        module_ids[mid] = fname

        mso = module["sortOrder"]
        if mso in module_orders:
            err(f"{fname}: duplicate module sortOrder {mso} (also {module_orders[mso]})")
        module_orders[mso] = fname

        elements = module["elements"]
        if len(elements) != ELEMENTS_PER_MODULE:
            err(f"{fname}: module has {len(elements)} elements, expected {ELEMENTS_PER_MODULE}")

        el_orders: dict[int, str] = {}
        for el in elements:
            eid = el.get("id", "<no-id>")
            etag = f"{fname}:{eid}"

            missing_el = ELEMENT_KEYS - el.keys()
            if missing_el:
                err(f"{etag}: missing element keys {sorted(missing_el)}")
                continue

            if eid in element_ids:
                err(f"{etag}: duplicate element id (also {element_ids[eid]})")
            element_ids[eid] = etag

            eso = el["sortOrder"]
            if eso in el_orders:
                err(f"{etag}: duplicate element sortOrder {eso} in module (also {el_orders[eso]})")
            el_orders[eso] = etag

            examples = el["examples"]
            if len(examples) < MIN_EXAMPLES_PER_ELEMENT:
                err(f"{etag}: {len(examples)} examples, need >= {MIN_EXAMPLES_PER_ELEMENT}")

            for ex in examples:
                xid = ex.get("id", "<no-id>")
                tag = f"{fname}:{xid}"

                missing_ex = EXAMPLE_KEYS - ex.keys()
                if missing_ex:
                    err(f"{tag}: missing example keys {sorted(missing_ex)}")
                    continue

                if xid in example_ids:
                    err(f"{tag}: duplicate example id (also {example_ids[xid]})")
                example_ids[xid] = tag

                if ex["type"] not in VALID_TYPES:
                    err(f"{tag}: bad type '{ex['type']}'")
                if ex["inputMode"] not in VALID_MODES:
                    err(f"{tag}: bad inputMode '{ex['inputMode']}'")

                ans, bank = ex["answerTokens"], ex["tokenBank"]
                if not ans:
                    err(f"{tag}: empty answerTokens")
                # freeText is typed — no token bank to validate against.
                if ex["inputMode"] != "freeText":
                    # multiset subset: each answer token needs enough copies in bank
                    need, have = Counter(ans), Counter(bank)
                    for tok, n in need.items():
                        if have[tok] < n:
                            err(f"{tag}: token '{tok}' needs {n} in bank, "
                                f"has {have[tok]}")

                if ex["inputMode"] == "multipleChoice" and len(ans) != 1:
                    err(f"{tag}: multipleChoice must have exactly 1 answer token, "
                        f"has {len(ans)}")

                # HARD RULE: a typing answer must never contain punctuation the
                # learner would have to type (mirrors Exercise.isTypeable). Only
                # freeText is unconditionally typed; the auto-shuffle skips any
                # punctuated answer at runtime, so this guards explicit authoring.
                if ex["inputMode"] == "freeText":
                    bad = sorted({c for t in ans for c in t
                                  if c in UNTYPEABLE_PUNCT})
                    if bad:
                        err(f"{tag}: freeText answer must not contain "
                            f"punctuation {bad} (learner would type it) — "
                            f"answer={ans}")

                for field in ("translation", "hint"):
                    val = ex.get(field)
                    if not (isinstance(val, str) and val.strip()):
                        err(f"{tag}: empty/missing {field} (English ease-in required)")

                # The post-answer banner is bilingual: French `explanation` plus a
                # parallel English `explanationEN`. Every example must carry one.
                en = ex.get("explanationEN")
                if not (isinstance(en, str) and en.strip()):
                    err(f"{tag}: empty/missing explanationEN (bilingual "
                        f"post-answer explanation required)")

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
