"""Contract tests for production En situation content."""

import copy
import tempfile
import unittest
from pathlib import Path

from tools.situations.lint import global_id_errors, lint_content, rendered_surfaces
from tools.situations.sitbook import item_ranks


def fixture():
    words = {"words": [
        {"fr": "bonjour", "en": "hello", "spoken": False, "audio": "sitw_bonjour", "firstSeen": None},
        {"fr": "oui", "en": "yes", "spoken": False, "audio": "sitw_oui", "firstSeen": None},
        {"fr": "café", "en": "coffee", "spoken": False, "audio": "sitw_cafe", "firstSeen": None},
        {"fr": "comme d'habitude", "en": "as usual", "spoken": False,
         "audio": "sitw_comme_d_habitude", "firstSeen": "sit_06_order_d01"},
    ]}
    items = []
    for number in range(1, 11):
        item = {"id": f"sit_06_order_d{number:02}", "place": "Au café",
                "cue": "Karim, the barista, asks you about coffee.",
                "turns": [{"speaker": "server", "name": "Karim", "text": "Bonjour, café ?"}],
                "drills": [{"type": "comprehend", "prompt": "What is offered?",
                            "choices": ["Coffee", "Tea"], "correct": 0,
                            "miss": "Reread « café »."}],
                "followUp": "Oui, café.", "newWords": []}
        if number == 1:
            item["turns"][0]["text"] = "Bonjour, comme d'habitude ?"
            item["newWords"] = ["comme d'habitude"]
        if number >= 2:
            item["turns"][0]["text"] = "Bonjour, comme d'habitude ?"
        if number % 2 == 0:
            item["drills"] = [{"type": "word", "prompt": "Meaning?",
                                "target": "comme d'habitude", "choices": ["as usual", "hello", "coffee"],
                                "correct": 0, "why": ["", "Not here.", "Not here."]}]
        items.append(item)
        if number % 2 == 0:
            standalone_number = number // 2
            items.append({"id": f"sit_06_order_s{standalone_number:02}",
                          "place": "Au café · phrase seule", "standalone": "Construire",
                          "cue": "Say yes to Karim.", "turns": [],
                          "drills": [{"type": "reply", "prompt": "Say yes.",
                                      "bank": ["Oui,", "café.", "bonjour"],
                                      "accepted": [["Oui,", "café."]], "model": "Oui, café."}],
                          "newWords": []})
    module = {"id": "sit_06", "title": "Au café", "arc": "Le quartier",
              "goal": "Order coffee.", "elements": [{"id": "sit_06_order", "title": "Commander",
               "note": "Order a drink.", "items": items}]}
    return module, words


