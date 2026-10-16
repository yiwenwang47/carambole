#!/usr/bin/env python3
"""Shorten audit-flagged quiet gaps without changing the spoken samples.

Writes candidates to a separate directory. Candidates pass the audio audit
before they can replace bundled clips; this cannot verify pronunciation.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import sys
import tempfile

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.situations.audio_audit import (  # noqa: E402
    DEFAULT_AUDIO, DEFAULT_REPORT, MAX_EDGE_SECONDS, MIN_GAP_SECONDS,
    VERY_LONG_GAP_SECONDS, _punctuation_fractions, active_spans,
    audit_clip, signal_findings,
    require_clean_clip,
)
from tools.situations.normalize_audio import (  # noqa: E402
    apply, decode, encode_checked, measure, mp3_format, plan, require_codec, tagged,
)

EDGE_KEEP_SECONDS = 0.25
UNEXPLAINED_KEEP_SECONDS = 0.20
PUNCTUATION_KEEP_SECONDS = 0.40


def shorten_pauses(samples: np.ndarray, sample_rate: int, text: str) -> np.ndarray:
    """Remove only the middles of excessive quiet regions; retain all speech."""
    spans = active_spans(samples, sample_rate)
    if not spans:
        return samples
    cuts: list[tuple[int, int]] = []
    first, last = spans[0][0], spans[-1][1]
    if first / sample_rate > MAX_EDGE_SECONDS:
        cuts.append((0, first - round(EDGE_KEEP_SECONDS * sample_rate)))
    if (len(samples) - last) / sample_rate > MAX_EDGE_SECONDS:
        cuts.append((last + round(EDGE_KEEP_SECONDS * sample_rate), len(samples)))
    if len(text.split()) > 1:
        punctuation = _punctuation_fractions(text)
        total_speech = sum(end - start for start, end in spans)
        speech_before = 0
        for left, right in zip(spans, spans[1:]):
            speech_before += left[1] - left[0]
            gap = (right[0] - left[1]) / sample_rate
            fraction = speech_before / total_speech
            explained = any(abs(fraction - mark) <= 0.16 for mark in punctuation)
            if gap >= VERY_LONG_GAP_SECONDS or (gap >= MIN_GAP_SECONDS and not explained):
                keep = PUNCTUATION_KEEP_SECONDS if explained else UNEXPLAINED_KEEP_SECONDS
                half = round(keep * sample_rate / 2)
                cuts.append((left[1] + half, right[0] - half))
    cuts = sorted((start, end) for start, end in cuts if end > start)
    if not cuts:
        return samples
    removed_energy = sum(float(np.dot(samples[start:end], samples[start:end])) for start, end in cuts)
    total_energy = float(np.dot(samples, samples))
    if total_energy and removed_energy / total_energy > 0.001:
        return samples  # A supposedly quiet section contains too much audio to discard.
    chunks = []
    cursor = 0
    for start, end in cuts:
        if start < cursor:
            raise ValueError("overlapping pause cuts")
        chunks.append(samples[cursor:start])
        cursor = end
    chunks.append(samples[cursor:])
    return np.concatenate(chunks)


def make_candidate(record: dict, audio_dir: Path, candidate_dir: Path) -> str:
    key, text, voice = record["key"], record["text"], record["voice"]
    source = audio_dir / f"{key}.mp3"
    original, rate = decode(source)
    edited = shorten_pauses(original, rate, text)
    if len(edited) == len(original):
        return "no safe cut"
    if len(edited) < len(original) * 0.4 or signal_findings(edited, rate, text):
        return "PCM audit still flags clip or removes too much duration"
    _, channels, bitrate = mp3_format(source.read_bytes())
    if channels != 1:
        return "not mono"
    candidate_dir.mkdir(parents=True, exist_ok=True)
    dest = candidate_dir / f"{key}.mp3"
    processed = apply(edited, rate, plan(measure(edited, rate)))
    dest.write_bytes(tagged(encode_checked(processed, rate, max(64, bitrate))))
    checked = audit_clip((key, text, voice), candidate_dir)
    if checked["findings"]:
        dest.unlink()
        return "encoded candidate fails audio audit"
    return "ready"


def repair_if_needed(row: tuple[str, str, str], audio_dir: Path) -> None:
    """Repair a new clip's excessive silence, then enforce the audit gate."""
    record = audit_clip(row, audio_dir)
    if record["findings"]:
        codes = {finding["code"] for finding in record["findings"]}
        if not codes <= {"internal_pause", "edge_silence"}:
            require_clean_clip(row, audio_dir)
        with tempfile.TemporaryDirectory() as directory:
            candidates = Path(directory)
            result = make_candidate(record, audio_dir, candidates)
            if result != "ready":
                raise RuntimeError(f"{row[0]}: automatic pause repair failed: {result}")
            shutil.copy2(candidates / f"{row[0]}.mp3", audio_dir / f"{row[0]}.mp3")
    require_clean_clip(row, audio_dir)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--audio-dir", type=Path, default=DEFAULT_AUDIO)
    parser.add_argument("--candidate-dir", type=Path, default=Path("/tmp/carambole_audio_candidates"))
    parser.add_argument("--backup-dir", type=Path, default=Path("/tmp/carambole_audio_backups"))
    parser.add_argument("--apply", action="store_true", help="replace source clips only after candidate checks")
    args = parser.parse_args()
    require_codec()
    report = json.loads(args.report.read_text(encoding="utf-8"))
    pending = [record for record in report["issues"] if not record.get("reviewed")]
    results = {}
    for index, record in enumerate(pending, 1):
        state = make_candidate(record, args.audio_dir, args.candidate_dir)
        results[record["key"]] = state
        print(f"[{index}/{len(pending)}] {record['key']}: {state}", flush=True)
        if state == "ready" and args.apply:
            args.backup_dir.mkdir(parents=True, exist_ok=True)
            backup = args.backup_dir / f"{record['key']}.mp3"
            if not backup.exists():
                shutil.copy2(args.audio_dir / f"{record['key']}.mp3", backup)
            shutil.copy2(args.candidate_dir / f"{record['key']}.mp3",
                         args.audio_dir / f"{record['key']}.mp3")
    ready = sum(state == "ready" for state in results.values())
    print(f"{ready}/{len(pending)} candidates pass; {'replaced' if args.apply else 'not applied'}")


if __name__ == "__main__":
    main()
