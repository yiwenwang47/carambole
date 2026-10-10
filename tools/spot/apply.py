#!/usr/bin/env python3
"""Write judged spot-the-error items into the topic JSON (as each example's `spot`).

Inputs: the candidates dir from tools/spot/candidates.py and the judges' verdict
files (list of {exampleId, accept, reason, options?, explanation?, explanationEN?}).
Only accepted items are written. Gates, re-run here whatever the judge said:

  - options[0] is still the candidate's correct word (a judge may only replace
    the WRONG options);
  - every wrong option, put in the slot, is flagged by Grammalecte. An option it
    does not flag is held back and printed for a human; pass its example id in
    --allow (comma-separated) once you have read it and agree it is wrong.

Touches only the `spot` key (style-preserving serializer, diff = new lines).
Re-running replaces earlier `spot` data for the examples it writes.

Usage: python3 tools/spot/apply.py CANDIDATES_DIR VERDICT.json [VERDICT.json ...]
       [--allow id1,id2] [--dry-run]
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(TOOLS, 'swaps'))
sys.path.insert(0, os.path.join(TOOLS, 'distractors'))

import swaps as S  # noqa: E402
from apply import dumps_cb  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('candidates')
    ap.add_argument('verdicts', nargs='+')
    ap.add_argument('--allow', default='')
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()
    allow = {a for a in args.allow.split(',') if a}

    cands = {c['exampleId']: c for f in glob.glob(os.path.join(args.candidates, '*.json'))
             for c in json.load(open(f))}
    verdicts = [v for f in args.verdicts for v in json.load(open(f))]
    checker = S.Checker()

    accepted: dict[str, dict] = {}
    held: list[str] = []
    for v in verdicts:
        if not v.get('accept'):
            continue
        c = cands[v['exampleId']]
        options = v.get('options') or c['options']
        if options[0] != c['correctToken']:
            held.append(f"{c['exampleId']}: judge changed the correct option to {options[0]!r}")
            continue
        unflagged = []
        for w in options[1:]:
            toks = list(c['tokens'])
            toks[c['wrongIndex']] = w
            grammar, _ = checker.flags(S.render(toks))
            if not grammar:
                unflagged.append(f'« {S.render(toks)} »')
        if unflagged and c['exampleId'] not in allow:
            held.append(f"{c['exampleId']}: wrong option not flagged: {'; '.join(unflagged)}")
            continue
        spot = {'tokens': c['tokens'], 'wrongIndex': c['wrongIndex'], 'options': options}
        if c['locked']:
            spot['locked'] = c['locked']
        if v.get('explanation'):
            spot['explanation'] = v['explanation']
            spot['explanationEN'] = v.get('explanationEN') or v['explanation']
        accepted[c['exampleId']] = spot

    written = 0
    for path in sorted(glob.glob(os.path.join(S.TOPICS, '[0-9]*.json'))):
        module = json.load(open(path))
        changed = False
        for el in module['elements']:
            for ex in el['examples']:
                if ex['id'] in accepted:
                    ex['spot'] = accepted[ex['id']]
                    changed = True
                    written += 1
        if changed and not args.dry_run:
            open(path, 'w').write(dumps_cb(module) + '\n')

    for h in held:
        print('HELD', h)
    print(f'{written} spot items written{" (dry run)" if args.dry_run else ""}; {len(held)} held')
    return 0


if __name__ == '__main__':
    sys.exit(main())
