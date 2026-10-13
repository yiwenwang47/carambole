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

sys.path.append(str(Path(__file__).resolve().parent))
from sitbook import (  # noqa: E402
    CONFIG, MODULE_ID, ROOT, SITUATIONS, item_ranks, load_config,
    load_manifest_modules, module_number, read_json,
)

AUDIO = ROOT / "carambole/Resources/Audio"
KINDS = {"comprehend", "reply", "pick", "complete", "fix", "word"}
STANDALONE = {"Construire": "reply", "Choisir le ton": "pick",
              "Corriger": "fix", "Transformer": "reply", "Mot en retour": "complete"}
SPOKEN = {"je sais pas", "t'as", "t'es", "y a", "y a encore", "ouais", "du coup",
          "carrément", "bref", "pas de souci", "top", "ça marche", "on",
          "dispo", "dispos", "boulot", "t'inquiète"}
# Canonical cast `name` strings; the audio CAST map uses the same keys.
SOCIAL_CAST = {"Léa", "Théo", "Inès", "M. Ferrand", "Mme Dumas"}
CAST_ALIASES = {"Monsieur Ferrand": "M. Ferrand", "Madame Dumas": "Mme Dumas",
                "Ines": "Inès", "Lea": "Léa", "Theo": "Théo"}
VOICES = {"male", "female"}
# `role` is the display-only French label above an unnamed server bubble
# (« Vendeuse », « Livreur », « Messagerie »). One capitalised French noun
# phrase: letters, spaces, apostrophes and hyphens.
ROLE = re.compile(r"^[A-ZÀÂÇÉÈÊËÎÏÔÛÙÜŸŒÆ][a-zàâçéèêëîïôûùüÿœæ'’ -]*$")
# Gendered roles must match the turn's voice (`voice: "female"` → feminine).
FEMININE_ROLES = {"Vendeuse", "Serveuse", "Boulangère", "Marchande", "Voisine",
                  "Passante", "Livreuse", "Pharmacienne", "Caissière",
                  "Conseillère", "Coiffeuse", "Employée", "Voyageuse", "Gardienne",
                  "Agente immobilière"}
MASCULINE_ROLES = {"Vendeur", "Serveur", "Boulanger", "Marchand", "Voisin",
                   "Passant", "Livreur", "Pharmacien", "Caissier",
                   "Conseiller", "Coiffeur", "Employé", "Voyageur", "Gardien",
                   "Agent immobilier"}
TEXTING = re.compile(r"(?i)(?<!\w)(?:mdr|stp|jsp|slt|svp|ptdr|bjr)(?!\w)")
# Robin, the learner, is a woman (user decision 2026-10-11): her own lines use
# feminine agreement only. Flags a masculine first-person form in a learner
# line, an accepted reply, or a correct pick.
MASC_SELF = re.compile(r"(?:\b(?:je\s+(?:suis|me\s+suis|me sens|serai)|j['’](?:étais|ai été))\s+"
                       r"(?:\w+\s+){0,3}(?:désolé|prêt|allé|arrivé|passé|parti|venu|"
                       r"content|fatigué|sorti|rentré|resté|occupé|ravi|américain|"
                       r"couché|tombé|épuisé|trempé|convaincu|sûr)s?"
                       r"|(?:^|[.!?,]\s*)(?:enchanté|désolé|ravi)s?)(?![\wé])", re.I)


def corrected(turn: dict) -> str:
    """A turn's text with its Corriger error word replaced by the fix."""
    text, mark = turn.get("text", ""), turn.get("error")
    if not mark:
        return text
    return re.sub(r"\b" + re.escape(mark.get("word", "")) + r"\b", mark.get("fix", ""), text, count=1)


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


def _hay(lines: list[str]) -> str:
    """Token-joined lines; a phrase matches when `_needle(phrase)` is a substring."""
    return "\n".join(" " + " ".join(tokens(line)) + " " for line in lines)


def _needle(phrase: str) -> str:
    parts = tokens(phrase)
    return " " + " ".join(parts) + " " if parts else ""


def word_errors(word_data: dict, audio_dir: Path = AUDIO, *, check_audio: bool = True) -> list[str]:
    """Checks on the book-wide words file itself (run once per lint)."""
    errors: list[str] = []
    word_entries = word_data.get("words", [])
    keys = {norm(w.get("fr", "")) for w in word_entries}
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
    return errors


def _role_errors(iid: str, turn: dict, draft: bool) -> list[str]:
    """`role` labels an unnamed server turn; strict mode requires one there."""
    unnamed_server = turn.get("speaker") == "server" and not turn.get("name")
    if "role" not in turn:
        return [] if draft or not unnamed_server else [
            f"{iid}: unnamed server turn needs a role (« Vendeuse », « Livreur »…)"]
    role = turn["role"]
    if not unnamed_server:
        return [f"{iid}: role is only for an unnamed server turn"]
    if not isinstance(role, str) or not ROLE.match(role):
        return [f"{iid}: role '{role}' must be a capitalised French label"]
    female = turn.get("voice") == "female"
    if female and role in MASCULINE_ROLES or not female and role in FEMININE_ROLES:
        return [f"{iid}: role '{role}' does not match the turn's {'female' if female else 'male'} voice"]
    return []


