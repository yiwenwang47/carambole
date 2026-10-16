"""Release audio checks must cover every registered production book."""

import json
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest


GATE = Path(__file__).with_name("audio_release_gate.py")


class ReleaseGateTests(unittest.TestCase):
    def test_future_book_with_missing_clip_blocks_release(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            index = root / "clips.json"
            index.write_text(json.dumps([{"key": "future_1", "text": "Bonjour", "voice": "voice"}]))
            registry = root / "books.json"
            registry.write_text(json.dumps({"books": [{"id": "future", "index": str(index),
                                                        "audio_dir": str(root / "audio"),
                                                        "report": str(root / "report.json") }]}))
            result = subprocess.run([sys.executable, str(GATE), "--registry", str(registry)],
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertEqual(json.loads((root / "report.json").read_text())["counts"], {"missing": 1})

    def test_empty_registry_blocks_release(self):
        with TemporaryDirectory() as directory:
            registry = Path(directory) / "books.json"
            registry.write_text('{"books": []}')
            result = subprocess.run([sys.executable, str(GATE), "--registry", str(registry)],
                                    capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
