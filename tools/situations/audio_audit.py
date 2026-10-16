#!/usr/bin/env python3
"""Audit bundled situation audio against its source text.

Run after generating audio. The command writes a JSON review queue and exits
nonzero when a clip is missing, invalid, silent, or has an unusual pause.
Signal checks cannot prove that a word is pronounced correctly; flagged clips
must be heard before they are accepted or regenerated.

The manifest, words file and audio directory are arguments so future books
using the situation audio schema can use the same audit.
"""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict, dataclass
import hashlib
import html
import json
import os
from pathlib import Path
import re
import sys
from urllib.parse import quote

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools/situations"))
from normalize_audio import decode, mp3_format  # noqa: E402

DEFAULT_SITUATIONS = ROOT / "carambole/Resources/Situations"
DEFAULT_AUDIO = ROOT / "carambole/Resources/Audio"
DEFAULT_REPORT = ROOT / "docs/reports/book2_audio_audit.json"
DEFAULT_REVIEWS = ROOT / "tools/situations/audio_audit_reviews.json"
FRAME_SECONDS = 0.02
MIN_GAP_SECONDS = 0.55
VERY_LONG_GAP_SECONDS = 1.20
MAX_EDGE_SECONDS = 1.0
WORD = re.compile(r"[^\W_]+(?:['’][^\W_]+)*", re.UNICODE)


@dataclass(frozen=True)
class Finding:
    code: str
    detail: str


def _runs(mask: np.ndarray) -> list[tuple[int, int]]:
    changes = np.diff(np.r_[False, mask, False].astype(np.int8))
    return list(zip(np.flatnonzero(changes == 1), np.flatnonzero(changes == -1)))


def _punctuation_fractions(text: str) -> list[float]:
    total = sum(char.isalnum() for char in text)
    if not total:
        return []
    seen = 0
    fractions = []
    for char in text:
        if char.isalnum():
            seen += 1
        elif char in ",.!?;:" and 0 < seen < total:
            fractions.append(seen / total)
    return fractions


def active_spans(samples: np.ndarray, sample_rate: int) -> list[tuple[int, int]]:
    """Speech-like spans as sample offsets, including quiet consonant gaps."""
    if sample_rate <= 0:
        return []
    frame = max(1, round(sample_rate * FRAME_SECONDS))
    usable = len(samples) // frame * frame
    if not usable:
        return []
    rms = np.sqrt(np.mean(samples[:usable].reshape(-1, frame) ** 2, axis=1))
    peak = float(np.max(rms))
    if peak < 10 ** (-50 / 20):
        return []
    active = rms >= max(peak * 0.02, 10 ** (-55 / 20))
    spans = _runs(active)
    for left, right in zip(spans, spans[1:]):
        if (right[0] - left[1]) * frame / sample_rate < 0.10:
            active[left[1]:right[0]] = True
    return [(start * frame, end * frame) for start, end in _runs(active)]


def signal_findings(samples: np.ndarray, sample_rate: int, text: str) -> list[Finding]:
    """Find broad acoustic defects without pretending to check pronunciation."""
    if sample_rate <= 0 or len(samples) == 0:
        return [Finding("silent", "no decoded samples")]
    spans = active_spans(samples, sample_rate)
    if not spans:
        return [Finding("silent", "no audible speech above -50 dBFS")]
    first, last = spans[0][0] / sample_rate, spans[-1][1] / sample_rate
    duration = len(samples) / sample_rate
    findings: list[Finding] = []
    if first > MAX_EDGE_SECONDS or duration - last > MAX_EDGE_SECONDS:
        findings.append(Finding("edge_silence", f"leading {first:.2f}s; trailing {duration - last:.2f}s"))
    if len(WORD.findall(text)) > 1:
        punctuation = _punctuation_fractions(text)
        total_speech = sum(end - start for start, end in spans)
        speech_before = 0
        suspect_gaps = []
        for left, right in zip(spans, spans[1:]):
            speech_before += left[1] - left[0]
            gap = (right[0] - left[1]) / sample_rate
            fraction = speech_before / total_speech
            explained = any(abs(fraction - mark) <= 0.16 for mark in punctuation)
            if gap >= VERY_LONG_GAP_SECONDS or (gap >= MIN_GAP_SECONDS and not explained):
                suspect_gaps.append((gap, fraction))
        if suspect_gaps:
            gap, fraction = max(suspect_gaps)
            findings.append(Finding("internal_pause", f"{gap:.2f}s silence at about {fraction:.0%} of speech"))
    return findings


def audit_clip(row: tuple[str, str, str], audio_dir: Path) -> dict:
    key, text, voice = row
    path = audio_dir / f"{key}.mp3"
    record = {"key": key, "text": text, "voice": voice, "path": str(path), "findings": []}
    if not path.is_file():
        record["findings"] = [asdict(Finding("missing", "MP3 does not exist"))]
        return record
    try:
        raw = path.read_bytes()
        record["sha256"] = hashlib.sha256(raw).hexdigest()
        rate, channels, _ = mp3_format(raw)
        samples, decoded_rate = decode(path)
        if channels != 1 or rate != 24000 or decoded_rate != rate:
            raise ValueError(f"expected mono 24 kHz; header {rate} Hz/{channels} ch, decoded {decoded_rate} Hz")
        record["duration_seconds"] = round(len(samples) / rate, 3)
        record["findings"] = [asdict(f) for f in signal_findings(samples, rate, text)]
    except Exception as error:
        record["findings"] = [asdict(Finding("invalid", f"{type(error).__name__}: {error}"))]
    return record


