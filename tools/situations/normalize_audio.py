#!/usr/bin/env python3
"""Even out clip loudness and soften harsh highs in bundled MP3 audio.

Every clip is brought to TARGET_LUFS integrated loudness (ITU-R BS.1770,
K-weighted, gated) with decoded true peaks at or below PEAK_LIMIT_DBTP (a 5 ms
look-ahead limiter at CEILING_DBTP catches the clips that need it). De-harshing: a clip whose energy
above 5 kHz is more than HF_MAX_DB of the whole gets a gentle high shelf at
6 kHz, cut by the excess and at most MAX_SHELF_DB. A clip that is still
sibilant-dominated after the shelf (a lone « ce », « six ») is aimed lower
than the target by its remaining excess over HF_DUCK_DB, at most MAX_DUCK_DB,
so a word that is mostly hiss is not pushed up into a loud hiss.

The file keeps its name, MP3 format, sample rate, channel count and CBR
bitrate, and decodes to the same length, sample-aligned with the original
(see `encode` for the rare clip with sound in its first or last frame).

Idempotent: a processed file carries an ID3 TXXX tag `carambole-normalize`
and is skipped on later runs (`--force` overrides; only force on originals,
since a second shelf would compound). A clip already within tolerance, not
bright and with safe peaks is only tagged, never re-encoded.

Needs macOS `afconvert` (decode), numpy, scipy and lameenc (encode).

    python3 tools/situations/normalize_audio.py --all            # every clip
    python3 tools/situations/normalize_audio.py a.mp3 b.mp3      # given files
    python3 tools/situations/normalize_audio.py --all --check    # report only
"""

from __future__ import annotations

import argparse
from concurrent.futures import ProcessPoolExecutor
from dataclasses import dataclass
import math
import os
from pathlib import Path
import subprocess
import tempfile
import wave

import numpy as np
from scipy import signal
from scipy.ndimage import minimum_filter1d, uniform_filter1d

ROOT = Path(__file__).resolve().parents[2]
AUDIO = ROOT / "carambole/Resources/Audio"

TARGET_LUFS = -18.0
MOMENTARY_MAX_LUFS = -15.5  # loudest 400 ms block; emphatic bursts sound loud even at -18 LUFS integrated
CEILING_DBTP = -2.0  # limiter ceiling; leaves 0.5 dB for MP3 overshoot under -1.5
LOUDNESS_TOLERANCE_LU = 0.5
PEAK_LIMIT_DBTP = -1.5  # a clip is "done" while its decoded true peak stays at or below this
HF_SPLIT_HZ = 5000.0
HF_MAX_DB = -23.0  # energy above 5 kHz relative to the whole clip; above this is "bright"
HF_TOLERANCE_DB = 1.0
SHELF_HZ = 6000.0
MAX_SHELF_DB = 4.0
HF_DUCK_DB = -12.0  # after the shelf, HF share above this lowers the clip's target
MAX_DUCK_DB = 8.0
TAG_KEY = b"carambole-normalize"
TAG_VALUE = f"v2 {TARGET_LUFS:g} LUFS, momentary <= {MOMENTARY_MAX_LUFS:g}, ceiling {CEILING_DBTP:g} dBTP".encode()
MP3_FRAME = 576  # samples per MPEG-2/2.5 layer III frame (TTS clips are 24 kHz)
EDGE_SILENT_DB = -40.0  # an edge frame this far below the clip's peak is codec delay/padding


@dataclass(frozen=True)
class Stats:
    lufs: float
    true_peak_db: float
    sample_peak_db: float
    centroid_hz: float
    hf_db: float
    momentary_max: float = -99.0  # loudest 400 ms block, LUFS


@dataclass(frozen=True)
class Plan:
    gain_db: float
    shelf_db: float  # <= 0; 0 means no de-harsh cut
    is_noop: bool = False  # already within tolerance: leave the audio alone


# ---------------------------------------------------------------- filters

