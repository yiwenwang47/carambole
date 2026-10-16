"""Build and validate Book 3 production module JSON from reviewed cards."""

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "carambole/Debug"
OUTPUT = ROOT / "carambole/Resources/Nuances"
FORMATS = {"word", "dialogue", "microtext", "rewrite"}
PUNCTUATION = set(".,?!;:«»…\"()")


def package_module(cards: list[dict], metadata: dict) -> dict:
    number = metadata["number"]
    module_id = f"nu_{number:02d}"
    if metadata["id"] != module_id or len(metadata["groups"]) != 5:
        raise ValueError(f"{module_id}: bad module identity or group count")
    if not metadata["title"].strip() or not metadata["goal"].strip():
        raise ValueError(f"{module_id}: empty title or goal")
    out = []
    cursor = 0
    for index, group in enumerate(metadata["groups"], 1):
        count = group["count"]
        if not isinstance(count, int) or not 4 <= count <= 7:
            raise ValueError(f"{module_id}: group {index} needs 4–7 cards")
        if not group["label"].strip() or not group["note"].strip():
            raise ValueError(f"{module_id}: group {index} has no label or note")
        chosen = cards[cursor:cursor + count]
        if len(chosen) != count:
            raise ValueError(f"{module_id}: group {index} exceeds card count")
        out.append({"id": f"{module_id}_e{index:02d}", "title": group["label"],
                    "note": group["note"], "cards": chosen})
        cursor += count
    if cursor != len(cards):
        raise ValueError(f"{module_id}: {len(cards) - cursor} unassigned cards")
    return {"id": module_id, "number": number, "title": metadata["title"],
            "goal": metadata["goal"], "elements": out}


def validate_course(modules: list[dict], *, strict_counts: bool = True) -> None:
    ids: set[str] = set()
    element_ids: set[str] = set()
    total = 0
    for module in modules:
        module_id = module["id"]
        formats: set[str] = set()
        for element in module["elements"]:
            element_id = element["id"]
            if element_id in element_ids:
                raise ValueError(f"duplicate element {element_id}")
            element_ids.add(element_id)
            for card in element["cards"]:
                card_id = card["id"]
                if card_id in ids:
                    raise ValueError(f"duplicate card {card_id}")
                ids.add(card_id)
                total += 1
                if not card_id.startswith(f"b3_{module['number']:02d}_"):
                    raise ValueError(f"{card_id}: wrong module prefix")
                if card["format"] not in FORMATS:
                    raise ValueError(f"{card_id}: bad format")
                formats.add(card["format"])
                source = card["source"]
                if not source or any(not line["text"].strip() for line in source):
                    raise ValueError(f"{card_id}: missing French source")
                if any(bool(line.get("speaker")) != (card["format"] == "dialogue") for line in source):
                    raise ValueError(f"{card_id}: speaker mismatch")
                if sum(len(line["text"]) for line in source) > 350:
                    raise ValueError(f"{card_id}: source too long")
                if not card["task"].strip() or len(card["task"]) > 150:
                    raise ValueError(f"{card_id}: missing or long task")
                if not card["feedback"].strip():
                    raise ValueError(f"{card_id}: missing feedback")
                response = card["response"]
                if response["kind"] == "choices":
                    choices = response.get("choices", [])
                    if len(choices) != 3 or len(set(choices)) != 3 or response["answer"] not in choices:
                        raise ValueError(f"{card_id}: bad choices")
                    if "accepted" in response:
                        raise ValueError(f"{card_id}: choices have typed variants")
                elif response["kind"] == "typed":
                    accepted = response.get("accepted", [])
                    if not accepted or response["answer"] not in accepted or "choices" in response:
                        raise ValueError(f"{card_id}: bad typed variants")
                    if any(len(a) > 120 or any(ch in PUNCTUATION for ch in a) for a in accepted):
                        raise ValueError(f"{card_id}: long or punctuated typed answer")
                else:
                    raise ValueError(f"{card_id}: bad response kind")
        if strict_counts and (len(module["elements"]) != 5 or formats != FORMATS):
            raise ValueError(f"{module_id}: missing group or format")
    if strict_counts and (len(modules) != 20 or len(element_ids) != 100 or total != 550):
        raise ValueError(f"expected 20 modules, 100 groups, 550 cards; got "
                         f"{len(modules)}, {len(element_ids)}, {total}")


def build() -> list[dict]:
    metadata: list[dict] = []
    for name in ("module_groups_01_10.json", "module_groups_11_20.json"):
        metadata.extend(json.loads((Path(__file__).parent / name).read_text())["modules"])
    if [m["number"] for m in metadata] != list(range(1, 21)):
        raise ValueError("metadata must contain modules 01–20 in order")
    modules = []
    for entry in metadata:
        number = entry["number"]
        name = "testbook_book3.json" if number == 1 else f"testbook_book3_{number:02d}.json"
        cards = json.loads((SOURCE / name).read_text())
        modules.append(package_module(cards, entry))
    validate_course(modules)
    return modules


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="validate sources and generated files")
    args = parser.parse_args()
    modules = build()
    files = [f"nuances_{module['number']:02d}.json" for module in modules]
    manifest = {"book": "book_fr_nuances", "moduleFiles": files}
    if args.check:
        if json.loads((OUTPUT / "nuances_manifest.json").read_text()) != manifest:
            raise ValueError("stale nuances manifest")
        for module, name in zip(modules, files):
            if json.loads((OUTPUT / name).read_text()) != module:
                raise ValueError(f"stale production module {name}")
    else:
        OUTPUT.mkdir(parents=True, exist_ok=True)
        (OUTPUT / "nuances_manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
        for module, name in zip(modules, files):
            (OUTPUT / name).write_text(json.dumps(module, ensure_ascii=False, indent=2) + "\n")
    print(f"Nuances content: {len(modules)} modules, "
          f"{sum(len(m['elements']) for m in modules)} groups, "
          f"{sum(len(e['cards']) for m in modules for e in m['elements'])} cards validated")


if __name__ == "__main__":
    main()
