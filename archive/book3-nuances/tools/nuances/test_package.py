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
        first = json.loads((ROOT / "carambole/Resources/Nuances/nuances_01.json").read_text())
        second = json.loads((ROOT / "carambole/Resources/Nuances/nuances_02.json").read_text())
        second["elements"][0]["cards"][0]["id"] = first["elements"][0]["cards"][0]["id"]
        with self.assertRaisesRegex(ValueError, "duplicate card"):
            validate_course([first, second], strict_counts=False)

    def test_group_needs_two_formats_for_mastery_to_be_reachable(self):
        cards = json.loads((ROOT / "carambole/Debug/testbook_book3.json").read_text())
        metadata = {
            "number": 1, "id": "nu_01", "title": "Ce qui s'est passé", "goal": "Raconter.",
            "groups": [{"label": f"Étape {i}", "note": "Lire.", "count": n}
                       for i, n in enumerate((5, 5, 5, 5, 6), 1)],
        }
        module = package_module(cards, metadata)
        for card in module["elements"][0]["cards"]:
            card["format"] = "word"
            for line in card["source"]:
                line.pop("speaker", None)
        with self.assertRaisesRegex(ValueError, "two formats"):
            validate_course([module], strict_counts=False)


if __name__ == "__main__":
    unittest.main()