def biquad_high_shelf(sr: int, fc: float, gain_db: float, q: float) -> tuple[np.ndarray, np.ndarray]:
    """RBJ cookbook high shelf (same form pyloudnorm uses for K-weighting)."""
    a = 10 ** (gain_db / 40)
    w0 = 2 * math.pi * fc / sr
    alpha = math.sin(w0) / (2 * q)
    cos = math.cos(w0)
    root = 2 * math.sqrt(a) * alpha
    b = np.array([a * ((a + 1) + (a - 1) * cos + root),
                  -2 * a * ((a - 1) + (a + 1) * cos),
                  a * ((a + 1) + (a - 1) * cos - root)])
    den = np.array([(a + 1) - (a - 1) * cos + root,
                    2 * ((a - 1) - (a + 1) * cos),
                    (a + 1) - (a - 1) * cos - root])
    return b / den[0], den / den[0]


def biquad_high_pass(sr: int, fc: float, q: float) -> tuple[np.ndarray, np.ndarray]:
    w0 = 2 * math.pi * fc / sr
    alpha = math.sin(w0) / (2 * q)
    cos = math.cos(w0)
    b = np.array([(1 + cos) / 2, -(1 + cos), (1 + cos) / 2])
    den = np.array([1 + alpha, -2 * cos, 1 - alpha])
    return b / den[0], den / den[0]


def k_weight(x: np.ndarray, sr: int) -> np.ndarray:
    # The pyloudnorm "K-weighting" stages (RBJ biquads at any sample rate).
    b1, a1 = biquad_high_shelf(sr, 1500.0, 4.0, 1 / math.sqrt(2))
    b2, a2 = biquad_high_pass(sr, 38.0, 0.5)
    return signal.lfilter(b2, a2, signal.lfilter(b1, a1, x))


# ---------------------------------------------------------------- measures

def integrated_loudness(x: np.ndarray, sr: int) -> float:
    """BS.1770-4 integrated loudness (mono). A clip shorter than one 400 ms
    block, or with every block gated out, is measured as one block."""
    y = k_weight(np.asarray(x, dtype=np.float64), sr)
    block, step = int(0.4 * sr), int(0.1 * sr)
    if len(y) >= block:
        starts = range(0, len(y) - block + 1, step)
        z = np.array([np.mean(y[s:s + block] ** 2) for s in starts])
        z = z[-0.691 + 10 * np.log10(z + 1e-20) > -70]
        if len(z):
            rel = -0.691 + 10 * np.log10(np.mean(z)) - 10
            kept = z[-0.691 + 10 * np.log10(z) > rel]
            if len(kept):
                return float(-0.691 + 10 * np.log10(np.mean(kept)))
    return float(-0.691 + 10 * np.log10(np.mean(y ** 2) + 1e-20))


def max_momentary_loudness(x: np.ndarray, sr: int) -> float:
    """Loudest 400 ms block (BS.1770 momentary loudness, 100 ms hop)."""
    y = k_weight(np.asarray(x, dtype=np.float64), sr)
    block, step = int(0.4 * sr), int(0.1 * sr)
    if len(y) < block:
        return float(-0.691 + 10 * np.log10(np.mean(y ** 2) + 1e-20))
    z = max(np.mean(y[s:s + block] ** 2) for s in range(0, len(y) - block + 1, step))
    return float(-0.691 + 10 * np.log10(z + 1e-20))


def burst_capped(target: float, x: np.ndarray, sr: int) -> float:
    """Lower the integrated target so the loudest 400 ms stays under MOMENTARY_MAX_LUFS."""
    burst = max_momentary_loudness(x, sr) - integrated_loudness(x, sr)
    return min(target, MOMENTARY_MAX_LUFS - burst)


def true_peak_db(x: np.ndarray) -> float:
    """4x oversampled peak (BS.1770 annex 2 style), in dBTP."""
    up = signal.resample_poly(np.asarray(x, dtype=np.float64), 4, 1)
    return float(20 * np.log10(max(np.max(np.abs(up)), np.max(np.abs(x)), 1e-9)))


def sample_peak_db(x: np.ndarray) -> float:
    return float(20 * np.log10(max(float(np.max(np.abs(x))), 1e-9)))


