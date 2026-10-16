"""Checks for the signal rules used by the Book 2 audio audit."""

import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
import json
import subprocess
import sys

import numpy as np

from tools.situations import audio_audit


SR = 24000


def voiced(seconds: float) -> np.ndarray:
    t = np.arange(round(seconds * SR)) / SR
    return 0.12 * np.sin(2 * np.pi * 220 * t)


def silence(seconds: float) -> np.ndarray:
    return np.zeros(round(seconds * SR))


class PauseTests(unittest.TestCase):
    def test_flags_long_internal_gap_like_broken_cetait_clip(self):
        x = np.concatenate([silence(.3), voiced(.2), silence(.65), voiced(1.4), silence(.2)])
        result = audio_audit.signal_findings(x, SR, "C'était top, hier ! À refaire !")
        self.assertTrue(any(f.code == "internal_pause" for f in result))

    def test_accepts_pause_aligned_with_punctuation(self):
        x = np.concatenate([voiced(.4), silence(.8), voiced(.6)])
        result = audio_audit.signal_findings(x, SR, "Salut ! Ça va ?")
        self.assertFalse(any(f.code == "internal_pause" for f in result))

    def test_very_long_pause_is_flagged_even_at_punctuation(self):
        x = np.concatenate([voiced(.4), silence(1.3), voiced(.6)])
        result = audio_audit.signal_findings(x, SR, "Salut ! Ça va ?")
        self.assertTrue(any(f.code == "internal_pause" for f in result))

    def test_does_not_count_codec_padding_or_short_consonant_gap(self):
        x = np.concatenate([silence(.4), voiced(.2), silence(.08), voiced(.3), silence(.5)])
        result = audio_audit.signal_findings(x, SR, "C'était top")
        self.assertFalse(any(f.code == "internal_pause" for f in result))
        self.assertFalse(any(f.code == "edge_silence" for f in result))

    def test_flags_excessive_edge_silence_and_empty_clip(self):
        x = np.concatenate([silence(1.2), voiced(.3), silence(1.2)])
        codes = {f.code for f in audio_audit.signal_findings(x, SR, "Bonjour")}
        self.assertIn("edge_silence", codes)
        codes = {f.code for f in audio_audit.signal_findings(silence(1), SR, "Bonjour")}
        self.assertIn("silent", codes)

    def test_short_word_does_not_get_a_sentence_pause_warning(self):
        x = np.concatenate([voiced(.2), silence(.7), voiced(.2)])
        codes = {f.code for f in audio_audit.signal_findings(x, SR, "bonjour")}
        self.assertNotIn("internal_pause", codes)


class GateTests(unittest.TestCase):
    def test_missing_clip_blocks_generation(self):
        with TemporaryDirectory() as directory:
            with self.assertRaisesRegex(RuntimeError, "missing"):
                audio_audit.require_clean_clip(("absent", "Bonjour", "voice"), Path(directory))

    def test_review_is_bound_to_exact_audio_and_requires_reason(self):
        record = {"key": "a", "sha256": "abc", "findings": [{"code": "internal_pause", "detail": "gap"}]}
        approved = {"a": {"sha256": "abc", "codes": ["internal_pause"], "reason": "heard; natural pause"}}
        self.assertTrue(audio_audit.is_reviewed(record, approved))
        self.assertFalse(audio_audit.is_reviewed({**record, "sha256": "changed"}, approved))
        self.assertFalse(audio_audit.is_reviewed(record, {"a": {**approved["a"], "reason": ""}}))
        self.assertFalse(audio_audit.is_reviewed(record, {"a": {**approved["a"], "reason": None}}))
        self.assertFalse(audio_audit.is_reviewed({**record, "findings": [{"code": "invalid"}]},
                                                 {"a": {**approved["a"], "codes": ["invalid"]}}))

    def test_future_book_index_writes_report_and_fails_for_missing_audio(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            index = root / "index.json"
            index.write_text(json.dumps([{"key": "future_1", "text": "Bonjour", "voice": "voice"}]))
            report = root / "report.json"
            result = subprocess.run([sys.executable, str(Path(audio_audit.__file__)),
                                     "--index", str(index), "--audio-dir", str(root),
                                     "--report", str(report)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            self.assertEqual(json.loads(report.read_text())["counts"], {"missing": 1})
            self.assertTrue(report.with_suffix(".html").is_file())


if __name__ == "__main__":
    unittest.main()
