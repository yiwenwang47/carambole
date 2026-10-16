#!/usr/bin/env python3
"""Regenerate review-only alternatives for the first Book 2 audio example."""

from __future__ import annotations

import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools/pilot"))
from generate_audio import access_token, synthesize  # noqa: E402

sys.path.insert(0, str(ROOT / "tools/situations"))
from normalize_audio import process_file, require_codec  # noqa: E402


OUT = Path(__file__).resolve().parent
TEXT = "C'était top, hier ! À refaire !"
VOICES = {
    "studio_a": "fr-FR-Studio-A",
    "neural2_f": "fr-FR-Neural2-F",
    "wavenet_f": "fr-FR-Wavenet-F",
}


def main() -> None:
    overrides = json.loads((ROOT / "tools/situations/tts_overrides.json").read_text())
    ssml = overrides[TEXT]
    require_codec()
    token = access_token()
    for label, voice in VOICES.items():
        target = OUT / f"sit_04_thank_d03_t0_{label}.mp3"
        if target.exists():
            print(f"existing: {target.name}")
            continue
        target.write_bytes(synthesize(ssml, voice, token))
        process_file(target)
        print(f"generated: {voice} → {target.name}")


if __name__ == "__main__":
    main()
