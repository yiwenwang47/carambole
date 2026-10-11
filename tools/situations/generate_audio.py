#!/usr/bin/env python3
"""Generate production Book 2 audio and optional Test book review audio.

Existing MP3 files are left in place. Credentials are read by the pilot TTS
client in-process and are never printed.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/pilot"))
from generate_audio import access_token, synthesize, voice_for  # noqa: E402

MODULE = ROOT / "carambole/Resources/Situations/06_au_cafe.json"
WORDS = ROOT / "carambole/Resources/Situations/words.json"
PILOT = ROOT / "carambole/Debug/testbook_situation.json"
OUT = ROOT / "carambole/Resources/Audio"
MALE = "fr-FR-Neural2-G"


def item_clips(item: dict, prefix: str = "") -> list[tuple[str, str, str]]:
    stem = prefix + item["id"]
    rows = [(f"{stem}_t{i}", turn["text"].replace("___", "…"), voice_for(turn.get("name")))
            for i, turn in enumerate(item["turns"]) if turn["speaker"] == "server"]
    if item.get("followUp"):
        by = item.get("followUpBy") or next(
            (turn.get("name") for turn in item["turns"]
             if turn["speaker"] == "server" and turn.get("name")), None)
        rows.append((f"{stem}_f", item["followUp"], voice_for(by)))
    return rows


def production_clips(module: dict, words: dict) -> list[tuple[str, str, str]]:
    rows = [clip for element in module["elements"] for item in element["items"]
            for clip in item_clips(item)]
    rows.extend((word["audio"], word["fr"], MALE) for word in words["words"])
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--review", action="store_true", help="generate pilot2_* clips for the nine-card review")
    parser.add_argument("--limit", type=int, help="maximum number of clips to inspect or generate")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    if args.review:
        items = json.loads(PILOT.read_text(encoding="utf-8"))["dialogues"]
        rows = [clip for item in items for clip in item_clips(item, "pilot2_")]
    else:
        module = json.loads(MODULE.read_text(encoding="utf-8"))
        words = json.loads(WORDS.read_text(encoding="utf-8"))
        rows = production_clips(module, words)
    if args.limit is not None:
        rows = rows[:args.limit]
    if len({stem for stem, _, _ in rows}) != len(rows):
        raise ValueError("duplicate audio keys")
    todo = [row for row in rows if not (OUT / (row[0] + ".mp3")).exists()]
    print(f"audio: {len(rows) - len(todo)}/{len(rows)} present; {len(todo)} missing")
    if args.dry_run or not todo:
        return
    OUT.mkdir(parents=True, exist_ok=True)
    token = access_token()
    for stem, text, voice in todo:
        audio = synthesize(text, voice, token)
        (OUT / f"{stem}.mp3").write_bytes(audio)
        print(f"{stem}.mp3 {len(audio)} bytes")


if __name__ == "__main__":
    main()
