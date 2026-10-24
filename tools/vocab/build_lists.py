#!/usr/bin/env python3
"""Build the word lists of « Monnaie courante » (book_fr_mots, formerly *Mots*) from Lexique 3 and the authored glosses.

Two steps:

  python3 tools/vocab/build_lists.py rank
      Download (once, cached) Lexique 3.83, rank lemmas by
      freqlemfilms2 + freqlemlivres (islem == 1), apply
      tools/vocab/data/lexique_rules.json (merges, splits, drops) and write
      tools/vocab/data/ranked.tsv: one row per card, rank 1..N.

  python3 tools/vocab/build_lists.py assemble [--bands 10]
      Join ranked.tsv with tools/vocab/data/glosses.json and
      expressions.json, cut bands of 100, shuffle each band with SEED, split
      into leçons of 10 words + 2 expressions and write
      carambole/Resources/Vocab/mots.json, tools/vocab/data/audio_entries.json
      (clip key + spoken text, input for fetch_audio.py --entries) and, when
      tools/vocab/data/audio_report.json exists, the release-gate clip index
      tools/vocab/audio_index.json and carambole/Resources/Vocab/mots_credits.json
      (read by the app's Credits screen, `Models/Credits.swift`; book-specific
      name because Xcode flattens bundle resources).

Rank of a card = its position in the filtered list (so band b is exactly
ranks 100(b-1)+1 .. 100b). A card's frequency is the highest of its merged
Lexique rows (Lexique repeats one count across sub-tags, e.g. qui PRO:int and
PRO:rel, so summing would double count).

Lexique 3 (New & Pallier, www.lexique.org) is CC BY-SA 4.0.
"""
from __future__ import annotations

import argparse
import csv
import json
import logging
import os
import random
import re
import sys
import unicodedata
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
DATA = HERE / "data"
LEXIQUE_URL = "https://www.lexique.org/databases/Lexique383/Lexique383.tsv"
CACHE = Path(os.environ.get("CARAMBOLE_LEXIQUE", HERE / ".cache/Lexique383.tsv"))
RULES = DATA / "lexique_rules.json"
RANKED = DATA / "ranked.tsv"
GLOSSES = DATA / "glosses.json"
EXPRESSIONS = DATA / "expressions.json"
AUDIO_ENTRIES = DATA / "audio_entries.json"
AUDIO_REPORT = DATA / "audio_report.json"
AUDIO_INDEX = HERE / "audio_index.json"
OUT_DIR = ROOT / "carambole/Resources/Vocab"
CREDITS = OUT_DIR / "mots_credits.json"
TTS_SERVICE = "Google Cloud Text-to-Speech"
BOOK = "book_fr_mots"
VERSION = 1
SEED = 20261023
BAND_SIZE = 100
LECON_WORDS = 10
LECON_EXPRESSIONS = 2
RANKED_KEEP = 5000  # cards written to ranked.tsv (enough for 50 bands)

ARTICLE = re.compile(r"^(le |la |les |l'|l’)", re.IGNORECASE)
REFLEXIVE = re.compile(r"^(se |s'|s’)", re.IGNORECASE)

log = logging.getLogger("build_lists")


def fold(text: str) -> str:
    """ASCII key: œ/æ spelled out, accents folded, everything else → _."""
    text = text.lower().replace("œ", "oe").replace("æ", "ae")
    folded = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "_", folded).strip("_") or "w"


def spoken_form(fr: str, pos: str) -> str:
    """What the clip says: no article; a reflexive verb without « se »; an expression in full."""
    if pos == "loc.":
        return fr.strip()  # « le long de » keeps its article
    s = ARTICLE.sub("", fr.strip(), count=1)
    if pos == "v.":
        s = REFLEXIVE.sub("", s, count=1)
    return s


# ---------------------------------------------------------------- rank


@dataclass
class Card:
    key: str  # "lemma" or "lemma#CGRAM" for a split card
    lemma: str
    freq: float = 0.0
    cgram: str = ""
    rows: dict[str, float] = field(default_factory=dict)

    def add(self, cgram: str, freq: float) -> None:
        self.rows[cgram] = max(self.rows.get(cgram, 0.0), freq)
        if freq > self.freq:
            self.freq, self.cgram = freq, cgram


