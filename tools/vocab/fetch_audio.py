#!/usr/bin/env python3
"""Fetch one MP3 per vocab word: a Lingua Libre recording from Wikimedia
Commons when one exists, else Google TTS. Every clip is trimmed of edge
silence, made mono and run through `normalize_audio.py` (even loudness).

Lingua Libre files are named `LL-Q150 (fra)-<speaker>-<word>.wav`; we try
exact titles for the most prolific French speakers in priority order (50
titles per API call, honouring Commons rate limits). Recordings are bare
words, so the article of a noun headword is not voiced (« la confiance » →
"confiance").

Usage:
  python3 tools/vocab/fetch_audio.py --words words.txt --out DIR [--report report.json]

`words.txt` has one headword per line. The report maps each headword to
{file, source, speaker, title}. CC BY-SA: keep `speaker` + `title` for credits.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
import tempfile
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
sys.path.append(str(ROOT / "tools/situations"))
sys.path.insert(0, str(ROOT / "tools/pilot"))

UA = "carambole-vocab/0.1 (personal language-learning app; non-commercial; mangopango047@gmail.com)"
API = "https://commons.wikimedia.org/w/api.php"
# Most prolific French Lingua Libre speakers first.
SPEAKERS = ["Lepticed7", "Poslovitch", "WikiLucas00", "LoquaxFR", "Fabricio Cardenas (Culex)",
            "Jérémy", "Mathieu Kappler", "Mecanautes", "Yug", "Guilhelma", "Lyokoï", "Bananax47",
            "Pamputt", "DenisdeShawi", "XANA000", "Michael Barbereau WMFr"]
TTS_VOICE = "fr-FR-Neural2-F"
ARTICLE = re.compile(r"^(le |la |les |l'|l’|un |une |se |s')", re.IGNORECASE)
EDGE_DB = -40.0   # trim leading/trailing audio quieter than this (re. clip peak)
EDGE_KEEP = 0.06  # seconds of quiet kept at each end


def spoken_form(headword: str) -> str:
    """What a Lingua Libre recording is filed under: the bare word."""
    return ARTICLE.sub("", headword.strip(), count=1)


def clip_key(word: str) -> str:
    """ASCII file key: accents folded (« réussir » → reussir), others → _."""
    folded = unicodedata.normalize("NFKD", word.lower()).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "_", folded).strip("_") or "w"


def get_json(params: dict) -> dict:
    url = API + "?" + urllib.parse.urlencode(params)
    while True:
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code != 429:
                raise
            time.sleep(int(e.headers.get("retry-after", 10)) + 1)


def find_recordings(words: list[str]) -> dict[str, tuple[str, str]]:
    """word -> (best existing Commons title, speaker), in speaker priority order."""
    cands = [(w, sp, f"File:LL-Q150 (fra)-{sp}-{w}.wav") for w in words for sp in SPEAKERS]
    hits: set[str] = set()
    for i in range(0, len(cands), 50):
        chunk = [t for _, _, t in cands[i:i + 50]]
        d = get_json({"action": "query", "format": "json", "titles": "|".join(chunk)})
        norm = {n["to"]: n["from"] for n in d["query"].get("normalized", [])}
        for p in d["query"]["pages"].values():
            if "missing" not in p:
                hits.add(norm.get(p["title"], p["title"]))
        time.sleep(1.0)
    best: dict[str, tuple[str, str]] = {}
    for w, sp, t in cands:
        if t in hits and w not in best:
            best[w] = (t, sp)
    return best


def download(title: str, dest: Path) -> None:
    d = get_json({"action": "query", "format": "json", "titles": title,
                  "prop": "imageinfo", "iiprop": "url"})
    url = next(iter(d["query"]["pages"].values()))["imageinfo"][0]["url"]
    while True:
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=120) as r:
                dest.write_bytes(r.read())
            return
        except urllib.error.HTTPError as e:
            if e.code != 429:
                raise
            time.sleep(int(e.headers.get("retry-after", 10)) + 1)


def trim_to_mp3(src: Path, dest: Path) -> None:
    """Decode any format, mono, trim quiet edges, encode MP3 (then normalised)."""
    import numpy as np
    from normalize_audio import decode, encode

    x, sr = decode(src)
    env = np.abs(x)
    loud = np.nonzero(env > env.max() * 10 ** (EDGE_DB / 20))[0]
    if len(loud):
        keep = int(EDGE_KEEP * sr)
        x = x[max(0, loud[0] - keep): min(len(x), loud[-1] + keep)]
    if sr not in (24000, 44100, 48000, 22050, 32000, 16000):
        raise ValueError(f"{src.name}: unexpected sample rate {sr}")
    dest.write_bytes(encode(x, sr, 64))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--words", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--report", type=Path)
    args = ap.parse_args()

    from normalize_audio import process_file, require_codec
    require_codec()
    args.out.mkdir(parents=True, exist_ok=True)
    heads = [l.strip() for l in args.words.read_text().splitlines() if l.strip()]
    spoken = {h: spoken_form(h) for h in heads}
    found = find_recordings(sorted(set(spoken.values())))  # Lingua Libre has some multi-word entries too

    report: dict[str, dict] = {}
    token = None
    with tempfile.TemporaryDirectory() as tmp:
        for h in heads:
            s = spoken[h]
            dest = args.out / f"voc_{clip_key(s)}.mp3"
            have = dest.exists()   # resumable: an existing clip is kept as is
            if s in found:
                title, speaker = found[s]
                if not have:
                    raw = Path(tmp) / "raw.wav"
                    download(title, raw)
                    trim_to_mp3(raw, dest)
                    time.sleep(1.0)
                report[h] = {"file": dest.name, "source": "lingualibre", "speaker": speaker,
                             "title": title}
            else:
                if not have:
                    from generate_audio import access_token, synthesize
                    raw = Path(tmp) / "raw.mp3"
                    try:
                        token = token or access_token()
                        raw.write_bytes(synthesize(s, TTS_VOICE, token))
                    except RuntimeError:   # tokens last an hour; Commons waits can outlast one
                        token = access_token()
                        raw.write_bytes(synthesize(s, TTS_VOICE, token))
                    trim_to_mp3(raw, dest)
                report[h] = {"file": dest.name, "source": "tts", "voice": TTS_VOICE}
            if not have:
                process_file(dest)
            print(f"{report[h]['source']:12s} {h}")
            if args.report:
                args.report.write_text(json.dumps(report, ensure_ascii=False, indent=1))
    ll = sum(1 for r in report.values() if r["source"] == "lingualibre")
    print(f"{ll}/{len(report)} from Lingua Libre, {len(report) - ll} TTS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
