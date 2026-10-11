"""Validate production En situation modules and their tappable French text.

Run `rtk python3 tools/situations/lint.py --draft --no-audio` during partial
authoring, then without flags after audio generation.
"""

from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[2]
SITUATIONS = ROOT / "carambole/Resources/Situations"
AUDIO = ROOT / "carambole/Resources/Audio"
KINDS = {"comprehend", "reply", "pick", "complete", "fix", "word"}
STANDALONE = {"Construire": "reply", "Choisir le ton": "pick",
              "Corriger": "fix", "Transformer": "reply", "Mot en retour": "complete"}
SPOKEN = {"je sais pas", "t'as", "t'es", "y a", "y a encore", "ouais", "du coup",
          "carrément", "bref", "pas de souci", "top", "ça marche", "on"}
TEXTING = re.compile(r"(?i)(?<!\w)(?:mdr|stp|jsp|slt|svp|ptdr|bjr)(?!\w)")
GENDERED_SELF = re.compile(r"\b(?:je\s+(?:suis|me sens|serai)|j['’](?:étais|ai))\s+"
                          r"(?:\w+\s+){0,3}(?:désolé(?:e)?s?|prêt(?:e)?s?|"
                          r"allé(?:e)?s?|arrivé(?:e)?s?|passé(?:e)?s?|parti(?:e)?s?|"
                          r"venu(?:e)?s?|content(?:e)?s?|fatigué(?:e)?s?)\b", re.I)


def norm(value: str) -> str:
    return value.lower().replace("’", "'").strip(".,!?;:«»… \t\n")


def tokens(value: str) -> list[str]:
    return [norm(t) for t in value.split() if norm(t) and t != "___"]


def contains_phrase(value: str, phrase: str) -> bool:
    hay = tokens(value)
    needle = tokens(phrase)
    return bool(needle) and any(hay[i:i + len(needle)] == needle
                                for i in range(len(hay) - len(needle) + 1))


def unglossed(value: str, keys: set[str]) -> list[str]:
    """Match set phrases longest first, like PilotText.segments in Swift."""
    raw = tokens(value)
    phrases = sorted((k.split() for k in keys), key=len, reverse=True)
    missing = []
    i = 0
    while i < len(raw):
        if raw[i] == "___":
            i += 1
            continue
        match = next((part for part in phrases if raw[i:i + len(part)] == part), None)
        if match:
            i += len(match)
        else:
            missing.append(raw[i])
            i += 1
    return missing


def french_surfaces(item: dict) -> list[str]:
    lines = [turn.get("text", "") for turn in item.get("turns", [])]
    if item.get("followUp"):
        lines.append(item["followUp"])
    for drill in item.get("drills", []):
        kind = drill.get("type")
        if kind == "reply":
            lines += [" ".join(answer) for answer in drill.get("accepted", [])]
        elif kind == "pick":
            lines += drill.get("choices", [])
        elif kind == "complete":
            gaps = [t.get("text", "") for t in item.get("turns", []) if "___" in t.get("text", "")]
            if gaps and isinstance(drill.get("correct"), int):
                choices = drill.get("choices", [])
                if 0 <= drill["correct"] < len(choices):
                    lines.append(gaps[0].replace("___", choices[drill["correct"]]))
    return lines


def exposure_lines(item: dict) -> list[str]:
    """Completed French the learner encounters, excluding distractors."""
    lines = [t.get("text", "") for t in item.get("turns", [])]
    if item.get("followUp"):
        lines.append(item["followUp"])
    for drill in item.get("drills", []):
        kind = drill.get("type")
        choices, correct = drill.get("choices", []), drill.get("correct")
        if kind == "reply":
            lines.extend(" ".join(a) for a in drill.get("accepted", []))
        elif kind == "pick" and isinstance(correct, int) and 0 <= correct < len(choices):
            lines.append(choices[correct])
        elif kind == "complete" and isinstance(correct, int) and 0 <= correct < len(choices):
            lines.extend(t.get("text", "").replace("___", choices[correct])
                         for t in item.get("turns", []) if "___" in t.get("text", ""))
    return lines


def tappable_lines(item: dict) -> list[str]:
    """All French displayed as tokens, including bank and choice distractors."""
    lines = french_surfaces(item)
    for drill in item.get("drills", []):
        if drill.get("type") == "reply":
            lines.extend(drill.get("bank", []))
        elif drill.get("type") == "complete":
            lines.extend(drill.get("choices", []))
        elif drill.get("type") == "fix":
            lines.extend(t["error"].get("choices", []) for t in item.get("turns", []) if "error" in t)
    return [piece for line in lines for piece in (line if isinstance(line, list) else [line])]


