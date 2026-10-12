#!/usr/bin/env python3
"""Bundle server-voice audio for the DEBUG-only Test book dialogue pilot.

Uses the same Google French Neural2 voice family as Book 1. Credentials stay
inside this process; no token or response body is printed. Existing files are
left in place so an interrupted run can resume. Each new clip is
loudness-normalised right after it is written (tools/situations/normalize_audio.py).
"""

from __future__ import annotations

import argparse
import base64
import json
from pathlib import Path
import ssl
import subprocess
import urllib.error
import urllib.request


ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "carambole/Debug/testbook_situation.json"
OUT = ROOT / "carambole/Resources/Audio"
ENDPOINT = "https://texttospeech.googleapis.com/v1/text:synthesize"
FEMALE = "fr-FR-Neural2-F"
MALE = "fr-FR-Neural2-G"
# One stable voice per recurring character (Chirp 3 HD: more conversational).
CAST = {
    "Karim": "fr-FR-Chirp3-HD-Charon",
    "Théo": "fr-FR-Chirp3-HD-Achird",
    "Léa": "fr-FR-Chirp3-HD-Aoede",
    # Book 2 cast; canonical turn `name` strings (see tools/situations/README.md).
    "M. Ferrand": "fr-FR-Chirp3-HD-Orus",  # older neighbour, fussy (Algenib paused ~1 s between sentences)
    "Inès": "fr-FR-Chirp3-HD-Despina",  # young colleague (smooth female)
    "Mme Dumas": "fr-FR-Chirp3-HD-Gacrux",  # older landlady (mature female)
}


def voice_for(name: str | None) -> str:
    return CAST.get(name or "", MALE)


def clip_rows(item: dict) -> list[tuple[str, str, str]]:
    """Server lines and the follow-up, one clip each, in the speaker's voice."""
    stem = "pilot2_" + item["id"]
    rows = [
        (f"{stem}_t{i}", turn["text"].replace("___", "…"), voice_for(turn.get("name")))
        for i, turn in enumerate(item["turns"])
        if turn["speaker"] == "server"
    ]
    if "followUp" in item:
        by = item.get("followUpBy") or next(
            (t.get("name") for t in item["turns"] if t["speaker"] == "server" and t.get("name")), None)
        rows.append((f"{stem}_f", item["followUp"], voice_for(by)))
    return rows


def access_token() -> str:
    return subprocess.check_output(
        ["gcloud", "auth", "application-default", "print-access-token"],
        text=True,
        stderr=subprocess.PIPE,
    ).strip()


def synthesize(text: str, voice: str, token: str) -> bytes:
    body = {
        "input": {"ssml": text} if text.startswith("<speak>") else {"text": text},
        "voice": {"languageCode": "fr-FR", "name": voice},
        "audioConfig": {"audioEncoding": "MP3", "speakingRate": 0.9},
    }
    adc_path = Path.home() / ".config/gcloud/application_default_credentials.json"
    quota_project = json.loads(adc_path.read_text()).get("quota_project_id", "")
    request = urllib.request.Request(
        ENDPOINT,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": "Bearer " + token,
            "Content-Type": "application/json; charset=utf-8",
            "x-goog-user-project": quota_project,
        },
        method="POST",
    )
    try:
        mac_ca = Path("/etc/ssl/cert.pem")
        context = ssl.create_default_context(cafile=str(mac_ca) if mac_ca.exists() else None)
        with urllib.request.urlopen(request, timeout=45, context=context) as response:
            result = json.load(response)
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"TTS HTTP {error.code}: {detail[:500]}") from error
    return base64.b64decode(result["audioContent"])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=None, help="Maximum number of clips")
    args = parser.parse_args()
    items = json.loads(CONTENT.read_text(encoding="utf-8"))["dialogues"]
    rows = [row for item in items for row in clip_rows(item)]
    if args.limit is not None:
        rows = rows[: args.limit]
    OUT.mkdir(parents=True, exist_ok=True)
    todo = [(stem, text, voice) for stem, text, voice in rows
            if not (OUT / (stem + ".mp3")).exists()]
    if todo:
        import sys
        sys.path.append(str(ROOT / "tools/situations"))
        from normalize_audio import process_file, require_codec
        require_codec()
    token = access_token() if todo else ""
    for stem, text, voice in todo:
        audio = synthesize(text, voice, token)
        (OUT / (stem + ".mp3")).write_bytes(audio)
        process_file(OUT / (stem + ".mp3"))
        print(f"{stem}.mp3 {len(audio)} bytes")
    print(f"audio coverage: {len(rows) - len(todo) + len(todo)}/{len(rows)}")


if __name__ == "__main__":
    main()
