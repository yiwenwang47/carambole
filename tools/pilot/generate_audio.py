#!/usr/bin/env python3
"""Bundle two-voice audio for the DEBUG-only Test book situation pilot.

Uses the same Google French Neural2 voice family as Book 1. Credentials stay
inside this process; no token or response body is printed. Existing files are
left in place so an interrupted run can resume.
"""

from __future__ import annotations

import argparse
import base64
import html
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


def clip_rows(item: dict) -> list[tuple[str, str, str]]:
    turns = item["turns"]
    dialogue = "<speak>" + "".join(
        f'<voice name="{FEMALE if turn["speaker"] == "customer" else MALE}">'
        f'{html.escape(turn["text"])}</voice><break time="400ms"/>'
        for turn in turns
    ) + "</speak>"
    stem = "pilot_" + item["id"]
    return [
        (stem, dialogue, FEMALE),
        (stem + "_model", item["modelReply"], FEMALE),
        (stem + "_followup", item["followUp"], MALE),
    ]


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
    items = json.loads(CONTENT.read_text(encoding="utf-8"))
    rows = [row for item in items for row in clip_rows(item)]
    if args.limit is not None:
        rows = rows[: args.limit]
    OUT.mkdir(parents=True, exist_ok=True)
    todo = [(stem, text, voice) for stem, text, voice in rows
            if not (OUT / (stem + ".mp3")).exists()]
    token = access_token() if todo else ""
    for stem, text, voice in todo:
        audio = synthesize(text, voice, token)
        (OUT / (stem + ".mp3")).write_bytes(audio)
        print(f"{stem}.mp3 {len(audio)} bytes")
    print(f"audio coverage: {len(rows) - len(todo) + len(todo)}/{len(rows)}")


if __name__ == "__main__":
    main()
