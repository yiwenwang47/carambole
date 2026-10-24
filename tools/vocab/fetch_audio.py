#!/usr/bin/env python3
"""Fetch one MP3 per vocab word: a Lingua Libre recording from Wikimedia
Commons when one exists, else Google TTS. Every clip is trimmed of edge
silence, made mono 24 kHz (what the release gate expects) and run through
`normalize_audio.py` (even loudness).

Lingua Libre files are named `LL-Q150 (fra)-<speaker>-<word>.wav`; we try
exact titles for the most prolific French speakers in priority order (50
titles per API call, honouring Commons rate limits). Recordings are bare
words, so the article of a noun headword is not voiced (« la confiance » →
"confiance").

Usage:
  # headword list (one per line), report keyed by headword (design/vocab/build.py)
  python3 tools/vocab/fetch_audio.py --words words.txt --out DIR [--report report.json]
  # explicit clip keys, [{"key": "voc_ou_adv", "spoken": "où"}, ...], report keyed by clip key
  python3 tools/vocab/fetch_audio.py --entries audio_entries.json --out DIR --report report.json

Resumable: an existing MP3 whose report row is present is kept as is. The
report maps each headword / key to {file, source, spoken, speaker, title,
license} (Lingua Libre) or {file, source, spoken, voice} (TTS). CC BY-SA:
keep `speaker` + `title` for credits.
"""
from __future__ import annotations

import argparse
import json
import logging
import re
import sys
import tempfile
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

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
OUT_RATE = 24000  # audio_audit.py requires mono 24 kHz (the Neural2 rate)

log = logging.getLogger("fetch_audio")


def spoken_form(headword: str) -> str:
    """What a Lingua Libre recording is filed under: the bare word."""
    return ARTICLE.sub("", headword.strip(), count=1)


def clip_key(word: str) -> str:
    """ASCII file key: œ/æ spelled out, accents folded (« réussir » → reussir), others → _."""
    word = word.lower().replace("œ", "oe").replace("æ", "ae")
    folded = unicodedata.normalize("NFKD", word).encode("ascii", "ignore").decode()
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
            wait = int(e.headers.get("retry-after", 10)) + 1
            log.warning("Commons 429, waiting %ds", wait)
            time.sleep(wait)


def variants(word: str) -> list[str]:
    """Filing variants: straight and curly apostrophe."""
    out = [word]
    if "'" in word:
        out.append(word.replace("'", "’"))
    return out


def find_recordings(words: list[str]) -> dict[str, tuple[str, str]]:
    """word -> (best existing Commons title, speaker), in speaker priority order."""
    cands = [(w, sp, f"File:LL-Q150 (fra)-{sp}-{v}.wav")
             for w in words for sp in SPEAKERS for v in variants(w)]
    hits: set[str] = set()
    for i in range(0, len(cands), 50):
        chunk = [t for _, _, t in cands[i:i + 50]]
        d = get_json({"action": "query", "format": "json", "titles": "|".join(chunk)})
        norm = {n["to"]: n["from"] for n in d["query"].get("normalized", [])}
        for p in d["query"]["pages"].values():
            if "missing" not in p and "invalid" not in p:
                hits.add(norm.get(p["title"], p["title"]))
        time.sleep(1.0)
    best: dict[str, tuple[str, str]] = {}
    for w, sp, t in cands:
        if t in hits and w not in best:
            best[w] = (t, sp)
    return best


def download(title: str, dest: Path) -> dict:
    """Save the file; return its licence metadata."""
    d = get_json({"action": "query", "format": "json", "titles": title,
                  "prop": "imageinfo", "iiprop": "url|extmetadata"})
    info = next(iter(d["query"]["pages"].values()))["imageinfo"][0]
    meta = info.get("extmetadata", {})
    url = info["url"]
    while True:
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=120) as r:
                dest.write_bytes(r.read())
            break
        except urllib.error.HTTPError as e:
            if e.code != 429:
                raise
            wait = int(e.headers.get("retry-after", 10)) + 1
            log.warning("upload.wikimedia.org 429, waiting %ds", wait)
            time.sleep(wait)
    return {"license": meta.get("LicenseShortName", {}).get("value", ""),
            "license_url": meta.get("LicenseUrl", {}).get("value", "")}