def rendered_surfaces(item: dict) -> list[str]:
    """Return every answer as seen in French for a grammar review pass.

    Includes intentionally wrong choice renderings. A grammar checker must
    judge those against each choice's author-written reason, not silently
    treat a distractor's error as a defect in the correct answer.
    """
    rendered = [t.get("text", "") for t in item.get("turns", []) if "___" not in t.get("text", "")]
    if item.get("followUp"):
        rendered.append(item["followUp"])
    gaps = [t.get("text", "") for t in item.get("turns", []) if "___" in t.get("text", "")]
    for turn in item.get("turns", []):
        mark = turn.get("error")
        if mark:
            rendered.append(re.sub(r"\b" + re.escape(mark.get("word", "")) + r"\b",
                                   mark.get("fix", ""), turn["text"], count=1))
    for drill in item.get("drills", []):
        kind = drill.get("type")
        if kind == "complete":
            rendered.extend(gap.replace("___", choice) for gap in gaps for choice in drill.get("choices", []))
        elif kind == "reply":
            rendered.extend(" ".join(answer) for answer in drill.get("accepted", []))
        elif kind == "pick":
            rendered.extend(drill.get("choices", []))
    return rendered


def buildable(answer: list[str], bank: list[str]) -> bool:
    remaining = list(bank)
    for tile in answer:
        if tile not in remaining:
            return False
        remaining.remove(tile)
    return True