def lint_content(module: dict, word_data: dict, audio_dir: Path = AUDIO,
                 *, check_audio: bool = True, draft: bool = False,
                 other_ids: set[str] | None = None,
                 book_ranks: dict[str, tuple] | None = None,
                 check_words: bool = True) -> list[str]:
    """Lint one module against the book-wide words file.

    `book_ranks` maps the other modules' item IDs to their book position
    (`sitbook.item_ranks`). Without it, a firstSeen in another module is
    ordered by its module number alone.
    """
    errors: list[str] = word_errors(word_data, audio_dir, check_audio=check_audio) if check_words else []
    word_entries = word_data.get("words", [])
    word_by_key = {norm(w.get("fr", "")): w for w in word_entries}
    keys = set(word_by_key)

    module_id = module.get("id", "")
    if not MODULE_ID.fullmatch(module_id):
        errors.append(f"module: bad ID '{module_id}'")
    if not all(module.get(field) for field in ("title", "arc", "goal")):
        errors.append("module: missing title, arc, or goal")
    seen = set(other_ids or ())
    introduced: dict[str, list[str]] = {}
    for word in word_entries:
        if word.get("firstSeen"):
            introduced.setdefault(word["firstSeen"], []).append(norm(word.get("fr", "")))
    home_place = Counter(x.get("place", "") for element in module.get("elements", [])
                         for x in element.get("items", []) if "standalone" not in x).most_common(1)
    home_place = home_place[0][0] if home_place else ""
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
        boundary_types = []
        all_dialogue_kinds = []
        for item in items:
            iid = item.get("id", "")
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
                if turn.get("name") in CAST_ALIASES:
                    errors.append(f"{iid}: use canonical cast name '{CAST_ALIASES[turn['name']]}'")
                if "voice" in turn and (turn["voice"] not in VOICES or turn.get("name")
                                        or turn.get("speaker") != "server"):
                    errors.append(f"{iid}: voice is only 'male' or 'female' on an unnamed server turn")
                errors += _role_errors(iid, turn, draft)
                count = len(tokens(turn.get("text", "")))
                if not solo and count > 10:
                    errors.append(f"{iid}: dialogue line over 10 words")
                if solo and not 8 <= count <= 14:
                    errors.append(f"{iid}: standalone line needs 8–14 words")
                if turn.get("speaker") == "server" and check_audio:
                    _audio(errors, audio_dir, f"{iid}_t{index}")
            if not solo and check_audio:
                _audio(errors, audio_dir, f"{iid}_f")
            if "followUpRole" in item and (solo or item.get("followUpBy")
                                           or not ROLE.match(str(item["followUpRole"]))):
                errors.append(f"{iid}: followUpRole is a capitalised French role on a dialogue without followUpBy")
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
            for drill in drills:
                _drill(errors, iid, drill)
                if drill.get("type") == "word" and not any(
                    contains_phrase(t.get("text", ""), drill.get("target", "")) for t in turns):
                    errors.append(f"{iid}: word target not in visible turn")
            surface = " ".join(exposure_lines(item))
            if TEXTING.search(surface):
                errors.append(f"{iid}: texting abbreviation")
            # A Corriger error line may hold Robin's wrong (masculine) agreement on
            # purpose: check it with the fix applied, so only the answer must be feminine.
            for line in [corrected(t) for t in turns if t.get("speaker") == "learner"] + [
                " ".join(a) for d in drills if d.get("type") == "reply" for a in d.get("accepted", [])] + [
                d.get("choices", [""])[d["correct"]] for d in drills
                if d.get("type") == "pick" and isinstance(d.get("correct"), int)
                and 0 <= d["correct"] < len(d.get("choices", []))]:
                if MASC_SELF.search(line):
                    errors.append(f"{iid}: masculine first-person form (Robin is a woman)")
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
            clarification = re.compile(r"(?i)\b(?:repeat|clarif\w*|say (?:it|that) again|répétez|répéter|"
                                       r"pouvez-vous redire|ça veut dire quoi|qu'est-ce que ça veut dire)\b")
            if not any(clarification.search(x.get("cue", "") + " " +
                                            " ".join(d.get("prompt", "") for d in x.get("drills", [])) + " " +
                                            " ".join(exposure_lines(x))) for x in dialogue):
                errors.append(f"{eid}: needs a clarification or repetition dialogue")
            other = sum(x.get("place", "") != home_place or any(
                t.get("name") in SOCIAL_CAST for t in x.get("turns", [])) for x in dialogue)
            if other < 2:
                errors.append(f"{eid}: needs 2 other-channel or social dialogues")

    errors += _order_errors(module, word_entries, book_ranks, draft)
    return sorted(set(errors))


