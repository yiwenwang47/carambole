"""Content contract for the Book 2 pilot (design rework + drill mix, 2026-10-11)."""

import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
PILOT = ROOT / "carambole/Debug/testbook_situation.json"
AUDIO = ROOT / "carambole/Resources/Audio"
KINDS = {"comprehend", "reply", "pick", "complete", "fix", "word"}


def norm(word):
    return word.lower().replace("’", "'").strip(".,!?;:«»… ")


def words(text):
    return [w for w in text.split() if norm(w)]


class DialoguePilotContentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        data = json.loads(PILOT.read_text(encoding="utf-8"))
        cls.glossary = data["glossary"]
        cls.items = data["dialogues"]

    def test_short_dialogues_with_one_or_two_drills(self):
        self.assertEqual(len({d["id"] for d in self.items}), len(self.items))
        for d in self.items:
            with self.subTest(d["id"]):
                solo = "standalone" in d
                self.assertTrue(d["id"].startswith("sit_06_solo_" if solo else "sit_06_cafe_"))
                if solo:
                    self.assertNotIn("followUp", d)
                    self.assertTrue(len(d["turns"]) <= 2)
                    self.assertEqual(len(d["drills"]), 1)
                else:
                    self.assertTrue(d["followUp"])
                    self.assertTrue(1 <= len(d["turns"]) <= 3)
                self.assertTrue(all(len(words(t["text"])) <= 10 for t in d["turns"]))
                types = [x["type"] for x in d["drills"]]
                self.assertTrue(1 <= len(types) <= 2)
                self.assertEqual(len(types), len(set(types)))
                self.assertFalse({"reply", "pick"} <= set(types))

    def test_one_standalone_per_two_dialogues_never_back_to_back(self):
        pattern = ["standalone" in d for d in self.items]
        self.assertEqual(pattern, [False, False, True] * (len(pattern) // 3))
        labels = [d.get("standalone") or "+".join(x["type"] for x in d["drills"]) for d in self.items]
        for a, b in zip(labels, labels[1:]):
            self.assertNotEqual(a, b)

    def test_drill_types_are_known(self):
        self.assertLessEqual({x["type"] for d in self.items for x in d["drills"]}, KINDS)

    def test_choice_drills_have_one_valid_answer_and_reasons(self):
        for d in self.items:
            for x in d["drills"]:
                if x["type"] in {"comprehend", "word", "pick", "complete"}:
                    with self.subTest(d["id"], kind=x["type"]):
                        need = 2 if x["type"] == "comprehend" else 3
                        self.assertEqual(len(set(x["choices"])), need)
                        self.assertIn(x["correct"], range(need))
                        if x["type"] in {"pick", "complete"}:
                            self.assertEqual(len(x["why"]), need)
                            self.assertTrue(all(x["why"][i] for i in range(need) if i != x["correct"]))

    def test_replies_are_buildable_and_model_is_accepted(self):
        for d in self.items:
            for x in d["drills"]:
                if x["type"] == "reply":
                    with self.subTest(d["id"]):
                        self.assertIn(x["model"], [" ".join(a) for a in x["accepted"]])
                        for reply in x["accepted"]:
                            bank = list(x["bank"])
                            for tile in reply:
                                self.assertIn(tile, bank)
                                bank.remove(tile)
                        self.assertGreater(len(x["bank"]), max(len(a) for a in x["accepted"]))

    def test_gap_and_error_lines_match_their_drills(self):
        for d in self.items:
            types = {x["type"] for x in d["drills"]}
            gaps = [t for t in d["turns"] if "___" in t["text"]]
            errors = [t for t in d["turns"] if "error" in t]
            with self.subTest(d["id"]):
                self.assertEqual(len(gaps), 1 if "complete" in types else 0)
                self.assertEqual(len(errors), 1 if "fix" in types else 0)
                for t in errors:
                    self.assertEqual(t["speaker"], "learner")
                for t in errors:
                    self.assertIn(norm(t["error"]["word"]), [norm(w) for w in t["text"].split()])
                    self.assertIn(t["error"]["fix"], t["error"]["choices"])

    def test_new_words_are_glossed_and_present(self):
        for d in self.items:
            text = " ".join([t["text"] for t in d["turns"]] + [d.get("followUp", "")]
                            + [a for x in d["drills"] for a in x.get("choices", []) if x["type"] in {"pick", "reply", "complete"}]
                            + [" ".join(x.get("bank", [])) for x in d["drills"]])
            flat = " ".join(norm(w) for w in text.split())
            for word in d["newWords"]:
                with self.subTest(d["id"], word=word):
                    self.assertIn(word, self.glossary)
                    self.assertTrue(re.search(r"(^| )" + re.escape(word) + r"( |$)", flat), word)
            for x in d["drills"]:
                if x["type"] == "word":
                    self.assertIn(x["target"], d["newWords"])

    def test_server_lines_and_follow_ups_have_audio(self):
        for d in self.items:
            keys = [f"pilot2_{d['id']}_t{i}" for i, t in enumerate(d["turns"]) if t["speaker"] == "server"]
            if "followUp" in d:
                keys.append(f"pilot2_{d['id']}_f")
            for key in keys:
                with self.subTest(key):
                    path = AUDIO / f"{key}.mp3"
                    self.assertTrue(path.exists())
                    self.assertGreater(path.stat().st_size, 2000)


    def test_spoken_glosses_are_marked(self):
        for word in ["y a", "du coup", "ouais", "carrément", "t'es", "pas de souci", "top", "ça marche"]:
            with self.subTest(word):
                self.assertTrue(self.glossary[word].startswith("* "))

    def test_learner_lines_avoid_gendered_self_reference(self):
        learner = [t["text"] for d in self.items for t in d["turns"] if t["speaker"] == "learner"]
        learner += [x["model"] for d in self.items for x in d["drills"] if x["type"] == "reply"]
        learner += [x["choices"][x["correct"]] for d in self.items for x in d["drills"] if x["type"] == "pick"]
        for line in learner:
            self.assertNotRegex(line.lower(), r"\b(désolée?|prête?|allée?)\b")


if __name__ == "__main__":
    unittest.main()
