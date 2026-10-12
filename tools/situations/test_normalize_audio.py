"""Gain, peak, de-harsh and idempotency checks for normalize_audio."""

import importlib.util
import shutil
import tempfile
import unittest
from pathlib import Path

import numpy as np
from scipy import signal

from tools.situations import normalize_audio as na

SR = 24000
HAVE_CODEC = shutil.which("afconvert") is not None and importlib.util.find_spec("lameenc") is not None


def stats(lufs=-18.0, peak=-6.0, hf=-30.0) -> na.Stats:
    return na.Stats(lufs=lufs, true_peak_db=peak, sample_peak_db=peak, centroid_hz=500.0, hf_db=hf)


def speechlike(seconds=1.5, level=0.05, seed=1) -> np.ndarray:
    """Low-passed noise in syllable-sized bursts, with silent edges."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    t = np.arange(n) / SR
    noise = signal.sosfilt(signal.butter(4, 3000, fs=SR, output="sos"), rng.standard_normal(n))
    envelope = np.clip(np.sin(2 * np.pi * 3 * t), 0, None)
    x = level * noise * envelope
    x[:2 * na.MP3_FRAME] = 0
    x[-2 * na.MP3_FRAME:] = 0
    return x


class PlanTests(unittest.TestCase):
    def test_emphatic_burst_is_capped_below_target(self):
        x = speechlike(seconds=3.0)
        x[int(0.5 * SR):int(1.0 * SR)] *= 4.0  # a shouted word
        y = na.apply(x, SR, na.Plan(0.0, 0.0))
        self.assertLessEqual(na.max_momentary_loudness(y, SR), na.MOMENTARY_MAX_LUFS + 0.2)
        self.assertLess(na.integrated_loudness(y, SR), na.TARGET_LUFS - 0.5)

    def test_burst_at_target_is_not_noop(self):
        p = na.plan(na.Stats(-18.0, -6.0, -6.0, 500.0, -30.0, na.MOMENTARY_MAX_LUFS + 1.5))
        self.assertFalse(p.is_noop)

    def test_even_clip_still_reaches_target(self):
        y = na.apply(speechlike(seconds=3.0), SR, na.Plan(0.0, 0.0))
        self.assertAlmostEqual(na.integrated_loudness(y, SR), na.TARGET_LUFS, delta=0.3)

    def test_quiet_clip_gets_positive_gain_to_target(self):
        p = na.plan(stats(lufs=-24.0))
        self.assertAlmostEqual(p.gain_db, 6.0)
        self.assertEqual(p.shelf_db, 0.0)

    def test_loud_clip_gets_cut(self):
        self.assertAlmostEqual(na.plan(stats(lufs=-13.0)).gain_db, -5.0)

    def test_within_tolerance_and_safe_is_noop(self):
        self.assertTrue(na.plan(stats(lufs=na.TARGET_LUFS + 0.4)).is_noop)

    def test_hot_peak_forces_processing_even_at_target(self):
        p = na.plan(stats(lufs=na.TARGET_LUFS, peak=0.2))
        self.assertFalse(p.is_noop)

    def test_bright_clip_gets_shelf_equal_to_excess(self):
        p = na.plan(stats(hf=na.HF_MAX_DB + 2.5))
        self.assertAlmostEqual(p.shelf_db, -2.5)

    def test_shelf_is_capped(self):
        self.assertEqual(na.plan(stats(hf=-3.0)).shelf_db, -na.MAX_SHELF_DB)

    def test_slightly_bright_within_tolerance_gets_no_shelf(self):
        self.assertEqual(na.plan(stats(hf=na.HF_MAX_DB + 0.5)).shelf_db, 0.0)

    def test_clip_target_ducks_only_sibilant_dominated_clips(self):
        self.assertEqual(na.clip_target(-20.0), na.TARGET_LUFS)
        self.assertAlmostEqual(na.clip_target(na.HF_DUCK_DB + 3), na.TARGET_LUFS - 3)
        self.assertEqual(na.clip_target(0.0), na.TARGET_LUFS - na.MAX_DUCK_DB)


class SignalTests(unittest.TestCase):
    def test_loudness_of_reference_sine(self):
        # BS.1770: a full-scale 997 Hz sine reads -3.01 LUFS.
        t = np.arange(3 * SR) / SR
        self.assertAlmostEqual(na.integrated_loudness(np.sin(2 * np.pi * 997 * t), SR), -3.01, delta=0.1)

    def test_limiter_holds_ceiling_and_leaves_quiet_audio_alone(self):
        x = speechlike(level=0.6)
        y = na.limit(x, SR)
        self.assertLessEqual(na.true_peak_db(y), na.CEILING_DBTP + 0.05)
        quiet = speechlike(level=0.01)
        np.testing.assert_array_equal(na.limit(quiet, SR), quiet)

    def test_apply_hits_target_under_ceiling_and_is_then_a_noop(self):
        for level in (0.005, 0.05, 0.4):
            y = na.apply(speechlike(level=level), SR, na.Plan(1.0, 0.0))
            self.assertAlmostEqual(na.integrated_loudness(y, SR), na.TARGET_LUFS, delta=0.2)
            self.assertLessEqual(na.true_peak_db(y), na.CEILING_DBTP + 0.05)
            self.assertTrue(na.plan(na.measure(y, SR)).is_noop)

    def test_shelf_lowers_high_frequency_share(self):
        rng = np.random.default_rng(3)
        x = 0.05 * rng.standard_normal(SR)  # white noise: very bright
        before = na.brightness(x, SR)[1]
        after = na.brightness(na.apply(x, SR, na.Plan(0.0, -4.0)), SR)[1]
        self.assertLess(after, before - 1.0)


class TagTests(unittest.TestCase):
    FRAME = bytes([0xFF, 0xF3, 0x44, 0xC4]) + bytes(92)  # MPEG-2 L3 32 kbps 24 kHz mono

    def test_tag_round_trip_keeps_format_and_does_not_stack(self):
        data = self.FRAME * 3
        self.assertFalse(na.is_tagged(data))
        once = na.tagged(data)
        self.assertTrue(na.is_tagged(once))
        self.assertEqual(na.mp3_format(once), (24000, 1, 32))
        self.assertEqual(na.tagged(once), once)


@unittest.skipUnless(HAVE_CODEC, "needs afconvert and lameenc")
class FileTests(unittest.TestCase):
    def test_process_keeps_length_and_second_run_is_skipped(self):
        x = speechlike(seconds=1.2, level=0.01)
        n = (len(x) // na.MP3_FRAME) * na.MP3_FRAME
        with tempfile.TemporaryDirectory() as tmp:
            # A first-generation clip: encoder delay/padding frames are silent.
            src = Path(tmp) / "clip.mp3"
            src.write_bytes(na.encode(x[:n], SR, 64))
            original, _ = na.decode(src)
            first = na.process_file(src)
            self.assertTrue(first.changed)
            processed = src.read_bytes()
            y, sr = na.decode(src)
            self.assertEqual(sr, SR)
            self.assertEqual(len(y), len(original))
            self.assertAlmostEqual(na.integrated_loudness(y, SR), na.TARGET_LUFS, delta=na.LOUDNESS_TOLERANCE_LU)
            self.assertLessEqual(na.sample_peak_db(y), -1.5)
            second = na.process_file(src)
            self.assertIsNone(second.before)
            self.assertEqual(src.read_bytes(), processed)


if __name__ == "__main__":
    unittest.main()