def trim_to_mp3(src: Path, dest: Path) -> None:
    """Decode any format, mono, trim quiet edges, resample to 24 kHz, encode MP3."""
    import numpy as np
    from normalize_audio import decode, encode
    from scipy.signal import resample_poly

    x, sr = decode(src)
    if x.ndim > 1:
        x = x.mean(axis=1)
    env = np.abs(x)
    loud = np.nonzero(env > env.max() * 10 ** (EDGE_DB / 20))[0]
    if len(loud):
        keep = int(EDGE_KEEP * sr)
        x = x[max(0, loud[0] - keep): min(len(x), loud[-1] + keep)]
    if sr not in (24000, 44100, 48000, 22050, 32000, 16000):
        raise ValueError(f"{src.name}: unexpected sample rate {sr}")
    if sr != OUT_RATE:
        from math import gcd
        g = gcd(sr, OUT_RATE)
        x = resample_poly(x, OUT_RATE // g, sr // g)
    dest.write_bytes(encode(np.clip(x, -1.0, 1.0), OUT_RATE, 64))


def load_jobs(args: argparse.Namespace) -> list[tuple[str, str, str]]:
    """(report key, spoken text, mp3 stem)."""
    if args.entries:
        rows = json.loads(args.entries.read_text(encoding="utf-8"))
        return [(r["key"], r["spoken"], r["key"]) for r in rows]
    heads = [line.strip() for line in args.words.read_text().splitlines() if line.strip()]
    return [(h, spoken_form(h), f"voc_{clip_key(spoken_form(h))}") for h in heads]


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    ap = argparse.ArgumentParser()
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--words", type=Path)
    src.add_argument("--entries", type=Path)
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--report", type=Path)
    args = ap.parse_args()

    from normalize_audio import process_file, require_codec
    require_codec()
    args.out.mkdir(parents=True, exist_ok=True)
    jobs = load_jobs(args)
    report: dict[str, dict] = {}
    if args.report and args.report.is_file():
        report = json.loads(args.report.read_text(encoding="utf-8"))
    todo = [j for j in jobs if not ((args.out / f"{j[2]}.mp3").exists() and j[0] in report)]
    log.info("%d clips, %d to fetch", len(jobs), len(todo))
    found = find_recordings(sorted({s for _, s, _ in todo}))

    token = None
    with tempfile.TemporaryDirectory() as tmp:
        for name, s, stem in todo:
            dest = args.out / f"{stem}.mp3"
            if s in found:
                title, speaker = found[s]
                raw = Path(tmp) / "raw.wav"
                lic = download(title, raw)
                trim_to_mp3(raw, dest)
                time.sleep(1.0)
                report[name] = {"file": dest.name, "source": "lingualibre", "spoken": s,
                                "speaker": speaker, "title": title, **lic}
            else:
                from generate_audio import access_token, synthesize
                raw = Path(tmp) / "raw.mp3"
                try:
                    token = token or access_token()
                    raw.write_bytes(synthesize(s, TTS_VOICE, token))
                except RuntimeError:   # tokens last an hour; Commons waits can outlast one
                    token = access_token()
                    raw.write_bytes(synthesize(s, TTS_VOICE, token))
                trim_to_mp3(raw, dest)
                report[name] = {"file": dest.name, "source": "tts", "spoken": s, "voice": TTS_VOICE}
            process_file(dest)
            log.info("%-12s %s", report[name]["source"], name)
            if args.report:
                args.report.write_text(json.dumps(report, ensure_ascii=False, indent=1) + "\n",
                                       encoding="utf-8")
    rows = [report[j[0]] for j in jobs if j[0] in report]
    ll = sum(1 for r in rows if r["source"] == "lingualibre")
    log.info("%d/%d from Lingua Libre, %d TTS", ll, len(rows), len(rows) - ll)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
