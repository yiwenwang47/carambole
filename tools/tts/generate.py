#!/usr/bin/env python3
"""Batch-synthesize French audio for every drill sentence via Google Cloud TTS.

Reads spoken_manifest.json (from extract.py) and writes one MP3 per unique
sentence, named <key>.mp3, into the output dir. Idempotent: existing files are
skipped unless --force, so re-running after a content edit only synthesizes the
new/changed sentences.

Auth: Application Default Credentials (gcloud auth application-default login).
No service-account key file.

Examples:
  python3 tools/tts/generate.py --spread 20 --out /tmp/tts_smoke   # smoke test
  python3 tools/tts/generate.py                                    # full batch
"""
from __future__ import annotations

import argparse
import json
import os
import sys

# Neural2 (not Chirp3-HD): its rule-based French G2P frontend handles elisions
# correctly (Chirp3-HD spelled bare "n'" as the letter N). Google's current
# female French Neural2 voice is F; the former C name maps to F.
VOICE = 'fr-FR-Neural2-F'
LANG = 'fr-FR'
RATE = 0.9


def manifest_path() -> str:
    return os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        'spoken_manifest.json')


def default_out() -> str:
    here = os.path.dirname(os.path.abspath(__file__))
    repo = os.path.dirname(os.path.dirname(here))
    return os.path.join(repo, 'carambole', 'Resources', 'Audio')


def pick(rows: list[dict], limit: int | None, spread: int | None) -> list[dict]:
    if spread:
        if spread >= len(rows):
            return rows
        step = len(rows) / spread
        return [rows[int(i * step)] for i in range(spread)]
    if limit:
        return rows[:limit]
    return rows


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=default_out())
    ap.add_argument('--limit', type=int, default=None, help='first N sentences')
    ap.add_argument('--spread', type=int, default=None,
                    help='N sentences evenly spread across the course (smoke test)')
    ap.add_argument('--rate', type=float, default=RATE)
    ap.add_argument('--force', action='store_true', help='re-synthesize existing')
    args = ap.parse_args(argv)

    if not os.path.exists(manifest_path()):
        print('spoken_manifest.json missing — run extract.py first', file=sys.stderr)
        return 1
    rows = json.load(open(manifest_path()))
    todo = pick(rows, args.limit, args.spread)
    os.makedirs(args.out, exist_ok=True)

    from google.cloud import texttospeech as tts
    client = tts.TextToSpeechClient()
    voice = tts.VoiceSelectionParams(language_code=LANG, name=VOICE)
    cfg = tts.AudioConfig(audio_encoding=tts.AudioEncoding.MP3,
                          speaking_rate=args.rate)

    made = skipped = chars = 0
    for i, r in enumerate(todo, 1):
        dest = os.path.join(args.out, r['key'] + '.mp3')
        if os.path.exists(dest) and not args.force:
            skipped += 1
            continue
        resp = client.synthesize_speech(
            input=tts.SynthesisInput(text=r['text']), voice=voice, audio_config=cfg)
        open(dest, 'wb').write(resp.audio_content)
        made += 1
        chars += len(r['text'])
        print(f'[{i}/{len(todo)}] {r["key"]}.mp3  {len(resp.audio_content):>6}B  '
              f'{r["text"]}')

    print(f'\ndone: {made} synthesized, {skipped} skipped → {args.out}')
    print(f'chars synthesized: {chars}')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
