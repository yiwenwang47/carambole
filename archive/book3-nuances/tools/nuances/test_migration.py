"""Book 3 SQLite migration contract against a populated version 5 database."""

import re
import sqlite3
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANAGER = ROOT / "carambole/Models/CoreDataManager.swift"


class NuanceMigrationTests(unittest.TestCase):
    def test_version_6_adds_card_log_without_changing_existing_progress(self):
        db = sqlite3.connect(":memory:")
        db.executescript("""
            CREATE TABLE review_status (
                element_id TEXT PRIMARY KEY, learning_state TEXT, stability REAL
            );
            INSERT INTO review_status VALUES ('sit_07_ticket', 'review', 12.5);
            CREATE TABLE situation_item_log (
                item_id TEXT PRIMARY KEY, element_id TEXT NOT NULL,
                last_done REAL NOT NULL, times INTEGER NOT NULL,
                last_rating INTEGER NOT NULL
            );
            INSERT INTO situation_item_log VALUES
                ('sit_07_ticket_d1', 'sit_07_ticket', 1234.5, 3, 2);
            PRAGMA user_version = 5;
        """)

        source = MANAGER.read_text()
        match = re.search(r"// v6\b(?P<block>.*?)\n\s*}\n\s*}\n", source, re.S)
        self.assertIsNotNone(match, "version 6 migration is missing")
        block = match.group("block")
        create = re.search(
            r'sqlite3_exec\(db, """\s*(CREATE TABLE IF NOT EXISTS nuance_card_log.*?)"""',
            block, re.S,
        )
        self.assertIsNotNone(create, "version 6 must create nuance_card_log")
        db.executescript(create.group(1))

        columns = [(row[1], row[2], row[5]) for row in
                   db.execute("PRAGMA table_info(nuance_card_log)")]
        self.assertEqual(columns, [
            ("card_id", "TEXT", 1), ("element_id", "TEXT", 0),
            ("last_done", "REAL", 0), ("times", "INTEGER", 0),
            ("last_rating", "INTEGER", 0),
        ])
        self.assertEqual(
            db.execute("SELECT * FROM review_status").fetchall(),
            [("sit_07_ticket", "review", 12.5)],
        )
        self.assertEqual(
            db.execute("SELECT * FROM situation_item_log").fetchall(),
            [("sit_07_ticket_d1", "sit_07_ticket", 1234.5, 3, 2)],
        )
        self.assertIn("setUserVersion(6)", block)

    def test_clear_history_removes_only_the_requested_element(self):
        db = sqlite3.connect(":memory:")
        db.executescript("""
            CREATE TABLE nuance_card_log (
                card_id TEXT PRIMARY KEY, element_id TEXT NOT NULL,
                last_done REAL NOT NULL, times INTEGER NOT NULL,
                last_rating INTEGER NOT NULL
            );
            INSERT INTO nuance_card_log VALUES
                ('nu_01_c1', 'nu_01_e01', 100.0, 2, 3),
                ('nu_01_c2', 'nu_01_e01', 200.0, 1, 1),
                ('nu_01_c3', 'nu_01_e02', 300.0, 4, 2);
        """)
        source = MANAGER.read_text()
        method = re.search(
            r'func clearNuanceCardHistory\(elementID: String\).*?\n    }', source, re.S
        )
        self.assertIsNotNone(method, "clearNuanceCardHistory is missing")
        delete = re.search(r'"(DELETE FROM nuance_card_log WHERE element_id = \?;)"',
                           method.group())
        self.assertIsNotNone(delete, "clear must delete by element ID")
        db.execute(delete.group(1), ("nu_01_e01",))
        self.assertEqual(
            db.execute("SELECT card_id, element_id, times FROM nuance_card_log").fetchall(),
            [("nu_01_c3", "nu_01_e02", 4)],
        )


if __name__ == "__main__":
    unittest.main()
