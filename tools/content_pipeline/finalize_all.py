"""Finalize generated raw exercises into validated staging topics.

Usage: python3 content_pipeline/finalize_all.py [--raw DIR] [--out DIR]
"""
from __future__ import annotations

import argparse

from content_pipeline.finalize import finalize_files


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default="content_pipeline/out/raw")
    ap.add_argument("--out", default="content_pipeline/out/staging")
    args = ap.parse_args()

    r = finalize_files(args.raw, args.out)
    print(
        f"raw {r['raw']} | accepted {r['accepted']} | "
        f"rejected {r['rejected']} | topics {r['topics']}"
    )
    for rej in r["rejections"]:
        print(f"  rejected {rej['id']}: {rej['errors'][0]}")
    print(f"wrote {args.out} ({', '.join(r['manifest']['topicFiles'])})")


if __name__ == "__main__":
    main()
