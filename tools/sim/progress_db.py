#!/usr/bin/env python3
"""Fill a sim app's progress store with N maîtrisé + M en cours elements of one book.

The app must have created its store first (open a book once). Existing
review_status / review_log / mastery_log rows are replaced.

    D=$(xcrun simctl get_app_container <sim> <bundle> data)/Documents
    xcrun simctl terminate <sim> <bundle>
    python3 tools/sim/progress_db.py $D/carambole.sqlite situations 3 16   # 2 %, like the user's phone
    python3 tools/sim/progress_db.py $D/carambole.sqlite topics 150 40
"""

import glob
import json
import sqlite3
import sys
import time
from pathlib import Path

DAY = 86400
RESOURCES = Path(__file__).resolve().parents[2] / "carambole" / "Resources"


def element_ids(book: str) -> list[str]:
    if book == "situations":
        files = sorted(glob.glob(str(RESOURCES / "Situations" / "[0-9]*.json")))
        return [e["id"] for f in files for e in json.load(open(f))["elements"]]
    files = json.load(open(RESOURCES / "Topics" / "manifest.json"))["moduleFiles"]
    return [e["id"] for f in files for e in json.load(open(RESOURCES / "Topics" / f))["elements"]]


def main(db: str, book: str, mastered: int, in_progress: int) -> None:
    ids = element_ids(book)[: mastered + in_progress]
    now = time.time()
    con = sqlite3.connect(db)
    for table in ("review_status", "review_log", "mastery_log"):
        con.execute(f"DELETE FROM {table}")
    for i, element in enumerate(ids):
        grad = i < mastered
        first = now - (30 if grad else 5) * DAY
        con.execute(
            "INSERT INTO review_status (element_id, learning_state, last_review_date, next_review_date,"
            " interval_days, first_seen_date, suspended, distinct_correct, mastered_example_ids,"
            " stability, difficulty, graduated_date) VALUES (?,?,?,?,?,?,0,3,'[]',?,5.0,?)",
            (element, "learned" if grad else "learning", now - 2 * DAY, now + (20 if grad else 2) * DAY,
             21 if grad else 2, first, 25.0 if grad else 3.0, now - 3 * DAY if grad else None),
        )
        con.execute("INSERT OR IGNORE INTO review_log VALUES (?,?)", (element, first - first % DAY))
        if grad:
            con.execute("INSERT OR IGNORE INTO mastery_log VALUES (?,?)", (element, now - 3 * DAY))
    con.commit()
    print(f"{len(ids)} seen, {mastered} maîtrisé")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]))