def lint_content(module: dict, word_data: dict, audio_dir: Path = AUDIO,
                 *, check_audio: bool = True, draft: bool = False,
                 other_ids: set[str] | None = None) -> list[str]:
    errors: list[str] = []
    word_entries = word_data.get("words", [])
    word_by_key = {norm(w.get("fr", "")): w for w in word_entries}
    keys = set(word_by_key)
    if len(keys) != len(word_entries):
        errors.append("words: duplicate or empty French gloss key")
    for audio_key, count in Counter(w.get("audio") for w in word_entries if w.get("audio")).items():
        if count > 1:
            errors.append(f"words: duplicate audio key '{audio_key}'")
    for word in word_entries:
        key = norm(word.get("fr", ""))
        if not word.get("en") or not word.get("audio") or not isinstance(word.get("spoken"), bool):
            errors.append(f"words: incomplete entry '{key}'")
        if word.get("spoken") and key not in SPOKEN:
            errors.append(f"words: spoken entry '{key}' is not in the spoken list")
        if key in SPOKEN and not word.get("spoken"):
            errors.append(f"words: spoken entry '{key}' must be marked spoken")
        if check_audio and word.get("audio"):
            _audio(errors, audio_dir, word["audio"])

    module_id = module.get("id", "")
    if not re.fullmatch(r"sit_\d{2}", module_id):
        errors.append(f"module: bad ID '{module_id}'")
    if not all(module.get(field) for field in ("title", "arc", "goal")):
        errors.append("module: missing title, arc, or goal")
    seen = set(other_ids or ())
    all_items = []
    introduced: dict[str, list[str]] = {}
    for word in word_entries:
        if word.get("firstSeen"):
            introduced.setdefault(word["firstSeen"], []).append(norm(word.get("fr", "")))
    for element in module.get("elements", []):
        eid = element.get("id", "")
        if not re.fullmatch(re.escape(module_id) + r"_[a-z]+", eid):
            errors.append(f"{eid}: bad element ID")
        if eid in seen:
            errors.append(f"{eid}: duplicate ID")
        seen.add(eid)
        if not element.get("title") or not element.get("note"):
            errors.append(f"{eid}: missing title or note")
        items = element.get("items", [])
        dialogue = [x for x in items if "standalone" not in x]
        alone = [x for x in items if "standalone" in x]
        if not draft and (len(dialogue) != 10 or len(alone) != 5):
            errors.append(f"{eid}: expected 10 dialogues and 5 standalone drills")
        pattern = ["standalone" in x for x in items]
        expected = ([False, False, True] * 5)[:len(items)]
        if pattern != expected or (not draft and len(items) != 15):
            errors.append(f"{eid}: expected D D S session order")
        item_positions = {x.get("id"): n for n, x in enumerate(items)}
        boundary_types = []
        all_dialogue_kinds = []
        for item in items:
            iid = item.get("id", "")
            all_items.append(item)
            solo = "standalone" in item
            suffix = r"s\d{2}" if solo else r"d\d{2}"
            if not re.fullmatch(re.escape(eid) + "_" + suffix, iid):
                errors.append(f"{iid}: bad item ID or sit_ prefix")
            if iid in seen:
                errors.append(f"{iid}: duplicate ID")
            seen.add(iid)
            if not item.get("place") or not item.get("cue"):
                errors.append(f"{iid}: missing place or cue")
            if solo and (not item["place"].endswith("· phrase seule") or
                         item["standalone"] not in STANDALONE):
                errors.append(f"{iid}: bad standalone label or place")
            turns = item.get("turns", [])
            drills = item.get("drills", [])
            if solo:
                if len(turns) > 2 or len(drills) != 1 or "followUp" in item:
                    errors.append(f"{iid}: standalone needs 0–2 lines, one drill, no follow-up")
                if item.get("newWords"):
                    errors.append(f"{iid}: standalone introduces newWords")
                if drills and STANDALONE.get(item["standalone"]) != drills[0].get("type"):
                    errors.append(f"{iid}: standalone label does not match drill type")
            else:
                if not 1 <= len(turns) <= 3 or not 1 <= len(drills) <= 2 or not item.get("followUp"):
                    errors.append(f"{iid}: dialogue needs 1–3 lines, 1–2 drills and follow-up")
                if len(turns) + any(d.get("type") == "reply" for d in drills) > 3:
                    errors.append(f"{iid}: dialogue has over 3 lines with the built reply")
            kinds = [d.get("type") for d in drills]
            if kinds:
                boundary_types.append((kinds[0], kinds[-1]))
            if not solo:
                all_dialogue_kinds.extend(kinds)
            if len(kinds) != len(set(kinds)):
                errors.append(f"{iid}: repeated drill type")
            if {"reply", "pick"} <= set(kinds):
                errors.append(f"{iid}: reply and pick cannot share a dialogue")
            if set(kinds) - KINDS:
                errors.append(f"{iid}: unknown drill type")
            for index, turn in enumerate(turns):
                if turn.get("speaker") not in {"server", "learner"} or not turn.get("text"):
                    errors.append(f"{iid}: bad turn")
                count = len(tokens(turn.get("text", "")))
                if not solo and count > 10:
                    errors.append(f"{iid}: dialogue line over 10 words")
                if solo and not 8 <= count <= 14:
                    errors.append(f"{iid}: standalone line needs 8–14 words")
                if turn.get("speaker") == "server" and check_audio:
                    _audio(errors, audio_dir, f"{iid}_t{index}")
            if not solo and check_audio:
                _audio(errors, audio_dir, f"{iid}_f")
            gaps = sum(t.get("text", "").count("___") for t in turns)
            if gaps != (1 if "complete" in kinds else 0):
                errors.append(f"{iid}: complete needs exactly one gap")
            marked = [t for t in turns if "error" in t]
            if len(marked) != (1 if "fix" in kinds else 0):
                errors.append(f"{iid}: fix needs exactly one error line")
            for turn in marked:
                mark = turn["error"]
                if turn.get("speaker") != "learner" or norm(mark.get("word", "")) not in tokens(turn.get("text", "")):
                    errors.append(f"{iid}: error word not in learner line")
                if mark.get("fix") not in mark.get("choices", []):
                    errors.append(f"{iid}: fix missing from choices")
                if len(set(mark.get("choices", []))) != 3:
                    errors.append(f"{iid}: fix needs 3 distinct choices")
                if not isinstance(mark.get("why"), str) or not mark["why"].strip():
                    errors.append(f"{iid}: fix why must be one line")
                if norm(mark.get("word", "")) in {"prêt", "prête", "allé", "allée", "désolé", "désolée"}:
                    errors.append(f"{iid}: fix targets learner gender")
            for drill in drills:
                _drill(errors, iid, drill)
                if drill.get("type") == "word" and not any(
                    contains_phrase(t.get("text", ""), drill.get("target", "")) for t in turns):
                    errors.append(f"{iid}: word target not in visible turn")
            surface = " ".join(exposure_lines(item))
            if TEXTING.search(surface):
                errors.append(f"{iid}: texting abbreviation")
            for line in [t.get("text", "") for t in turns if t.get("speaker") == "learner"] + [
                d.get("model", "") for d in drills if d.get("type") == "reply"] + [
                d.get("choices", [""])[d["correct"]] for d in drills
                if d.get("type") == "pick" and isinstance(d.get("correct"), int)
                and 0 <= d["correct"] < len(d.get("choices", []))]:
                if GENDERED_SELF.search(line):
                    errors.append(f"{iid}: gendered first-person model needs both forms accepted")
            for word in item.get("newWords", []):
                key = norm(word)
                if key not in keys:
                    errors.append(f"{iid}: newWords '{word}' missing gloss")
                if not contains_phrase(surface, word):
                    errors.append(f"{iid}: newWords '{word}' not in item")
            if iid in introduced:
                for key in introduced[iid]:
                    if key not in {norm(w) for w in item.get("newWords", [])}:
                        errors.append(f"{iid}: '{key}' firstSeen must be listed in newWords")
                    if not any(contains_phrase(t.get("text", ""), key) for t in turns):
                        errors.append(f"{iid}: '{key}' firstSeen must be visible in a turn")
            if solo:
                solo_surfaces = tappable_lines(item)
                for line in solo_surfaces:
                    for missing in set(unglossed(line, keys)):
                        errors.append(f"{iid}: standalone untaught word or missing gloss '{missing}'")
                    for key, entry in word_by_key.items():
                        first = entry.get("firstSeen")
                        if first in item_positions and item_positions[first] >= item_positions[iid] and contains_phrase(line, key):
                            errors.append(f"{iid}: standalone uses '{key}' before it is taught")
            for line in tappable_lines(item):
                for missing in set(unglossed(line, keys)):
                    errors.append(f"{iid}: missing gloss '{missing}'")
        for left, right in zip(boundary_types, boundary_types[1:]):
            if left[-1] == right[0]:
                errors.append(f"{eid}: same drill type back to back")
        if not draft:
            if len(set(all_dialogue_kinds)) < 4:
                errors.append(f"{eid}: dialogues need at least 4 drill types")
            if sum(k in {"reply", "complete"} for k in all_dialogue_kinds) * 2 < len(all_dialogue_kinds):
                errors.append(f"{eid}: reply and complete need at least half the dialogue drills")
            if {x.get("standalone") for x in alone} != set(STANDALONE):
                errors.append(f"{eid}: standalone drills need all five labels")
            clarification = re.compile(r"(?i)\b(?:repeat|clarif|say (?:it|that) again|répétez|répéter|"
                                       r"pouvez-vous redire|ça veut dire quoi|qu'est-ce que ça veut dire)\b")
            if not any(clarification.search(x.get("cue", "") + " " +
                                            " ".join(d.get("prompt", "") for d in x.get("drills", [])) + " " +
                                            " ".join(exposure_lines(x))) for x in dialogue):
                errors.append(f"{eid}: needs a clarification or repetition dialogue")
            social_cast = {"Léa", "Théo", "Inès", "Monsieur Ferrand", "Madame Dumas"}
            other = sum(x.get("place", "") != "Au café" or any(
                t.get("name") in social_cast for t in x.get("turns", [])) for x in dialogue)
            if other < 2:
                errors.append(f"{eid}: needs 2 other-channel or social dialogues")

    positions = {x.get("id"): i for i, x in enumerate(all_items)}
    for item in all_items:
        if "standalone" not in item:
            continue
        for word in word_entries:
            first = word.get("firstSeen")
            if first in positions and positions[first] >= positions[item.get("id")]:
                key = norm(word.get("fr", ""))
                if any(contains_phrase(line, key) for line in tappable_lines(item)):
                    errors.append(f"{item.get('id')}: standalone uses '{key}' before it is taught")
    for word in word_entries:
        first = word.get("firstSeen")
        if first not in positions:
            continue
        key = norm(word.get("fr", ""))
        origin = positions[first]
        for item in all_items[:origin]:
            if any(contains_phrase(line, key) for line in exposure_lines(item)):
                errors.append(f"{item.get('id')}: '{key}' used before firstSeen '{first}'")
        later = all_items[origin + 1:]
        later_dialogues = [x for x in later if "standalone" not in x and
                           any(contains_phrase(line, key) for line in exposure_lines(x))]
        if not draft and len(later_dialogues) < 2:
            errors.append(f"{first}: '{key}' needs two later dialogues")
        if not draft and not any(
            any(d.get("type") == "word" and norm(d.get("target", "")) == key or
                x.get("standalone") == "Mot en retour" and d.get("type") == "complete" and
                isinstance(d.get("correct"), int) and 0 <= d["correct"] < len(d.get("choices", [])) and
                norm(d["choices"][d["correct"]]) == key for d in x.get("drills", []))
            for x in later):
            errors.append(f"{first}: '{key}' needs later Mot or Mot en retour")

    return sorted(set(errors))


