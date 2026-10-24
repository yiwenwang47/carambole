#!/usr/bin/env python3
"""Lint the *Mots* book (carambole/Resources/Vocab/mots.json).

Errors (exit 1): duplicate id / lemma, missing gloss, noun without a
matching article, English in the French headword, part of speech outside the
allowed set, missing audio file, clip key collision (one key, two spoken
forms), contract shape (leçon size, indexes, ranks, keys).

  python3 tools/vocab/lint.py [--book PATH] [--audio-dir DIR] [--no-audio]
"""
from __future__ import annotations

import argparse
import json
import logging
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from build_lists import BAND_SIZE, LECON_EXPRESSIONS, LECON_WORDS, ROOT, fold, read_ranked, spoken_form

BOOK = ROOT / "carambole/Resources/Vocab/mots.json"
AUDIO_DIR = ROOT / "carambole/Resources/Audio"
# Spec set plus pron. and interj. (NOT in the spec, flagged to the user: qui, que, ça,
# rien, quelqu'un… and merci survive the filters and have no other home).
POS = {"n.m.", "n.f.", "v.", "adj.", "adv.", "prép.", "conj.", "loc.", "pron.", "interj."}
REGISTERS = {"fam.", "vulg."}
KEYS = {"id", "fr", "pos", "en", "rank", "audio", "fem", "register"}
ARTICLE = re.compile(r"^(le|la|les|l')\b ?", re.IGNORECASE)
# Common English words that are never French words.
ENGLISH = {"the", "of", "and", "to", "is", "it", "you", "with", "for", "that", "this", "be",
           "have", "not", "are", "was", "what", "who", "my", "your", "his", "her", "they",
           "we", "from", "by", "at", "in", "or", "but", "if", "so", "do", "make", "get"}
FRENCH_TOO = {"on", "a", "an", "as", "but", "plus", "son", "ton", "mais", "est"}

log = logging.getLogger("lint")