def download_lexique(path: Path = CACHE) -> Path:
    if path.is_file() and path.stat().st_size > 10_000_000:
        return path
    path.parent.mkdir(parents=True, exist_ok=True)
    log.info("downloading %s", LEXIQUE_URL)
    tmp = path.with_suffix(".part")
    req = urllib.request.Request(LEXIQUE_URL, headers={"User-Agent": "carambole-vocab/0.1"})
    with urllib.request.urlopen(req, timeout=300) as r, tmp.open("wb") as f:
        while chunk := r.read(1 << 20):
            f.write(chunk)
    tmp.replace(path)
    return path


def rank_cards(lexique: Path, rules: dict) -> tuple[list[Card], dict[str, str]]:
    """Ranked cards plus {lemma: reason} for everything dropped."""
    merge: dict[str, str] = rules["merge"]
    splits = {(s["lemma"], s["cgram"]) for s in rules["split"]}
    drop_cgram = set(rules["drop_cgram"])
    cards: dict[str, Card] = {}
    with lexique.open(encoding="utf-8") as f:
        for row in csv.DictReader(f, delimiter="\t"):
            if row["islem"] != "1":
                continue
            lemma = merge.get(row["lemme"], row["lemme"])
            cgram = row["cgram"]
            freq = float(row["freqlemfilms2"] or 0) + float(row["freqlemlivres"] or 0)
            key = f"{lemma}#{cgram}" if (lemma, cgram) in splits else lemma
            cards.setdefault(key, Card(key, lemma)).add(cgram, freq)
    dropped: dict[str, str] = {}
    kept: list[Card] = []
    for card in cards.values():
        if card.lemma in rules["drop"] and "#" not in card.key:
            dropped[card.key] = rules["drop"][card.lemma]
        elif card.cgram in drop_cgram:
            dropped[card.key] = f"led by {card.cgram}"
        elif card.freq > 0:
            kept.append(card)
    kept.sort(key=lambda c: (-c.freq, c.key))
    return kept, dropped


def cmd_rank(_: argparse.Namespace) -> int:
    rules = json.loads(RULES.read_text(encoding="utf-8"))
    cards, dropped = rank_cards(download_lexique(), rules)
    with RANKED.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(["rank", "key", "lemma", "cgram", "freq", "rows"])
        for i, c in enumerate(cards[:RANKED_KEEP], 1):
            rows = " ".join(f"{k}:{v:.1f}" for k, v in sorted(c.rows.items(), key=lambda kv: -kv[1]))
            w.writerow([i, c.key, c.lemma, c.cgram, f"{c.freq:.2f}", rows])
    top = {c.key for c in cards[:BAND_SIZE * 2]}
    cutoff = cards[BAND_SIZE * 2 - 1].freq
    big = sorted((k for k in dropped), key=lambda k: k)
    log.info("%d cards ranked (%d written to %s); %d dropped", len(cards),
             min(len(cards), RANKED_KEEP), RANKED.relative_to(ROOT), len(dropped))
    log.info("band 2 ends at freq %.1f; %d of top 200 are split cards", cutoff,
             sum("#" in k for k in top))
    log.debug("dropped: %s", big)
    return 0


# ------------------------------------------------------------ assemble


def read_ranked() -> list[dict[str, str]]:
    with RANKED.open(encoding="utf-8") as f:
        return list(csv.DictReader(f, delimiter="\t"))


def entry_for(g: dict, rank: int | None) -> dict:
    """Contract entry (key order matters only for readability)."""
    e: dict = {"id": g.get("id") or f"voc_{fold(g.get('lemma') or g['fr'])}",
               "fr": g["fr"], "pos": g["pos"], "en": g["en"], "rank": rank}
    for k in ("fem", "register"):
        if g.get(k):
            e[k] = g[k]
    spoken = g.get("spoken") or spoken_form(g["fr"], g["pos"])
    e["audio"] = g.get("audio") or f"voc_{fold(spoken)}"
    e["_spoken"] = spoken
    return e