def load_reviews(path: Path = DEFAULT_REVIEWS) -> dict:
    return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else {}


def is_reviewed(record: dict, reviews: dict) -> bool:
    entry = reviews.get(record["key"], {})
    codes = {finding["code"] for finding in record["findings"]}
    reason = entry.get("reason")
    return bool(codes and codes <= {"internal_pause", "edge_silence"}
                and record.get("sha256") == entry.get("sha256")
                and isinstance(reason, str) and reason.strip()
                and codes <= set(entry.get("codes", [])))


def require_clean_clip(row: tuple[str, str, str], audio_dir: Path,
                       reviews_path: Path = DEFAULT_REVIEWS) -> None:
    """Generation gate: a suspect clip needs a hash-bound listening review."""
    record = audit_clip(row, audio_dir)
    if record["findings"] and not is_reviewed(record, load_reviews(reviews_path)):
        codes = ", ".join(f["code"] for f in record["findings"])
        raise RuntimeError(f"{row[0]}: audio audit failed ({codes}); listen, fix, or record a hash-bound review")


def expected_clips(situations: Path) -> list[tuple[str, str, str]]:
    """Use the same text and audio keys as production generation."""
    from tools.situations.generate_audio import production_clips  # Same builder as TTS.
    from sitbook import load_manifest_modules

    modules = load_manifest_modules(situations)
    words = json.loads((situations / "words.json").read_text(encoding="utf-8"))
    rows = production_clips(modules, words)
    if len({key for key, _, _ in rows}) != len(rows):
        raise ValueError("duplicate audio keys in manifest")
    return rows


def audit(rows: list[tuple[str, str, str]], audio_dir: Path, jobs: int = 8,
          reviews: dict | None = None) -> dict:
    reviews = reviews or {}
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        records = list(pool.map(lambda row: audit_clip(row, audio_dir), rows))
    issues = [record for record in records if record["findings"]]
    for record in issues:
        record["reviewed"] = is_reviewed(record, reviews)
    unresolved = [record for record in issues if not record["reviewed"]]
    counts: dict[str, int] = {}
    for record in unresolved:
        for finding in record["findings"]:
            code = finding["code"]
            counts[code] = counts.get(code, 0) + 1
    return {"total_clips": len(records), "flagged_clips": len(unresolved),
            "reviewed_clips": len(issues) - len(unresolved), "counts": counts,
            "issues": issues}


def render_html(result: dict, report_path: Path) -> str:
    cards = []
    for record in result["issues"]:
        source = quote(Path(os.path.relpath(record["path"], report_path.parent)).as_posix(), safe="/.")
        findings = "; ".join(f"{f['code']}: {f['detail']}" for f in record["findings"])
        state = "Reviewed" if record["reviewed"] else "Needs review"
        cards.append(f"<article><h2>{html.escape(record['key'])}</h2>"
                     f"<p class='line'>{html.escape(record['text'])}</p>"
                     f"<p>{html.escape(state)} · {html.escape(findings)} · {html.escape(record['voice'])}</p>"
                     f"<audio controls preload='none' src='{html.escape(source, quote=True)}'></audio>"
                     f"<code>SHA-256: {html.escape(record.get('sha256', 'missing'))}</code></article>")
    return ("<!doctype html><html lang='en'><meta charset='utf-8'><title>Book audio audit</title>"
            "<style>body{font:16px system-ui;max-width:900px;margin:40px auto;padding:0 20px;color:#222}"
            "article{border-top:1px solid #ccc;padding:18px 0}h2{font-size:16px;margin:0}"
            ".line{font-size:22px}audio{display:block;width:100%;margin:12px 0}"
            "code{font-size:11px;color:#666;overflow-wrap:anywhere}</style>"
            f"<h1>Audio review</h1><p>{result['total_clips']} clips audited; "
            f"{result['flagged_clips']} need review; {result['reviewed_clips']} reviewed.</p>"
            "<p>Listen to each flagged clip. Fix the source audio or add a reason and its exact "
            "SHA-256 to audio_audit_reviews.json.</p>" + "".join(cards) + "</html>\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--situations", type=Path, default=DEFAULT_SITUATIONS,
                        help="directory containing situations_manifest.json, modules, and words.json")
    parser.add_argument("--index", type=Path,
                        help="future books: JSON list of {key, text, voice} clips instead of a situation manifest")
    parser.add_argument("--audio-dir", type=Path, default=DEFAULT_AUDIO)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--reviews", type=Path, default=DEFAULT_REVIEWS)
    parser.add_argument("--jobs", type=int, default=8)
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    if args.index:
        data = json.loads(args.index.read_text(encoding="utf-8"))
        rows = [(entry["key"], entry["text"], entry.get("voice", "")) for entry in data]
        if len({key for key, _, _ in rows}) != len(rows):
            raise ValueError("duplicate audio keys in index")
    else:
        rows = expected_clips(args.situations)
    result = audit(rows, args.audio_dir, args.jobs, load_reviews(args.reviews))
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    args.report.with_suffix(".html").write_text(render_html(result, args.report), encoding="utf-8")
    print(f"Audited {result['total_clips']} clips; {result['flagged_clips']} need review: {result['counts']}")
    print(f"Reports: {args.report}, {args.report.with_suffix('.html')}")
    raise SystemExit(1 if result["flagged_clips"] else 0)


if __name__ == "__main__":
    main()
