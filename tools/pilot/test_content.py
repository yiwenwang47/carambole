"""Content contract for the connected café listening pilot."""

import json
from pathlib import Path
import unittest


PILOT = Path(__file__).resolve().parents[2] / "carambole/Debug/testbook_situation.json"
REQUIRED = {
    "id", "context", "turns", "question", "choices", "correctChoice",
    "responsePrompt", "replyTokens", "tokenBank", "acceptedReplies",
    "modelReply", "followUp", "explanationEN",
}


def render(chunks):
    return " ".join(chunks).replace(" ,", ",").replace(" .", ".")


class CafePilotContentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = json.loads(PILOT.read_text(encoding="utf-8"))

    def test_four_connected_scenes_have_complete_listening_and_reply_contracts(self):
        self.assertEqual(len(self.items), 4)
        self.assertEqual(len({item["id"] for item in self.items}), 4)
        self.assertEqual(len({item["context"] for item in self.items}), 1)
        for item in self.items:
            with self.subTest(item=item["id"]):
                self.assertEqual(set(item), REQUIRED)
                self.assertTrue(item["id"].startswith("sit_06_cafe_"))
                self.assertEqual([turn["speaker"] for turn in item["turns"]], ["customer", "server"])
                self.assertTrue(all(turn["text"].strip() for turn in item["turns"]))
                self.assertEqual(len(item["choices"]), 3)
                self.assertEqual(len(set(item["choices"])), 3)
                self.assertIn(item["correctChoice"], range(3))
                self.assertTrue(item["responsePrompt"].strip())
                self.assertTrue(item["explanationEN"].strip())
                self.assertTrue(item["followUp"].strip())

    def test_answer_keys_require_inference_across_audio_and_context(self):
        self.assertEqual(
            [item["choices"][item["correctChoice"]] for item in self.items],
            [
                "Coffee with soy milk",
                "The lentil salad",
                "You will eat in the café",
                "Scan the code with your phone",
            ],
        )
        self.assertIn("ten minutes", self.items[1]["context"])
        self.assertIn("un quart d’heure", self.items[1]["turns"][1]["text"])
        self.assertIn("doit passer au four", self.items[1]["turns"][1]["text"])

    def test_every_accepted_reply_is_buildable_and_model_is_accepted(self):
        for item in self.items:
            with self.subTest(item=item["id"]):
                self.assertGreaterEqual(len(item["acceptedReplies"]), 2)
                bank = item["tokenBank"]
                self.assertEqual(len(bank), len(set(bank)))
                self.assertIn(item["replyTokens"], item["acceptedReplies"])
                self.assertEqual(render(item["replyTokens"]), item["modelReply"])
                for reply in item["acceptedReplies"]:
                    self.assertTrue(reply)
                    self.assertEqual(len(reply), len(set(reply)))
                    self.assertTrue(all(token in bank for token in reply))
                self.assertGreater(len(bank), len(item["replyTokens"]))

    def test_repair_reply_corrects_takeaway_and_requests_a_box(self):
        repair = self.items[2]
        for reply in repair["acceptedReplies"]:
            spoken = render(reply).lower()
            self.assertIn("à emporter", spoken)
            self.assertIn("boîte", spoken)

    def test_shorter_valid_replies_are_accepted(self):
        self.assertIn(
            ["la salade de lentilles,", "s’il vous plaît."],
            self.items[1]["acceptedReplies"],
        )
        self.assertIn(
            ["je vais scanner le code", "avec mon téléphone."],
            self.items[3]["acceptedReplies"],
        )


if __name__ == "__main__":
    unittest.main()