def _order_errors(module: dict, word_entries: list[dict],
                  book_ranks: dict[str, tuple] | None, draft: bool) -> list[str]:
    """Book-wide "no word before its firstSeen" and in-module recurrence gates."""
    errors: list[str] = []
    number = module_number(module.get("id")) or 0
    all_items = [x for element in module.get("elements", []) for x in element.get("items", [])]
    ranks = {iid: rank for iid, rank in (book_ranks or {}).items() if rank[0] != number}
    positions = {}
    for index, item in enumerate(all_items):
        positions.setdefault(item.get("id"), index)
    for iid, rank in item_ranks([module]).items():
        ranks.setdefault(iid, rank)
    exposure = [_hay(exposure_lines(x)) for x in all_items]
    tappable = [_hay(tappable_lines(x)) if "standalone" in x else "" for x in all_items]
    for word in word_entries:
        first = word.get("firstSeen")
        if not first:
            continue
        key = norm(word.get("fr", ""))
        needle = _needle(key)
        if not needle:
            continue
        origin = ranks.get(first)
        if origin is None:
            first_module = module_number(first)
            if first_module is None or first_module == number:
                continue  # unknown item: global_id_errors reports it
            origin = (first_module,)
        for index, item in enumerate(all_items):
            rank = ranks[item.get("id")]
            if rank < origin and needle in exposure[index]:
                errors.append(f"{item.get('id')}: '{key}' used before firstSeen '{first}'")
            if "standalone" in item and rank <= origin and needle in tappable[index]:
                errors.append(f"{item.get('id')}: standalone uses '{key}' before it is taught")
        if draft or first not in positions:
            continue
        later = all_items[positions[first] + 1:]
        later_dialogues = [x for x in later if "standalone" not in x and
                           any(contains_phrase(line, key) for line in exposure_lines(x))]
        if len(later_dialogues) < 2:
            errors.append(f"{first}: '{key}' needs two later dialogues")
        if not any(
            any(d.get("type") == "word" and norm(d.get("target", "")) == key or
                x.get("standalone") == "Mot en retour" and d.get("type") == "complete" and
                isinstance(d.get("correct"), int) and 0 <= d["correct"] < len(d.get("choices", [])) and
                norm(d["choices"][d["correct"]]) == key for d in x.get("drills", []))
            for x in later):
            errors.append(f"{first}: '{key}' needs later Mot or Mot en retour")
    return errors


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


def _fill_fragment(module: dict) -> dict:
    """Give a draft fragment (only `elements`) its module header from modules.json."""
    if "id" in module or "elements" not in module:
        return module
    first = next((e.get("id", "") for e in module["elements"]), "")
    number = module_number(first)
    header = {"id": f"sit_{number:02}" if number else "sit_06", "title": "Au café",
              "arc": "Le quartier", "goal": "Use French at the café."}
    if number and CONFIG.is_file():
        entry = load_config().get(f"{number:02}")
        if entry:
            header = {field: entry[field] for field in ("id", "title", "arc", "goal")}
    return {**header, **module}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-audio", action="store_true", help="authoring pass before TTS")
    parser.add_argument("--draft", action="store_true", help="allow incomplete element counts and word recurrence")
    parser.add_argument("--module", type=Path, help="lint one module file (in book context); default: all manifest modules")
    parser.add_argument("--words", type=Path, help="words file; default: production words.json")
    args = parser.parse_args()
    manifest = read_json(SITUATIONS / "situations_manifest.json")
    if manifest.get("book") != "fr_en_situation":
        print("situations_manifest.json: wrong book ID", file=sys.stderr)
        return 1
    words = read_json(args.words or SITUATIONS / "words.json")
    book = load_manifest_modules()
    if args.module:
        module = read_json(args.module)
        if args.draft:
            module = _fill_fragment(module)
        targets = [module]
        context = [m for m in book if m.get("id") != module.get("id")]
    else:
        targets, context = book, []
    ranks = item_ranks(context + targets)
    all_errors = word_errors(words, check_audio=not args.no_audio)
    used: set[str] = set()
    for module in targets:
        all_errors += lint_content(module, words, check_audio=not args.no_audio,
                                   draft=args.draft, other_ids=used,
                                   book_ranks=ranks, check_words=False)
        used |= {module.get("id")} | {e.get("id") for e in module.get("elements", [])} | {
            x.get("id") for e in module.get("elements", []) for x in e.get("items", [])}
    if not args.draft and not args.module:
        all_errors += global_id_errors(targets, words, book_one_ids())
    for error in all_errors:
        print(error)
    if all_errors:
        print(f"{len(all_errors)} error(s)", file=sys.stderr)
        return 1
    print(f"OK: {len(targets)} situation module(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