def brightness(x: np.ndarray, sr: int) -> tuple[float, float]:
    """(spectral centroid in Hz, energy above HF_SPLIT_HZ in dB re total),
    over 20 ms frames within 40 dB of the loudest frame (speech, not pauses)."""
    n = int(0.02 * sr)
    if len(x) < n:
        return 0.0, -99.0
    f, _, s = signal.stft(x, fs=sr, nperseg=n, noverlap=n // 2, boundary=None)
    p = np.abs(s) ** 2
    e = p.sum(axis=0)
    p = p[:, e > e.max() * 1e-4]
    total = p.sum()
    if total <= 0:
        return 0.0, -99.0
    centroid = float((f[:, None] * p).sum() / total)
    hf = float(p[f >= HF_SPLIT_HZ].sum() / total)
    return centroid, float(10 * np.log10(hf + 1e-12))


def measure(x: np.ndarray, sr: int) -> Stats:
    centroid, hf = brightness(x, sr)
    return Stats(integrated_loudness(x, sr), true_peak_db(x), sample_peak_db(x), centroid, hf,
                 max_momentary_loudness(x, sr))


# ---------------------------------------------------------------- the rule

def plan(stats: Stats) -> Plan:
    """Gain to reach TARGET_LUFS and a de-harsh shelf for bright clips.

    No-op when loudness is within tolerance, peaks are safe and the clip is
    not bright: that is what keeps repeated runs from drifting."""
    shelf = 0.0
    excess = stats.hf_db - HF_MAX_DB
    if excess > HF_TOLERANCE_DB:
        shelf = -round(min(MAX_SHELF_DB, excess), 2)
    gain = TARGET_LUFS - stats.lufs
    burst_ok = stats.momentary_max <= MOMENTARY_MAX_LUFS + LOUDNESS_TOLERANCE_LU
    if abs(gain) <= LOUDNESS_TOLERANCE_LU and stats.true_peak_db <= PEAK_LIMIT_DBTP and shelf == 0.0 and burst_ok:
        return Plan(0.0, 0.0, is_noop=True)
    return Plan(round(gain, 2), shelf)


def clip_target(hf_db_after_shelf: float) -> float:
    """Loudness target for a clip, given its HF share once de-harshed."""
    duck = min(MAX_DUCK_DB, max(0.0, hf_db_after_shelf - HF_DUCK_DB))
    return TARGET_LUFS - duck


def limit(x: np.ndarray, sr: int, ceiling_db: float = CEILING_DBTP) -> np.ndarray:
    """Look-ahead peak limiter: a smooth gain curve that never exceeds the
    per-sample gain needed to keep (oversampled) peaks under the ceiling."""
    ceiling = 10 ** (ceiling_db / 20)
    up = np.abs(signal.resample_poly(x, 4, 1))[:4 * len(x)]  # inter-sample peaks
    peak = np.maximum(np.abs(x), up.reshape(len(x), 4).max(axis=1))
    need = np.minimum(1.0, ceiling / np.maximum(peak, 1e-12))
    if need.min() >= 1.0:
        return x
    width = max(3, int(0.005 * sr) | 1)  # 5 ms attack/look-ahead
    held = minimum_filter1d(need, size=2 * width + 1, mode="nearest")
    gain = uniform_filter1d(held, size=width, mode="nearest")
    return x * np.minimum(gain, need)


def apply(x: np.ndarray, sr: int, p: Plan) -> np.ndarray:
    y = np.asarray(x, dtype=np.float64)
    target = TARGET_LUFS
    if p.shelf_db:
        b, a = biquad_high_shelf(sr, SHELF_HZ, p.shelf_db, 1 / math.sqrt(2))
        y = signal.lfilter(b, a, y)
        target = clip_target(brightness(y, sr)[1])
    target = burst_capped(target, y, sr)
    # Gain is re-measured here, after the shelf, rather than taken from the plan.
    y = y * 10 ** ((target - integrated_loudness(y, sr)) / 20)
    for _ in range(3):  # limiting trims loudness slightly; nudge back up
        y = limit(y, sr)
        short = target - integrated_loudness(y, sr)
        if short <= 0.1:
            break
        y = y * 10 ** (short / 20)
    return limit(y, sr)


# ---------------------------------------------------------------- MP3 I/O

_BITRATES = {  # kbps by (version bits, index), layer III
    3: [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320],
    2: [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160],
    0: [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160],
}
_RATES = {3: [44100, 48000, 32000], 2: [22050, 24000, 16000], 0: [11025, 12000, 8000]}


def mp3_format(data: bytes) -> tuple[int, int, int]:
    """(sample rate, channels, kbps) from the first frame header."""
    i = 0
    if data[:3] == b"ID3":
        size = (data[6] << 21) | (data[7] << 14) | (data[8] << 7) | data[9]
        i = 10 + size
    while i < len(data) - 4:
        if data[i] == 0xFF and data[i + 1] & 0xE0 == 0xE0:
            version = (data[i + 1] >> 3) & 3
            layer = (data[i + 1] >> 1) & 3
            br_index = data[i + 2] >> 4
            sr_index = (data[i + 2] >> 2) & 3
            if version != 1 and layer == 1 and 0 < br_index < 15 and sr_index < 3:
                channels = 1 if data[i + 3] >> 6 == 3 else 2
                return _RATES[version][sr_index], channels, _BITRATES[version][br_index]
        i += 1
    raise ValueError("no MPEG layer III frame header found")


def decode(path: Path) -> tuple[np.ndarray, int]:
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "x.wav"
        subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16", str(path), str(wav)],
                       check=True, capture_output=True)
        with wave.open(str(wav)) as w:
            sr, ch = w.getframerate(), w.getnchannels()
            pcm = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2")
    x = pcm.astype(np.float64) / 32768.0
    if ch > 1:
        x = x.reshape(-1, ch).mean(axis=1)
    return x, sr


