#!/usr/bin/env python3
"""Generate production Book 2 audio and optional Test book review audio.

Production mode covers every module in situations_manifest.json (book order)
plus the book-wide words.json; `--module NN` limits it to one module's turns,
follow-ups and the words first taught in that module. Existing MP3 files are
left in place. Each new clip is loudness-normalised and de-harshed right
after it is written (`normalize_audio.py`). Credentials are read by the pilot TTS client in-process and are
never printed.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/pilot"))
from generate_audio import CAST, access_token, synthesize  # noqa: E402

sys.path.append(str(ROOT / "tools/situations"))
from sitbook import SITUATIONS, load_manifest_modules, module_number  # noqa: E402
from normalize_audio import process_file, require_codec  # noqa: E402

WORDS = SITUATIONS / "words.json"
PILOT = ROOT / "carambole/Debug/testbook_situation.json"
OUT = ROOT / "carambole/Resources/Audio"
OVERRIDES = ROOT / "tools/situations/tts_overrides.json"
MALE = "fr-FR-Neural2-G"
FEMALE = "fr-FR-Neural2-F"


def turn_voice(turn: dict) -> str:
    """Cast voice by name; an unnamed server may ask for `voice: "female"`."""
    if turn.get("name") in CAST:
        return CAST[turn["name"]]
    return FEMALE if turn.get("voice") == "female" else MALE


def item_clips(item: dict, prefix: str = "") -> list[tuple[str, str, str]]:
    stem = prefix + item["id"]
    servers = [turn for turn in item["turns"] if turn["speaker"] == "server"]
    rows = [(f"{stem}_t{i}", turn["text"].replace("___", "…"), turn_voice(turn))
            for i, turn in enumerate(item["turns"]) if turn["speaker"] == "server"]
    if item.get("followUp"):
        if item.get("followUpBy"):
            voice = turn_voice({"name": item["followUpBy"]})
        else:
            named = next((turn for turn in servers if turn.get("name")), None)
            voice = turn_voice(named or (servers[0] if servers else {}))
        rows.append((f"{stem}_f", item["followUp"], voice))
    return rows


def production_clips(modules: dict | list[dict], words: dict,
                     only: int | None = None) -> list[tuple[str, str, str]]:
    """Turn and follow-up clips in book order, then word clips.

    `only` keeps one module number: its items and the words it first teaches.
    """
    if isinstance(modules, dict):
        modules = [modules]
    if only is not None:
        modules = [m for m in modules if module_number(m.get("id")) == only]
    rows = [clip for module in modules for element in module["elements"]
            for item in element["items"] for clip in item_clips(item)]
    rows.extend((word["audio"], word["fr"], MALE) for word in words["words"]
                if only is None or module_number(word.get("firstSeen")) == only)
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--review", action="store_true", help="generate pilot2_* clips for the nine-card review")
    parser.add_argument("--limit", type=int, help="maximum number of clips to inspect or generate")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--module", type=int, metavar="NN", help="only this module's clips and its taught words")
    args = parser.parse_args()
    if args.review:
        items = json.loads(PILOT.read_text(encoding="utf-8"))["dialogues"]
        rows = [clip for item in items for clip in item_clips(item, "pilot2_")]
    else:
        modules = load_manifest_modules()
        if args.module is not None and not any(module_number(m.get("id")) == args.module for m in modules):
            raise SystemExit(f"module {args.module:02} is not in situations_manifest.json")
        words = json.loads(WORDS.read_text(encoding="utf-8"))
        rows = production_clips(modules, words, args.module)
    if args.limit is not None:
        rows = rows[:args.limit]
    if len({stem for stem, _, _ in rows}) != len(rows):
        raise ValueError("duplicate audio keys")
    todo = [row for row in rows if not (OUT / (row[0] + ".mp3")).exists()]
    print(f"audio: {len(rows) - len(todo)}/{len(rows)} present; {len(todo)} missing")
    if args.dry_run or not todo:
        return
    require_codec()
    OUT.mkdir(parents=True, exist_ok=True)
    token = access_token()
    # Display text -> text sent to TTS, e.g. "!" -> "." where the exclamation came out too loud.
    spoken = json.loads(OVERRIDES.read_text(encoding="utf-8")) if OVERRIDES.exists() else {}
    for stem, text, voice in todo:
        audio = synthesize(spoken.get(text, text), voice, token)
        (OUT / f"{stem}.mp3").write_bytes(audio)
        result = process_file(OUT / f"{stem}.mp3")
        print(f"{stem}.mp3 {len(audio)} bytes; {result.before.lufs:.1f} LUFS -> {result.plan.gain_db:+.1f} dB"
              + (f", shelf {result.plan.shelf_db:.1f} dB" if result.plan.shelf_db else ""))


if __name__ == "__main__":
    main()
