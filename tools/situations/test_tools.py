"""Focused adapter checks for the production-to-pilot review path."""

import json
import tempfile
import unittest
from pathlib import Path

from tools.situations.assemble import assemble, draft_files, merge_words
from tools.situations.generate_audio import FEMALE, MALE, PILOT, item_clips, production_clips
from tools.situations.sitbook import load_manifest_modules
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


    def test_production_audio_filters_one_module_and_its_words(self):
        def module(number):
            return {"id": f"sit_{number:02}", "elements": [{"items": [
                {"id": f"sit_{number:02}_order_d01", "turns": [
                    {"speaker": "server", "text": "Bonjour !"}], "followUp": "Voilà."}]}]}
        words = {"words": [
            {"fr": "a", "audio": "sitw_a", "firstSeen": None},
            {"fr": "b", "audio": "sitw_b", "firstSeen": "sit_03_order_d01"},
            {"fr": "c", "audio": "sitw_c", "firstSeen": "sit_06_order_d01"}]}
        everything = [key for key, _, _ in production_clips([module(3), module(6)], words)]
        self.assertEqual(everything, ["sit_03_order_d01_t0", "sit_03_order_d01_f",
                                      "sit_06_order_d01_t0", "sit_06_order_d01_f",
                                      "sitw_a", "sitw_b", "sitw_c"])
        only = [key for key, _, _ in production_clips([module(3), module(6)], words, 6)]
        self.assertEqual(only, ["sit_06_order_d01_t0", "sit_06_order_d01_f", "sitw_c"])

    def test_gap_line_is_voiced_with_its_answer(self):
        item = {"id": "sit_01_bye_s05",
                "turns": [{"speaker": "server", "text": "Je suis là ce soir. ___ !"}],
                "drills": [{"type": "complete", "choices": ["Au revoir", "À tout à l'heure"], "correct": 1}]}
        self.assertEqual(item_clips(item)[0][1], "Je suis là ce soir. À tout à l'heure !")
        item["drills"] = []
        with self.assertRaisesRegex(ValueError, "gap line"):
            item_clips(item)

    def test_no_shipped_clip_text_has_a_gap(self):
        """HARD RULE: clips are complete lines, never « … » or ___ for the answer."""
        modules = load_manifest_modules()
        pilot = json.loads(PILOT.read_text(encoding="utf-8"))["dialogues"]
        items = [it for m in modules for e in m["elements"] for it in e["items"]] + pilot
        gaps = [it["id"] for it in items
                if any("___" in t["text"] for t in it["turns"] if t["speaker"] == "server")]
        self.assertTrue(gaps)
        for item in items:
            for key, text, _ in item_clips(item):
                self.assertNotIn("___", text, key)
                raw = [t["text"] for t in item["turns"]] + [item.get("followUp") or ""]
                if "…" in text:
                    self.assertTrue(any("…" in r for r in raw), f"{key}: « … » not in the authored line")

    def test_cast_and_anonymous_female_voices(self):
        item = {"id": "sit_12_leak_d01", "turns": [
            {"speaker": "server", "name": "Mme Dumas", "text": "Bonjour."},
            {"speaker": "server", "voice": "female", "text": "Oui ?"}],
            "followUp": "Merci."}
        voices = [voice for _, _, voice in item_clips(item)]
        self.assertEqual(voices, ["fr-FR-Chirp3-HD-Gacrux", FEMALE, "fr-FR-Chirp3-HD-Gacrux"])
        item["turns"] = [{"speaker": "server", "voice": "female", "text": "Oui ?"}]
        self.assertEqual([v for _, _, v in item_clips(item)], [FEMALE, FEMALE])
        item["turns"] = [{"speaker": "server", "name": "Pharmacien", "text": "Oui ?"}]
        self.assertEqual([v for _, _, v in item_clips(item)], [MALE, MALE])
        item["followUpBy"] = "M. Ferrand"
        self.assertEqual(item_clips(item)[-1][2], "fr-FR-Chirp3-HD-Orus")

    def test_thank_you_line_uses_selected_studio_voice(self):
        item = {"id": "sit_04_thank_d03", "turns": [
            {"speaker": "server", "name": "Léa", "text": "C'était top, hier ! À refaire !"},
            {"speaker": "server", "name": "Léa", "text": "À bientôt !"}]}
        voices = [voice for _, _, voice in item_clips(item)]
        self.assertEqual(voices, ["fr-FR-Studio-A", "fr-FR-Chirp3-HD-Aoede"])

    def test_export_takes_items_from_several_modules(self):
        other = {"elements": [{"id": "sit_01_hello", "title": "Saluer", "items": self.items[3:]}]}
        first = {"elements": [{"id": "sit_06_order", "title": "Commander", "items": self.items[:3]}]}
        result = export([other, first], self.words, [item["id"] for item in self.items])
        self.assertEqual([d["element"] for d in result["dialogues"]][2:4], ["Commander", "Saluer"])


def word(fr, first, en="x", audio=None):
    return {"fr": fr, "en": en, "spoken": False, "audio": audio or f"sitw_{fr}", "firstSeen": first}


def element(module_id, move, count=2):
    return {"id": f"{module_id}_{move}", "title": move, "note": "n",
            "items": [{"id": f"{module_id}_{move}_d{n:02}"} for n in range(1, count + 1)]}


class AssembleTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        self.drafts, self.out = root / "drafts", root / "out"
        self.drafts.mkdir()
        self.out.mkdir()
        self.config = root / "modules.json"
        self.config.write_text(json.dumps({"modules": [
            {"id": "sit_03", "title": "Tu ou vous ?", "arc": "Arriver à Lyon", "goal": "g3",
             "file": "03_tu_ou_vous.json", "moves": ["greet", "repeat"]},
            {"id": "sit_06", "title": "Au café", "arc": "Le quartier", "goal": "g6",
             "file": "06_au_cafe.json", "moves": ["order", "pay"]}]}), encoding="utf-8")
        (self.out / "situations_manifest.json").write_text(json.dumps(
            {"book": "fr_en_situation", "moduleFiles": ["06_au_cafe.json"]}), encoding="utf-8")
        self.draft("06_cafe_first_half", [element("sit_06", "pay")],
                   [word("merci", "sit_06_pay_d01"), word("café", None)])
        self.draft("06_cafe_second_half", [element("sit_06", "order")],
                   [word("merci", "sit_06_pay_d02"), word("bonjour", "sit_06_order_d02")])

    def draft(self, stem, elements, words):
        (self.drafts / f"{stem}.json").write_text(json.dumps({"elements": elements}), encoding="utf-8")
        (self.drafts / f"{stem}_words.json").write_text(json.dumps({"words": words}), encoding="utf-8")

    def run_assemble(self, numbers=None):
        return assemble(numbers, drafts=self.drafts, config_path=self.config, situations=self.out)

    def test_module_follows_config_move_order(self):
        written, words, files = self.run_assemble()
        module = written["06_au_cafe.json"]
        self.assertEqual(list(module), ["id", "title", "arc", "goal", "elements"])
        self.assertEqual([e["id"] for e in module["elements"]], ["sit_06_order", "sit_06_pay"])
        self.assertEqual(files, ["06_au_cafe.json"])
        self.assertEqual([w["fr"] for w in words["words"]], ["bonjour", "café", "merci"])

    def test_earliest_first_seen_wins_by_book_order(self):
        # order is the first move, so sit_06_order_d02 precedes sit_06_pay_d01.
        self.draft("06_cafe_second_half", [element("sit_06", "order")],
                   [word("merci", "sit_06_order_d02")])
        _, words, _ = self.run_assemble()
        self.assertEqual({w["fr"]: w["firstSeen"] for w in words["words"]}["merci"], "sit_06_order_d02")

    def test_earlier_module_wins_and_manifest_stays_numeric(self):
        self.draft("03_tu_vous_a", [element("sit_03", "greet"), element("sit_03", "repeat")],
                   [word("café", "sit_03_repeat_d02"), word("merci", "sit_03_greet_d01")])
        written, words, files = self.run_assemble(["03"])
        self.assertEqual(list(written), ["03_tu_ou_vous.json"])
        self.assertEqual(files, ["03_tu_ou_vous.json", "06_au_cafe.json"])
        first = {w["fr"]: w["firstSeen"] for w in words["words"]}
        self.assertEqual(first["merci"], "sit_03_greet_d01")
        self.assertEqual(first["café"], "sit_03_repeat_d02")  # taught beats base null

    def test_base_word_stays_null_when_nobody_teaches_it(self):
        _, words, _ = self.run_assemble()
        self.assertIsNone({w["fr"]: w["firstSeen"] for w in words["words"]}["café"])

    def test_conflicting_gloss_fails_with_both_entries(self):
        self.draft("06_cafe_second_half", [element("sit_06", "order")],
                   [word("merci", "sit_06_order_d01", en="thanks a lot")])
        with self.assertRaises(ValueError) as caught:
            self.run_assemble()
        self.assertIn('"en": "x"', str(caught.exception))
        self.assertIn('"en": "thanks a lot"', str(caught.exception))

    def test_unknown_first_seen_fails(self):
        self.draft("06_cafe_second_half", [element("sit_06", "order")],
                   [word("merci", "sit_07_order_d01")])
        with self.assertRaisesRegex(ValueError, "not an assembled item ID"):
            self.run_assemble()

    def test_missing_move_and_missing_words_draft_fail(self):
        (self.drafts / "06_cafe_second_half.json").write_text(json.dumps({"elements": []}))
        with self.assertRaisesRegex(ValueError, "exactly the unique moves"):
            self.run_assemble()
        (self.drafts / "06_cafe_second_half_words.json").unlink()
        with self.assertRaisesRegex(ValueError, "missing 06_cafe_second_half_words.json"):
            draft_files(self.drafts)

    def test_manifest_module_without_drafts_fails(self):
        (self.out / "situations_manifest.json").write_text(json.dumps(
            {"book": "fr_en_situation", "moduleFiles": ["03_tu_ou_vous.json", "06_au_cafe.json"]}))
        with self.assertRaisesRegex(ValueError, "would be dropped"):
            self.run_assemble(["06"])

    def test_merge_words_rank_order(self):
        ranks = {"sit_02_a_d01": (2, 0, 0), "sit_01_b_d05": (1, 0, 4)}
        merged = merge_words([word("x", None), word("x", "sit_02_a_d01"), word("x", "sit_01_b_d05")], ranks)
        self.assertEqual(merged["words"][0]["firstSeen"], "sit_01_b_d05")


if __name__ == "__main__":
    unittest.main()