def decode_bytes(data: bytes) -> tuple[np.ndarray, int]:
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "x.mp3"
        path.write_bytes(data)
        return decode(path)


def encode(x: np.ndarray, sr: int, kbps: int) -> bytes:
    """CBR MP3 whose decode (afconvert / Core Audio) lines up sample for
    sample with `x` and has the same length.

    LAME delays the signal by one frame and pads the end; Core Audio strips
    neither. The first and last frame of a TTS clip hold the original
    encoder's delay and padding, so when they are silent (EDGE_SILENT_DB
    under the clip's peak, a gain-independent test) they are dropped and the decode keeps the original length and timing.
    When one holds sound it is kept, and the decode is one frame (24 ms)
    longer at that end instead; nothing audible is ever cut."""
    import lameenc

    silent = np.max(np.abs(x)) * 10 ** (EDGE_SILENT_DB / 20)
    head = MP3_FRAME if np.max(np.abs(x[:MP3_FRAME])) < silent else 0
    tail = MP3_FRAME if np.max(np.abs(x[-MP3_FRAME:])) < silent else 0
    body = x[head:len(x) - tail] if len(x) > 3 * MP3_FRAME else x
    enc = lameenc.Encoder()
    enc.set_bit_rate(kbps)
    enc.set_in_sample_rate(sr)
    enc.set_out_sample_rate(sr)
    enc.set_channels(1)
    enc.set_quality(2)
    pcm = np.clip(np.round(body * 32767), -32768, 32767).astype("<i2").tobytes()
    return bytes(enc.encode(pcm) + enc.flush())


def _energy_db(x: np.ndarray, sr: int) -> float:
    """Ungated K-weighted level: stable under tiny changes, unlike the gated
    integrated loudness of a sub-second clip, which can jump ~1 LU."""
    return float(10 * np.log10(np.mean(k_weight(x, sr) ** 2) + 1e-20))


def encode_checked(y: np.ndarray, sr: int, kbps: int) -> bytes:
    """Encode, then undo the codec's level shift (about -0.45 dB, steady)
    and keep the decoded true peak at or below PEAK_LIMIT_DBTP."""
    gain_db, ceiling = 0.0, CEILING_DBTP
    for _ in range(4):
        out = encode(limit(y * 10 ** (gain_db / 20), sr, ceiling), sr, kbps)
        z = decode_bytes(out)[0]
        drift = _energy_db(z, sr) - _energy_db(y, sr)
        peak = true_peak_db(z)
        if abs(drift) <= 0.1 and peak <= PEAK_LIMIT_DBTP:
            break
        gain_db -= drift
        if peak - drift > PEAK_LIMIT_DBTP:  # the peak once the drift is undone
            ceiling -= peak - drift - PEAK_LIMIT_DBTP + 0.1
    return out


def _syncsafe(n: int) -> bytes:
    return bytes([(n >> 21) & 0x7F, (n >> 14) & 0x7F, (n >> 7) & 0x7F, n & 0x7F])


def is_tagged(data: bytes) -> bool:
    if data[:3] != b"ID3":
        return False
    size = (data[6] << 21) | (data[7] << 14) | (data[8] << 7) | data[9]
    return TAG_KEY in data[10:10 + size]


