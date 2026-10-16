"""Production Book 3 packaging contracts."""

import json
import unittest
from pathlib import Path

from tools.nuances.package import package_module, validate_course


ROOT = Path(__file__).resolve().parents[2]


class PackageTests(unittest.TestCase):
    def test_module_01_assigns_each_review_card_once_in_authored_order(self):
        cards = json.loads((ROOT / "carambole/Debug/testbook_book3.json").read_text())
        metadata = {
            "number": 1,
            "id": "nu_01",
            "title": "Ce qui s'est passé",
            "goal": "Distinguer le cadre et l'événement.",
            "groups": [
                {"label": f"Étape {i}", "note": "Lire le récit.", "count": n}
                for i, n in enumerate((5, 5, 5, 5, 6), 1)
            ],
        }
        module = package_module(cards, metadata)
        packaged = [card["id"] for group in module["elements"] for card in group["cards"]]
        self.assertEqual(packaged, [card["id"] for card in cards])
        self.assertEqual([group["id"] for group in module["elements"]],
                         [f"nu_01_e{i:02d}" for i in range(1, 6)])

    def test_rejects_a_group_plan_that_drops_a_card(self):
        cards = json.loads((ROOT / "carambole/Debug/testbook_book3.json").read_text())
        metadata = {
            "number": 1, "id": "nu_01", "title": "Ce qui s'est passé", "goal": "Raconter.",
            "groups": [
                {"label": f"Étape {i}", "note": "Lire.", "count": 5}
                for i in range(1, 6)
            ],
        }
        with self.assertRaisesRegex(ValueError, "unassigned"):
            package_module(cards, metadata)

    def test_course_rejects_duplicate_card_ids_across_modules(self):
        card = {
            "id": "b3_01_x", "format": "word", "source": [{"text": "La salle ouvre."}],
            "task": "Choisis.", "response": {"kind": "choices", "choices": ["a", "b", "c"],
                                                  "answer": "a"}, "feedback": "A.",
        }
        module = {"id": "nu_01", "number": 1,
                  "elements": [{"id": "nu_01_e01", "cards": [card]}]}
        with self.assertRaisesRegex(ValueError, "duplicate card"):
            validate_course([module, {"id": "nu_02", "number": 2, "elements": [
                {"id": "nu_02_e01", "cards": [card]}]}], strict_counts=False)


if __name__ == "__main__":
    unittest.main()