class SituationLintTests(unittest.TestCase):
    def setUp(self):
        self.module, self.words = fixture()
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.audio = Path(self.temp.name)
        for item in self.module["elements"][0]["items"]:
            for index, turn in enumerate(item["turns"]):
                if turn["speaker"] == "server":
                    (self.audio / f"{item['id']}_t{index}.mp3").write_bytes(b"x" * 2001)
            if "followUp" in item:
                (self.audio / f"{item['id']}_f.mp3").write_bytes(b"x" * 2001)
        for word in self.words["words"]:
            (self.audio / f"{word['audio']}.mp3").write_bytes(b"x" * 2001)

    def errors(self, module=None, words=None, *, draft=False):
        return lint_content(module or self.module, words or self.words, self.audio, draft=draft)

    def assert_bad(self, fragment):
        self.assertIn(fragment, "\n".join(self.errors()))

    def test_valid_module(self):
        self.assertEqual([], self.errors(draft=True))

    def test_card_counts_and_order(self):
        self.module["elements"][0]["items"].pop()
        self.assert_bad("10 dialogues and 5 standalone")

    def test_duplicate_ids_and_wrong_prefix(self):
        items = self.module["elements"][0]["items"]
        items[1]["id"] = items[0]["id"]
        self.assert_bad("duplicate ID")

    def test_dialogue_line_and_drill_bounds(self):
        item = self.module["elements"][0]["items"][0]
        item["turns"][0]["text"] = "Bonjour café café café café café café café café café café"
        item["drills"].append(copy.deepcopy(item["drills"][0]))
        self.assert_bad("over 10 words")
        self.assert_bad("repeated drill type")

    def test_reply_line_counts_toward_dialogue_limit(self):
        items = self.module["elements"][0]["items"]
        item = items[0]
        item["turns"] = [copy.deepcopy(item["turns"][0]) for _ in range(3)]
        item["drills"].append(copy.deepcopy(items[2]["drills"][0]))
        self.assert_bad("over 3 lines with the built reply")

    def test_reply_requires_buildable_accepted_and_model(self):
        drill = self.module["elements"][0]["items"][2]["drills"][0]
        drill["accepted"] = [["Oui,", "thé."]]
        self.assert_bad("cannot be built")
        self.assert_bad("model is not accepted")

    def test_choice_reasons_and_single_gap(self):
        item = self.module["elements"][0]["items"][0]
        item["turns"][0]["text"] = "Bonjour, ___ ___ ?"
        item["drills"] = [{"type": "complete", "prompt": "Fill it.",
                           "choices": ["café", "oui", "bonjour"], "correct": 0,
                           "why": ["", "", "Wrong here."]}]
        self.assert_bad("exactly one gap")
        self.assert_bad("why-line")

    def test_fix_targets_learner_word(self):
        item = self.module["elements"][0]["items"][0]
        item["turns"] = [{"speaker": "learner", "text": "Oui café.",
                          "error": {"word": "thé", "fix": "café", "choices": ["café", "oui", "bonjour"],
                                    "why": "Wrong word."}}]
        item["drills"] = [{"type": "fix", "prompt": "Fix the line."}]
        self.assert_bad("error word not in learner line")

    def test_missing_gloss_and_new_word_recurrence(self):
        self.module["elements"][0]["items"][0]["turns"][0]["text"] += " thé"
        self.assert_bad("missing gloss")
        for item in self.module["elements"][0]["items"][3:]:
            if "standalone" not in item:
                item["turns"][0]["text"] = "Bonjour, café ?"
        self.assert_bad("two later dialogues")

    def test_standalone_cannot_introduce_word(self):
        item = self.module["elements"][0]["items"][2]
        item["newWords"] = ["comme d'habitude"]
        self.assert_bad("standalone introduces")

    def test_spoken_and_texting_abbreviation(self):
        self.words["words"][0]["spoken"] = True
        self.module["elements"][0]["items"][0]["turns"][0]["text"] += " stp"
        self.assert_bad("spoken entry")
        self.assert_bad("texting abbreviation")

    def test_audio_required(self):
        (self.audio / "sit_06_order_d01_f.mp3").unlink()
        self.assert_bad("missing audio")

    def test_word_audio_required(self):
        (self.audio / "sitw_bonjour.mp3").unlink()
        self.assert_bad("sitw_bonjour: missing audio")

    def test_distinct_words_cannot_share_audio_key(self):
        self.words["words"][1]["audio"] = "sitw_bonjour"
        self.assert_bad("duplicate audio key 'sitw_bonjour'")

    def test_other_module_first_seen_is_allowed(self):
        self.words["words"].append({"fr": "merci", "en": "thank you", "spoken": False,
                                    "audio": "sitw_merci", "firstSeen": "sit_07_order_d01"})
        (self.audio / "sitw_merci.mp3").write_bytes(b"x" * 2001)
        self.assertEqual([], self.errors(draft=True))

    def test_draft_allows_incomplete_move(self):
        self.module["elements"][0]["items"] = self.module["elements"][0]["items"][:3]
        errors = lint_content(self.module, self.words, self.audio, draft=True)
        self.assertFalse(any("10 dialogues" in error or "two later dialogues" in error for error in errors))

    def test_standalone_cannot_use_word_taught_later(self):
        item = self.module["elements"][0]["items"][2]
        item["drills"][0]["bank"].append("tard")
        self.words["words"].append({"fr": "tard", "en": "late", "spoken": False,
                                    "audio": "sitw_tard", "firstSeen": "sit_06_order_d05"})
        self.assert_bad("before it is taught")

    def test_rendered_surfaces_include_filled_gap_and_fix(self):
        item = {"turns": [
            {"speaker": "learner", "text": "Je ___ café."},
            {"speaker": "learner", "text": "Je bois café.",
             "error": {"word": "bois", "fix": "veux", "choices": ["veux", "boit", "bois"]}}],
            "drills": [{"type": "complete", "choices": ["veux", "prends", "bois"], "correct": 0},
                       {"type": "reply", "accepted": [["Je", "veux", "un café."]]}]}
        self.assertIn("Je veux café.", rendered_surfaces(item))
        self.assertIn("Je prends café.", rendered_surfaces(item))
        self.assertIn("Je veux café.", rendered_surfaces(item))
        self.assertIn("Je veux un café.", rendered_surfaces(item))

    def test_reinforced_new_word_keeps_original_first_seen(self):
        self.module["elements"][0]["items"][3]["newWords"] = ["comme d'habitude"]
        self.assertEqual([], self.errors(draft=True))

    def test_reinforced_word_from_earlier_module(self):
        self.words["words"][3]["firstSeen"] = "sit_01_intro_d01"
        self.assertEqual([], self.errors(draft=True))

    def test_word_target_must_be_in_visible_turn(self):
        item = self.module["elements"][0]["items"][1]
        item["turns"][0]["text"] = "Bonjour, café ?"
        item["drills"].append({"type": "reply", "prompt": "Say as usual.",
                               "bank": ["comme d'habitude", "oui"],
                               "accepted": [["comme d'habitude"]], "model": "comme d'habitude"})
        self.assert_bad("word target not in visible turn")

    def test_fix_why_is_one_english_line(self):
        item = self.module["elements"][0]["items"][0]
        item["turns"] = [{"speaker": "learner", "text": "Oui café.",
                          "error": {"word": "Oui", "fix": "Bonjour", "choices": ["Bonjour", "Oui", "Café"],
                                    "why": ["Wrong", "Wrong"]}}]
        item["drills"] = [{"type": "fix", "prompt": "Fix the line."}]
        self.assert_bad("why must be one line")

    def test_global_ids_reject_book_one_collision_and_missing_first_seen(self):
        self.words["words"].append({"fr": "merci", "en": "thank you", "spoken": False,
                                    "audio": "sitw_merci", "firstSeen": "sit_07_order_d01"})
        errors = global_id_errors([self.module], self.words, {"sit_06_order_d01"})
        self.assertIn("collides with Book 1", "\n".join(errors))
        self.assertIn("firstSeen 'sit_07_order_d01'", "\n".join(errors))

    def test_standalone_line_uses_eight_to_fourteen_words(self):
        item = self.module["elements"][0]["items"][2]
        item["turns"] = [{"speaker": "server", "text": "Bonjour café ?"}]
        self.assert_bad("standalone line needs 8–14 words")

    def test_new_word_must_be_visible_and_listed_at_first_seen(self):
        first = self.module["elements"][0]["items"][0]
        first["newWords"] = []
        self.assert_bad("firstSeen must be listed in newWords")
        first["newWords"] = ["comme d'habitude"]
        first["turns"][0]["text"] = "Bonjour, café ?"
        self.assert_bad("firstSeen must be visible")

    def test_two_words_can_share_first_seen_item(self):
        self.words["words"].append({"fr": "merci", "en": "thank you", "spoken": False,
                                    "audio": "sitw_merci", "firstSeen": "sit_06_order_d01"})
        (self.audio / "sitw_merci.mp3").write_bytes(b"x" * 2001)
        self.assert_bad("'merci' firstSeen must be listed in newWords")
        self.assert_bad("'merci' firstSeen must be visible")

    def test_new_word_cannot_precede_first_seen(self):
        self.words["words"][3]["firstSeen"] = "sit_06_order_d03"
        self.assert_bad("used before firstSeen")

    def test_recurrence_counts_later_dialogues_across_elements(self):
        source = self.module["elements"][0]
        other = copy.deepcopy(source)
        other["id"] = "sit_06_size"
        for item in other["items"]:
            item["id"] = item["id"].replace("_order_", "_size_")
        for item in source["items"][1:]:
            if "standalone" not in item:
                item["turns"][0]["text"] = "Bonjour, café ?"
        self.module["elements"].append(other)
        errors = lint_content(self.module, self.words, self.audio, check_audio=False, draft=True)
        self.assertNotIn("needs two later dialogues", "\n".join(errors))

    def test_boundary_repeated_type_is_rejected(self):
        items = self.module["elements"][0]["items"]
        items[0]["drills"].append({"type": "reply", "prompt": "Say yes", "bank": ["Oui,"],
                                   "accepted": [["Oui,"]], "model": "Oui,"})
        items[1]["drills"][0]["type"] = "reply"
        self.assert_bad("same drill type back to back")

    def test_word_wrong_choices_need_reasons(self):
        self.module["elements"][0]["items"][1]["drills"][0].pop("why")
        self.assert_bad("word needs a why-line")

    def test_tappable_complete_distractor_and_reply_bank_need_gloss(self):
        item = self.module["elements"][0]["items"][2]
        item["drills"][0]["bank"].append("thé")
        self.assert_bad("missing gloss 'thé'")

    def test_spoken_y_a_encore_allowed(self):
        self.words["words"].append({"fr": "y a encore", "en": "there is still",
                                    "spoken": True, "audio": "sitw_y_a_encore", "firstSeen": None})
        (self.audio / "sitw_y_a_encore.mp3").write_bytes(b"x" * 2001)
        self.assertNotIn("spoken entry 'y a encore'", "\n".join(self.errors()))

    def test_strict_move_checks_spread_clarification_and_social_channel(self):
        errors = "\n".join(self.errors())
        self.assertIn("at least 4 drill types", errors)
        self.assertIn("at least half", errors)
        self.assertIn("all five labels", errors)
        self.assertIn("clarification", errors)
        self.assertIn("other-channel or social", errors)

    def test_masculine_self_guard_catches_arrived(self):
        item = self.module["elements"][0]["items"][2]
        item["drills"][0]["model"] = "Je suis arrivé."
        item["drills"][0]["accepted"] = [["Je suis arrivé."]]
        self.assert_bad("masculine first-person")

    def test_masculine_self_guard_catches_bare_enchante(self):
        item = self.module["elements"][0]["items"][2]
        item["turns"].append({"speaker": "learner", "text": "Bonjour ! Enchanté."})
        self.assert_bad("masculine first-person")

    def test_feminine_self_forms_pass(self):
        from tools.situations.lint import MASC_SELF
        for line in ("Je suis arrivée.", "Bonjour ! Enchantée.", "Désolée, je suis en retard.",
                     "Il est content.", "Je suis prête !"):
            self.assertIsNone(MASC_SELF.search(line), line)


    # Book-wide word order across modules.

    def renumber(self, number):
        """Return a copy of the fixture module as module `number`."""
        module = copy.deepcopy(self.module)
        module["id"] = f"sit_{number:02}"
        for element in module["elements"]:
            element["id"] = element["id"].replace("sit_06", module["id"])
            for item in element["items"]:
                item["id"] = item["id"].replace("sit_06", module["id"])
        return module

    def test_earlier_module_cannot_use_word_taught_in_later_module(self):
        later = self.renumber(5)
        self.words["words"][3]["firstSeen"] = "sit_05_order_d01"
        module_03 = self.renumber(3)
        ranks = item_ranks([module_03, later])
        errors = "\n".join(lint_content(module_03, self.words, self.audio, draft=True,
                                         check_audio=False, book_ranks=ranks))
        self.assertIn("sit_03_order_d01: 'comme d'habitude' used before firstSeen 'sit_05_order_d01'", errors)
        # Without ranks the module number alone orders it.
        errors = "\n".join(lint_content(module_03, self.words, self.audio, draft=True, check_audio=False))
        self.assertIn("used before firstSeen 'sit_05_order_d01'", errors)

    def test_later_module_may_use_and_relist_earlier_word(self):
        self.words["words"][3]["firstSeen"] = "sit_01_order_d01"
        earlier = self.renumber(1)
        ranks = item_ranks([earlier, self.module])
        self.assertEqual([], lint_content(self.module, self.words, self.audio, draft=True,
                                          book_ranks=ranks))

    def test_standalone_cannot_use_word_from_later_module(self):
        self.module["elements"][0]["items"][2]["drills"][0]["bank"].append("tard")
        self.words["words"].append({"fr": "tard", "en": "late", "spoken": False,
                                    "audio": "sitw_tard", "firstSeen": "sit_09_order_d01"})
        errors = "\n".join(lint_content(self.module, self.words, self.audio, draft=True, check_audio=False))
        self.assertIn("sit_06_order_s01: standalone uses 'tard' before it is taught", errors)

    def test_recurrence_gate_only_in_teaching_module(self):
        self.words["words"][3]["firstSeen"] = "sit_02_order_d01"
        for item in self.module["elements"][0]["items"][1:]:
            if "standalone" not in item:
                item["turns"][0]["text"] = "Bonjour, café ?"
        errors = "\n".join(lint_content(self.module, self.words, self.audio, check_audio=False))
        self.assertNotIn("needs two later dialogues", errors)
        self.assertNotIn("needs later Mot", errors)

    def test_book_ranks_order_items_within_same_module_by_element(self):
        source = self.module["elements"][0]
        other = copy.deepcopy(source)
        other["id"] = "sit_06_size"
        for item in other["items"]:
            item["id"] = item["id"].replace("_order_", "_size_")
        self.module["elements"].insert(0, other)
        # Taught in the second element: the whole first element is earlier.
        errors = "\n".join(self.errors(draft=True))
        self.assertIn("sit_06_size_d01: 'comme d'habitude' used before firstSeen 'sit_06_order_d01'", errors)

    def test_stale_ranks_for_linted_module_are_ignored(self):
        stale = {"sit_06_order_d01": (6, 9, 9)}
        self.assertEqual([], lint_content(self.module, self.words, self.audio, draft=True,
                                          book_ranks=stale))

    def test_module_id_range(self):
        for good in ("sit_01", "sit_25"):
            module = self.renumber(int(good[-2:]))
            self.assertNotIn("bad ID", "\n".join(lint_content(module, self.words, self.audio,
                                                              draft=True, check_audio=False)))
        module = self.renumber(26)
        self.assertIn("module: bad ID 'sit_26'",
                      "\n".join(lint_content(module, self.words, self.audio, draft=True, check_audio=False)))

    def test_cast_alias_and_voice_field(self):
        turn = self.module["elements"][0]["items"][0]["turns"][0]
        turn["name"] = "Monsieur Ferrand"
        self.assert_bad("use canonical cast name 'M. Ferrand'")
        turn["name"] = "Karim"
        turn["voice"] = "female"
        self.assert_bad("voice is only 'male' or 'female' on an unnamed server turn")
        del turn["name"]
        self.assertNotIn("voice is only", "\n".join(self.errors(draft=True)))

    def test_other_channel_uses_module_home_place(self):
        for item in self.module["elements"][0]["items"]:
            if "standalone" not in item:
                item["place"] = "Sur le palier"
        self.assert_bad("other-channel or social")
        self.module["elements"][0]["items"][0]["place"] = "Texto · Léa"
        self.module["elements"][0]["items"][1]["place"] = "Messagerie"
        self.assertNotIn("other-channel or social", "\n".join(self.errors()))


if __name__ == "__main__":
    unittest.main()