def build_book(bands: int) -> tuple[dict, list[dict]]:
    ranked = read_ranked()
    glosses = json.loads(GLOSSES.read_text(encoding="utf-8"))["entries"]
    by_key = {g["key"]: g for g in glosses}
    expressions = json.loads(EXPRESSIONS.read_text(encoding="utf-8"))["entries"]
    per_band = BAND_SIZE // LECON_WORDS * LECON_EXPRESSIONS
    if len(expressions) < bands * per_band:
        raise SystemExit(f"need {bands * per_band} expressions, have {len(expressions)}")
    book: dict = {"book": BOOK, "version": VERSION, "seed": SEED, "bands": []}
    flat: list[dict] = []
    for b in range(1, bands + 1):
        rows = ranked[(b - 1) * BAND_SIZE: b * BAND_SIZE]
        missing = [r["key"] for r in rows if r["key"] not in by_key]
        if missing:
            raise SystemExit(f"band {b}: no gloss for {', '.join(missing)}")
        words = [entry_for({**by_key[r["key"]], "lemma": by_key[r["key"]].get("lemma", r["lemma"])},
                           int(r["rank"])) for r in rows]
        random.Random(SEED * 1000 + b).shuffle(words)
        exprs = [entry_for(x, None) for x in expressions[(b - 1) * per_band: b * per_band]]
        lecons = []
        for i in range(BAND_SIZE // LECON_WORDS):
            entries = (words[i * LECON_WORDS:(i + 1) * LECON_WORDS]
                       + exprs[i * LECON_EXPRESSIONS:(i + 1) * LECON_EXPRESSIONS])
            flat.extend(entries)
            lecons.append({"index": (b - 1) * (BAND_SIZE // LECON_WORDS) + i + 1,
                           "entries": [{k: v for k, v in e.items() if not k.startswith("_")}
                                       for e in entries]})
        book["bands"].append({"band": b, "lecons": lecons})
    return book, flat


def write_json(path: Path, data: object, compact: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, ensure_ascii=False, separators=(",", ":") if compact else None,
                      indent=None if compact else 1)
    path.write_text(text + "\n", encoding="utf-8")


def credits(flat: list[dict], report: dict) -> dict:
    """Credits for the app's Credits screen: sources, Lingua Libre clips, TTS count."""
    clips = []
    tts = []
    for key in sorted({e["audio"] for e in flat}):
        r = report[key]
        if r["source"] != "lingualibre":
            tts.append(key)
        else:
            clips.append({"audio": key, "word": r["spoken"], "source": "Lingua Libre",
                          "speaker": r["speaker"], "title": r["title"],
                          "license": r.get("license", "CC BY-SA 4.0"),
                          "url": "https://commons.wikimedia.org/wiki/"
                                 + r["title"].replace(" ", "_")})
    return {
        "book": BOOK,
        "sources": [
            {"name": "Lexique 3.83", "authors": "Boris New, Christophe Pallier et al.",
             "use": "word frequency ranks", "license": "CC BY-SA 4.0",
             "url": "http://www.lexique.org"},
            {"name": "Lingua Libre", "authors": "Wikimedia France and its speakers",
             "use": "word recordings (Wikimedia Commons)", "license": "see each clip",
             "url": "https://lingualibre.org"},
        ],
        "speakers": sorted({c["speaker"] for c in clips}),
        "clips": clips,
        "tts": {"count": len(tts), "service": TTS_SERVICE,
                "voices": sorted({report[k]["voice"] for k in tts})},
    }


def cmd_assemble(args: argparse.Namespace) -> int:
    book, flat = build_book(args.bands)
    write_json(OUT_DIR / "mots.json", book, compact=False)
    # One clip per audio key; several entries may share one (same spoken form).
    seen: dict[str, str] = {}
    for e in flat:
        if seen.setdefault(e["audio"], e["_spoken"]) != e["_spoken"]:
            raise SystemExit(f"clip key {e['audio']}: {seen[e['audio']]!r} vs {e['_spoken']!r}")
    write_json(AUDIO_ENTRIES, [{"key": k, "spoken": s} for k, s in seen.items()])
    log.info("mots.json: %d bands, %d entries, %d clips", args.bands, len(flat), len(seen))
    if AUDIO_REPORT.is_file():
        report = json.loads(AUDIO_REPORT.read_text(encoding="utf-8"))
        absent = [k for k in seen if k not in report]
        if absent:
            log.warning("%d clips not fetched yet (e.g. %s); index/mots_credits not written",
                        len(absent), absent[:5])
            return 1
        index = [{"key": k, "text": s,
                  "voice": (f"lingualibre:{report[k]['speaker']}"
                            if report[k]["source"] == "lingualibre" else report[k]["voice"])}
                 for k, s in sorted(seen.items())]
        write_json(AUDIO_INDEX, index)
        write_json(CREDITS, credits(flat, report))
        ll = sum(1 for i in index if i["voice"].startswith("lingualibre"))
        log.info("audio_index.json + mots_credits.json: %d clips, %d Lingua Libre, %d TTS",
                 len(index), ll, len(index) - ll)
    return 0


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("rank").set_defaults(func=cmd_rank)
    a = sub.add_parser("assemble")
    a.add_argument("--bands", type=int, default=10, help="bands to emit (all must be glossed)")
    a.set_defaults(func=cmd_assemble)
    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
