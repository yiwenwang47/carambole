"""Focused adapter checks for the production-to-pilot review path."""

import unittest

from tools.situations.generate_audio import item_clips, production_clips
from tools.situations.review_set import export


class ReviewAdapterTests(unittest.TestCase):
    def setUp(self):
        self.items = []
        for index in range(9):
            solo = index % 3 == 2
            kind = ("comprehend", "reply", "pick")[index % 3]
            item = {"id": f"sit_06_order_{'s' if solo else 'd'}{index + 1:02}",
                    "place": "Au café · phrase seule" if solo else "Au café",
                    "cue": "A cue", "turns": [],
                    "drills": [{"type": kind}], "newWords": []}
            if solo:
                item["standalone"] = "Choisir le ton"
            else:
                item["followUp"] = "D'accord."
            self.items.append(item)
        self.module = {"elements": [{"id": "sit_06_order", "title": "Commander",
                                     "items": self.items}]}
        self.words = {"words": [{"fr": "ouais", "en": "yeah", "spoken": True,
                                  "audio": "sitw_ouais", "firstSeen": None}]}

    def test_export_has_flat_pilot_shape_and_spoken_gloss(self):
        result = export(self.module, self.words, [item["id"] for item in self.items])
        self.assertEqual(len(result["dialogues"]), 9)
        self.assertEqual(result["dialogues"][0]["element"], "Commander")
        self.assertEqual(result["glossary"]["ouais"], "* yeah")

    def test_export_rejects_wrong_review_order(self):
        ids = [item["id"] for item in self.items]
        ids[1], ids[2] = ids[2], ids[1]
        with self.assertRaisesRegex(ValueError, "D D S"):
            export(self.module, self.words, ids)

    def test_production_audio_keys_use_item_id_once(self):
        item = {"id": "sit_06_order_d01",
                "turns": [{"speaker": "server", "name": "Karim", "text": "Bonjour !"}],
                "followUp": "Voilà."}
        clips = item_clips(item)
        self.assertEqual([key for key, _, _ in clips],
                         ["sit_06_order_d01_t0", "sit_06_order_d01_f"])
        rows = production_clips({"elements": [{"items": [item]}]}, self.words)
        self.assertEqual(rows[-1][0], "sitw_ouais")


if __name__ == "__main__":
    unittest.main()
