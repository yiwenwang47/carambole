import json
import pathlib
import unittest

import extract


class SpotAudioManifestTests(unittest.TestCase):
    def test_every_spot_variant_has_corrected_audio(self):
        rows = extract.collect()
        by_key = {row["key"]: row["text"] for row in rows}
        topics = pathlib.Path(extract.topics_dir())
        files = json.loads((topics / "manifest.json").read_text())["moduleFiles"]

        spot_count = 0
        for name in files:
            module = json.loads((topics / name).read_text())
            for element in module.get("elements", []):
                for example in element.get("examples", []):
                    spot = example.get("spot")
                    if spot is None:
                        continue
                    spot_count += 1
                    corrected = spot["tokens"].copy()
                    corrected[spot["wrongIndex"]] = spot["options"][0]
                    spoken = extract.spoken_french(
                        "Trouve l'erreur.", extract.display_join(corrected), False
                    )
                    self.assertEqual(by_key.get(extract.audio_key(spoken)), spoken)

        self.assertGreater(spot_count, 0)


if __name__ == "__main__":
    unittest.main()
