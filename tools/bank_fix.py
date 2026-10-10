#!/usr/bin/env python3
"""Apply bank_lint judgments: fix banks with a second correct answer, record verdicts.

  fixes     {exampleId: {"remove": [distractor, ...], "add": [replacement, ...]}}
            each removed distractor is replaced IN PLACE by its replacement;
            only `tokenBank` changes (style-preserving serializer).
  verdicts  {exampleId: {"<swapped sentence>": "wrong: …" | "also-correct: …"}}
            "wrong" verdicts merge into tools/bank_lint_reviewed.json; "also-correct"
            ones are dropped (the fix removes that swap from the content).

Then re-run tools/bank_lint.py: a replacement that itself leaves the sentence
clean shows up as a new unreviewed swap.

Usage: python3 tools/bank_fix.py --fixes F.json [F.json ...] --verdicts V.json [V.json ...] [--dry-run]
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, 'distractors'))
sys.path.insert(0, os.path.join(HERE, 'swaps'))

import swaps as S  # noqa: E402
from apply import dumps_cb  # noqa: E402

REVIEWED = os.path.join(HERE, 'bank_lint_reviewed.json')


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--fixes', nargs='*', default=[])
    ap.add_argument('--verdicts', nargs='*', default=[])
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    fixes: dict[str, dict] = {}
    for f in args.fixes:
        fixes.update(json.load(open(f)))
    problems: list[str] = []
    fixed = 0
    for path in sorted(glob.glob(os.path.join(S.TOPICS, '[0-9]*.json'))):
        module = json.load(open(path))
        changed = False
        for el in module['elements']:
            for ex in el['examples']:
                fx = fixes.get(ex['id'])
                if not fx:
                    continue
                bank = list(ex['tokenBank'])
                if len(fx['remove']) != len(fx['add']):
                    problems.append(f"{ex['id']}: remove/add counts differ")
                    continue
                ok = True
                for old, new in zip(fx['remove'], fx['add']):
                    if old in ex['answerTokens'] or old not in bank:
                        problems.append(f"{ex['id']}: can't remove {old!r}")
                        ok = False
                    elif new in bank or new in ex['answerTokens']:
                        problems.append(f"{ex['id']}: replacement {new!r} already present")
                        ok = False
                    else:
                        bank[bank.index(old)] = new
                if not ok:
                    continue
                if Counter(ex['answerTokens']) - Counter(bank):
                    problems.append(f"{ex['id']}: bank lost an answer token")
                    continue
                ex['tokenBank'] = bank
                changed = True
                fixed += 1
        if changed and not args.dry_run:
            open(path, 'w').write(dumps_cb(module) + '\n')

    reviewed = json.load(open(REVIEWED)) if os.path.exists(REVIEWED) else {}
    kept = 0
    for f in args.verdicts:
        for eid, m in json.load(open(f)).items():
            for sent, verdict in m.items():
                if verdict.startswith('wrong'):
                    reviewed.setdefault(eid, {})[sent] = verdict
                    kept += 1
    if not args.dry_run and args.verdicts:
        ordered = {k: dict(sorted(v.items())) for k, v in sorted(reviewed.items())}
        json.dump(ordered, open(REVIEWED, 'w'), ensure_ascii=False, indent=1)
        open(REVIEWED, 'a').write('\n')

    for p in problems:
        print('PROBLEM', p)
    print(f'{fixed} banks fixed; {kept} "wrong" verdicts recorded; {len(problems)} problems')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
