#!/usr/bin/env python3
"""Audit every registered production book's bundled speech before release.

Add each future book to audio_books.json with either its situation manifest or
an index of {key, text, voice} clips. A missing clip or unresolved finding
blocks the release build.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from audio_audit import audit, expected_clips, load_reviews, render_html


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REGISTRY = Path(__file__).with_name("audio_books.json")


def path_from_repo(value: str) -> Path:
    path = Path(value)
    return path if path.is_absolute() else ROOT / path


def indexed_clips(path: Path) -> list[tuple[str, str, str]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    rows = [(entry["key"], entry["text"], entry.get("voice", "")) for entry in data]
    if not rows or len({key for key, _, _ in rows}) != len(rows):
        raise ValueError(f"{path}: audio index must be nonempty with unique keys")
    return rows


def check_registry(registry: Path, jobs: int) -> bool:
    books = json.loads(registry.read_text(encoding="utf-8"))["books"]
    if not books or len({book["id"] for book in books}) != len(books):
        raise ValueError("audio books registry must contain unique production book IDs")
    passed = True
    for book in books:
        if ("situations" in book) == ("index" in book):
            raise ValueError(f"{book['id']}: set exactly one of situations or index")
        rows = (expected_clips(path_from_repo(book["situations"])) if "situations" in book
                else indexed_clips(path_from_repo(book["index"])))
        if not rows:
            raise ValueError(f"{book['id']}: audio index is empty")
        audio_dir = path_from_repo(book["audio_dir"])
        reviews = load_reviews(path_from_repo(book["reviews"])) if "reviews" in book else {}
        result = audit(rows, audio_dir, jobs, reviews)
        report = path_from_repo(book["report"])
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        report.with_suffix(".html").write_text(render_html(result, report), encoding="utf-8")
        print(f"{book['id']}: {result['total_clips']} clips, {result['flagged_clips']} unresolved; {report}",
              flush=True)
        passed &= result["flagged_clips"] == 0
    return passed


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--jobs", type=int, default=8)
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    raise SystemExit(0 if check_registry(args.registry, args.jobs) else 1)


if __name__ == "__main__":
    main()