def tagged(data: bytes) -> bytes:
    """Prefix an ID3v2.3 tag holding one TXXX frame (the processed marker).
    Any existing ID3v2 tag is replaced; TTS clips carry none."""
    if data[:3] == b"ID3":
        data = data[10 + ((data[6] << 21) | (data[7] << 14) | (data[8] << 7) | data[9]):]
    body = b"\x00" + TAG_KEY + b"\x00" + TAG_VALUE
    frame = b"TXXX" + len(body).to_bytes(4, "big") + b"\x00\x00" + body
    return b"ID3\x03\x00\x00" + _syncsafe(len(frame)) + frame + data


# ---------------------------------------------------------------- files

def require_codec() -> None:
    """Fail before any TTS spend if the clips could not be normalised."""
    import shutil

    missing = [name for name, ok in (("afconvert (macOS)", shutil.which("afconvert")),
                                     ("lameenc (pip install lameenc)", _has("lameenc")))
               if not ok]
    if missing:
        raise SystemExit("normalize_audio needs " + " and ".join(missing))


def _has(module: str) -> bool:
    import importlib.util

    return importlib.util.find_spec(module) is not None


@dataclass(frozen=True)
class Result:
    name: str
    before: Stats | None  # None: already tagged, not measured
    plan: Plan
    changed: bool


def _write(path: Path, data: bytes) -> None:
    tmp = path.with_suffix(".mp3.tmp")
    tmp.write_bytes(data)
    os.replace(tmp, path)


def process_file(path: Path, check: bool = False, force: bool = False) -> Result:
    path = Path(path)
    data = path.read_bytes()
    if is_tagged(data) and not force and not check:
        return Result(path.name, None, Plan(0.0, 0.0, is_noop=True), False)
    sr, channels, kbps = mp3_format(data)
    if channels != 1:
        raise ValueError(f"{path.name}: expected mono, got {channels} channels")
    x, decoded_sr = decode(path)
    if decoded_sr != sr:
        raise ValueError(f"{path.name}: header says {sr} Hz, decoder gave {decoded_sr} Hz")
    before = measure(x, sr)
    p = plan(before)
    if check:
        return Result(path.name, before, p, False)
    if p.is_noop:
        _write(path, tagged(data))  # lossless: only the marker is added
        return Result(path.name, before, p, False)
    _write(path, tagged(encode_checked(apply(x, sr, p), sr, kbps)))
    return Result(path.name, before, p, True)


def process_files(paths: list[Path], check: bool = False, force: bool = False,
                  jobs: int | None = None) -> list[Result]:
    paths = [Path(p) for p in paths]
    if len(paths) < 8:
        return [process_file(p, check, force) for p in paths]
    n = len(paths)
    with ProcessPoolExecutor(max_workers=jobs) as pool:
        return list(pool.map(process_file, paths, [check] * n, [force] * n, chunksize=16))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("files", nargs="*", type=Path)
    parser.add_argument("--all", action="store_true", help=f"every *.mp3 in {AUDIO.relative_to(ROOT)}")
    parser.add_argument("--check", action="store_true", help="measure and report; change nothing")
    parser.add_argument("--force", action="store_true",
                        help="re-process tagged files too (use on originals only)")
    parser.add_argument("--jobs", type=int)
    args = parser.parse_args()
    paths = sorted(AUDIO.glob("*.mp3")) if args.all else args.files
    if not paths:
        parser.error("give MP3 files or --all")
    results = process_files(paths, args.check, args.force, args.jobs)
    skipped = sum(1 for r in results if r.before is None)
    todo = [r for r in results if not r.plan.is_noop]
    verb = "would re-encode" if args.check else "re-encoded"
    print(f"{len(results)} clips; {skipped} already normalised; {verb} {len(todo)}; "
          f"de-harshed {sum(1 for r in todo if r.plan.shelf_db)}")
    for r in todo[:20] if args.check else []:
        print(f"  {r.name}: {r.before.lufs:.1f} LUFS, peak {r.before.true_peak_db:.1f} dBTP, "
              f"HF {r.before.hf_db:.1f} dB -> gain {r.plan.gain_db:+.1f} dB, shelf {r.plan.shelf_db:.1f} dB")


if __name__ == "__main__":
    main()