def _audio(errors: list[str], directory: Path, key: str) -> None:
    path = directory / f"{key}.mp3"
    if not path.is_file() or path.stat().st_size <= 2000:
        errors.append(f"{key}: missing audio")


def _drill(errors: list[str], iid: str, drill: dict) -> None:
    kind = drill.get("type")
    if not drill.get("prompt"):
        errors.append(f"{iid}: {kind} missing prompt")
    if kind in {"comprehend", "pick", "complete", "word"}:
        choices = drill.get("choices", [])
        need = 2 if kind == "comprehend" else 3
        correct = drill.get("correct")
        if len(choices) != need or len(set(choices)) != need or not isinstance(correct, int) or not 0 <= correct < need:
            errors.append(f"{iid}: {kind} needs {need} distinct choices and valid correct index")
        if kind == "comprehend" and not drill.get("miss"):
            errors.append(f"{iid}: comprehend needs miss note")
        if kind in {"pick", "complete", "word"}:
            why = drill.get("why", [])
            if len(why) != need or any(not why[i] for i in range(need) if i != correct):
                errors.append(f"{iid}: {kind} needs a why-line for each wrong choice")
        if kind == "word" and not drill.get("target"):
            errors.append(f"{iid}: word needs target")
    if kind == "reply":
        bank, accepted, model = drill.get("bank", []), drill.get("accepted", []), drill.get("model", "")
        if not bank or not accepted or any(not answer or not buildable(answer, bank) for answer in accepted):
            errors.append(f"{iid}: accepted reply cannot be built from bank")
        if model not in [" ".join(a) for a in accepted]:
            errors.append(f"{iid}: model is not accepted")


