"""Conservative removal of excessive quiet gaps from bundled speech."""

import unittest
import importlib.util
import shutil
from pathlib import Path
from tempfile import TemporaryDirectory

import numpy as np

from tools.situations.audio_audit import audit_clip, signal_findings
from tools.situations.normalize_audio import encode
from tools.situations.repair_audio import repair_if_needed, shorten_pauses


SR = 24000


def voice(seconds: float) -> np.ndarray:
    t = np.arange(round(seconds * SR)) / SR
    return 0.1 * np.sin(2 * np.pi * 220 * t)


def quiet(seconds: float) -> np.ndarray:
    return np.zeros(round(seconds * SR))


class RepairTests(unittest.TestCase):
    def test_shortens_unexplained_pause_and_preserves_speech(self):
        first, second = voice(.2), voice(1.4)
        old = np.concatenate([first, quiet(.65), second])
        new = shorten_pauses(old, SR, "C'était top, hier ! À refaire !")
        self.assertLess(len(new), len(old))
        np.testing.assert_array_equal(new[:len(first)], first)
        np.testing.assert_array_equal(new[-len(second):], second)
        self.assertFalse(signal_findings(new, SR, "C'était top, hier ! À refaire !"))

    def test_keeps_ordinary_punctuation_pause(self):
        old = np.concatenate([voice(.4), quiet(.8), voice(.6)])
        np.testing.assert_array_equal(shorten_pauses(old, SR, "Salut ! Ça va ?"), old)

    def test_shortens_very_long_punctuation_pause(self):
        old = np.concatenate([voice(.4), quiet(1.3), voice(.6)])
        new = shorten_pauses(old, SR, "Salut ! Ça va ?")
        self.assertLess(len(new), len(old))
        self.assertFalse(signal_findings(new, SR, "Salut ! Ça va ?"))

    def test_caps_large_silent_edges(self):
        old = np.concatenate([quiet(1.2), voice(.3), quiet(1.2)])
        new = shorten_pauses(old, SR, "Bonjour")
        self.assertFalse(signal_findings(new, SR, "Bonjour"))

    def test_does_not_discard_low_level_audio_in_a_gap(self):
        t = np.arange(2 * SR) / SR
        low_voice = 0.0018 * np.sin(2 * np.pi * 220 * t)
        old = np.concatenate([voice(.2), low_voice, voice(.2)])
        np.testing.assert_array_equal(shorten_pauses(old, SR, "Bonjour encore"), old)


@unittest.skipUnless(shutil.which("afconvert") and importlib.util.find_spec("lameenc"),
                     "needs MP3 codec")
class GeneratedClipTests(unittest.TestCase):
    def test_generation_repairs_a_long_gap_before_accepting_clip(self):
        with TemporaryDirectory() as directory:
            audio_dir = Path(directory)
            path = audio_dir / "sample.mp3"
            path.write_bytes(encode(np.concatenate([voice(.2), quiet(.7), voice(.4)]), SR, 64))
            row = ("sample", "Bonjour encore", "voice")
            self.assertTrue(audit_clip(row, audio_dir)["findings"])
            repair_if_needed(row, audio_dir)
            self.assertFalse(audit_clip(row, audio_dir)["findings"])


if __name__ == "__main__":
    unittest.main()