def lint(book: dict, audio_dir: Path | None) -> list[str]:
    errors: list[str] = []
    err = errors.append
    if book.get("book") != "book_fr_mots" or not isinstance(book.get("version"), int) \
            or not isinstance(book.get("seed"), int):
        err("top level: book/version/seed wrong")
    ids: dict[str, str] = {}
    lemmas: dict[str, str] = {}
    clips: dict[str, str] = {}
    lecon_index = 0
    entries_all: list[dict] = []
    for bi, band in enumerate(book["bands"], 1):
        if band["band"] != bi:
            err(f"band {band['band']}: expected {bi}")
        if len(band["lecons"]) != BAND_SIZE // LECON_WORDS:
            err(f"band {bi}: {len(band['lecons'])} leçons")
        for lecon in band["lecons"]:
            lecon_index += 1
            if lecon["index"] != lecon_index:
                err(f"leçon {lecon['index']}: expected index {lecon_index}")
            # Expression <=> pos loc. <=> rank null; exactly 10 words + 2 expressions.
            words = [e for e in lecon["entries"] if e.get("pos") != "loc."]
            exprs = [e for e in lecon["entries"] if e.get("pos") == "loc."]
            if len(words) != LECON_WORDS or len(exprs) != LECON_EXPRESSIONS:
                err(f"leçon {lecon_index}: {len(words)} words + {len(exprs)} expressions "
                    f"(need {LECON_WORDS} + {LECON_EXPRESSIONS})")
            for e in words:
                if e.get("rank") is None:
                    err(f"{e.get('id')}: word card without a rank")
            for e in exprs:
                if e.get("rank") is not None:
                    err(f"{e.get('id')}: expression (loc.) with a rank")
            words = [e for e in words if e.get("rank") is not None]
            lo, hi = (bi - 1) * BAND_SIZE + 1, bi * BAND_SIZE
            for e in words:
                if not lo <= e["rank"] <= hi:
                    err(f"{e['id']}: rank {e['rank']} outside band {bi}")
            entries_all.extend(lecon["entries"])
    ranked = {int(r["rank"]): r for r in read_ranked()}
    for e in entries_all:
        eid = e.get("id", "?")
        extra = set(e) - KEYS
        if extra or not {"id", "fr", "pos", "en", "rank", "audio"} <= set(e):
            err(f"{eid}: keys {sorted(set(e))}")
            continue
        fr, pos, en = e["fr"], e["pos"], e["en"].strip()
        if eid in ids:
            err(f"{eid}: duplicate id ({ids[eid]} / {fr})")
        ids[eid] = fr
        if not re.fullmatch(r"voc_[a-z0-9_]+", eid):
            err(f"{eid}: id not voc_<ascii>")
        lemma = ARTICLE.sub("", fr).lower()
        if lemma in lemmas:
            err(f"{eid}: duplicate lemma « {lemma} » (also {lemmas[lemma]})")
        lemmas[lemma] = eid
        if not en:
            err(f"{eid}: no gloss")
        elif en.endswith(".") or en != e["en"]:
            err(f"{eid}: gloss has trailing period/space")
        if pos not in POS:
            err(f"{eid}: pos {pos!r} not allowed")
        if pos in ("n.m.", "n.f."):
            m = ARTICLE.match(fr)
            art = m.group(1).lower() if m else None
            if art is None:
                err(f"{eid}: noun without article: {fr!r}")
            elif (art == "le" and pos != "n.m.") or (art == "la" and pos != "n.f."):
                err(f"{eid}: article {art} vs {pos}")
            elif art == "l'" and not re.match(r"l'[aeiouyhâàéèêëîïôœûù]", fr, re.IGNORECASE):
                err(f"{eid}: l' before a consonant")
            elif art in ("le", "la") and re.match(r"(le|la) [aeiouâàéèêëîïôœûù]", fr, re.IGNORECASE):
                err(f"{eid}: article should elide: {fr!r}")
        elif ARTICLE.match(fr) and pos != "loc.":
            err(f"{eid}: article on a {pos}: {fr!r}")
        words = re.findall(r"[^\W\d_]+", fr.lower())
        english = [w for w in words if w in ENGLISH and w not in FRENCH_TOO]
        if english or re.search(r"[;=()]", fr):
            err(f"{eid}: English or gloss text in fr: {fr!r}")
        if e.get("register") and e["register"] not in REGISTERS:
            err(f"{eid}: register {e['register']!r}")
        if e.get("fem") and pos != "adj.":
            err(f"{eid}: fem on a {pos}")
        if e["rank"] is not None:
            r = ranked.get(e["rank"])
            if r is None:
                err(f"{eid}: rank {e['rank']} not in ranked.tsv")
        spoken = spoken_form(fr, pos)
        prev = clips.setdefault(e["audio"], spoken)
        if prev != spoken:
            err(f"{eid}: clip key collision {e['audio']}: « {prev} » vs « {spoken} »")
        if e["audio"] == f"voc_{fold(spoken)}" or e["audio"] == eid:
            pass
        else:
            err(f"{eid}: audio key {e['audio']} is neither voc_<spoken> nor the id")
        if audio_dir is not None and not (audio_dir / f"{e['audio']}.mp3").is_file():
            err(f"{eid}: audio missing {e['audio']}.mp3")
    # An accent-folded key shared by two different spoken forms anywhere.
    folded: dict[str, str] = {}
    for key, spoken in clips.items():
        if key in folded and folded[key] != spoken:
            err(f"clip key collision {key}")
        folded[key] = spoken
    natural: dict[str, list[str]] = {}
    for e in entries_all:
        natural.setdefault(f"voc_{fold(spoken_form(e['fr'], e['pos']))}", []).append(e["id"])
    for key, owners in natural.items():
        spokens = {spoken_form(e["fr"], e["pos"]) for e in entries_all if e["id"] in owners}
        if len(spokens) > 1 and len({e["audio"] for e in entries_all if e["id"] in owners}) < len(spokens):
            err(f"{key}: {sorted(spokens)} fold together and share a clip")
    # An expression must not repeat a ranked word card (anywhere in ranked.tsv).
    ranked_lemmas = {r["lemma"] for r in ranked.values()}
    for e in entries_all:
        if e["rank"] is None and e["fr"] in ranked_lemmas:
            err(f"{e['id']}: expression « {e['fr']} » is also a ranked word")
    return errors


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--book", type=Path, default=BOOK)
    ap.add_argument("--audio-dir", type=Path, default=AUDIO_DIR)
    ap.add_argument("--no-audio", action="store_true")
    args = ap.parse_args()
    book = json.loads(args.book.read_text(encoding="utf-8"))
    errors = lint(book, None if args.no_audio else args.audio_dir)
    n = sum(len(lc["entries"]) for b in book["bands"] for lc in b["lecons"])
    for e in errors:
        log.error("ERROR %s", e)
    log.info("%d entries in %d bands: %d errors", n, len(book["bands"]), len(errors))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