def global_id_errors(modules: list[dict], word_data: dict, book_one_ids: set[str]) -> list[str]:
    """Check IDs that cannot be judged from a single authoring fragment."""
    errors = []
    ids = []
    for module in modules:
        ids.append(module.get("id"))
        for element in module.get("elements", []):
            ids.append(element.get("id"))
            ids.extend(item.get("id") for item in element.get("items", []))
    for identifier, count in Counter(ids).items():
        if count > 1:
            errors.append(f"{identifier}: duplicate ID across modules")
        if identifier in book_one_ids:
            errors.append(f"{identifier}: collides with Book 1 ID")
    item_ids = {item.get("id") for module in modules
                for element in module.get("elements", []) for item in element.get("items", [])}
    for word in word_data.get("words", []):
        first = word.get("firstSeen")
        if first is not None and first not in item_ids:
            errors.append(f"words: firstSeen '{first}' is not a situation item ID")
    return sorted(set(errors))


def book_one_ids() -> set[str]:
    topics = ROOT / "carambole/Resources/Topics"
    manifest = json.loads((topics / "manifest.json").read_text(encoding="utf-8"))
    ids = set()
    for file in manifest["moduleFiles"]:
        module = json.loads((topics / file).read_text(encoding="utf-8"))
        ids.add(module["id"])
        for element in module.get("elements", []):
            ids.add(element["id"])
            ids.update(example["id"] for example in element.get("examples", []))
    return ids


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-audio", action="store_true", help="authoring pass before TTS")
    parser.add_argument("--draft", action="store_true", help="allow incomplete element counts and word recurrence")
    parser.add_argument("--module", type=Path, help="lint one module; default: manifest modules")
    parser.add_argument("--words", type=Path, help="words file; default: production words.json")
    args = parser.parse_args()
    manifest_path = SITUATIONS / "situations_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("book") != "fr_en_situation":
        print("situations_manifest.json: wrong book ID", file=sys.stderr)
        return 1
    words = json.loads((args.words or SITUATIONS / "words.json").read_text(encoding="utf-8"))
    files = [args.module] if args.module else [SITUATIONS / f for f in manifest.get("moduleFiles", [])]
    all_errors = []
    modules = []
    used = set()
    for file in files:
        module = json.loads(file.read_text(encoding="utf-8"))
        if args.draft and "id" not in module and "elements" in module:
            module = {"id": "sit_06", "title": "Au café", "arc": "Le quartier",
                      "goal": "Use French at the café.", **module}
        modules.append(module)
        all_errors += lint_content(module, words, check_audio=not args.no_audio,
                                   draft=args.draft, other_ids=used)
        used |= {module.get("id")} | {e.get("id") for e in module.get("elements", [])} | {
            x.get("id") for e in module.get("elements", []) for x in e.get("items", [])}
    if not args.draft and not args.module:
        all_errors += global_id_errors(modules, words, book_one_ids())
    for error in all_errors:
        print(error)
    if all_errors:
        print(f"{len(all_errors)} error(s)", file=sys.stderr)
        return 1
    print(f"OK: {len(files)} situation module(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
