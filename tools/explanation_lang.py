#!/usr/bin/env python3
"""Find drills whose FRENCH `explanation` field is written in English.

Every example carries `explanation` (French, shown first, ink) and
`explanationEN` (English, shown beneath in grey) — see DrillMissExplanation in
carambole/Features/Drill/MagnetBoard.swift and DrillView.reviewResultBlock.
Many modules were authored with English in both fields. This is a heuristic:
it counts common English vs French function words OUTSIDE quoted French
(« … », "…", '…') and flags a line with English words and no French ones
(`english`), more English than French (`mostly-english`), or both with >=2
English words (`mixed`). Formula-only lines ("elle + habit- + -ait") pass.

Usage: python3 tools/explanation_lang.py            # summary per module, exit 1 if any
       python3 tools/explanation_lang.py --list     # one line per flagged drill
       python3 tools/explanation_lang.py --json F   # full records to F
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sys
from collections import Counter, defaultdict

TOPICS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                      'carambole', 'Resources', 'Topics')
EN = set(('the is are with use you uses it its this that and of for to an in on before after '
          'takes take be becomes when not no only one so because means verb ending form same '
          'here there they we he she has have was were by from as into stays keeps drops needs').split())
FR = set(("le la les est sont avec on un une des du de devant après avant pour et que qui ne pas "
          "se devient prend il elle nous vous ils elles au aux en car donc reste garde comme mais").split())


def category(text: str) -> str | None:
    bare = re.sub(r"«[^»]*»|\"[^\"]*\"|'[^' ]+'|'[^']*'", '', text.lower())
    words = re.findall(r'[a-zàâçéèêëîïôûùüÿœ]+', bare)
    en = sum(w in EN for w in words)
    fr = sum(w in FR for w in words)
    if en >= 1 and fr == 0:
        return 'english'
    if en > fr:
        return 'mostly-english'
    if en >= 2 and fr >= 1:
        return 'mixed'
    return None


def flagged() -> list[dict]:
    out = []
    for path in sorted(glob.glob(os.path.join(TOPICS, '[0-9]*.json'))):
        for el in json.load(open(path))['elements']:
            for ex in el['examples']:
                c = category(ex['explanation'])
                if c:
                    out.append({'module': os.path.basename(path), 'id': ex['id'], 'category': c,
                                'explanation': ex['explanation'],
                                'explanationEN': ex.get('explanationEN')})
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--json')
    args = ap.parse_args()
    rows = flagged()
    if args.json:
        json.dump(rows, open(args.json, 'w'), ensure_ascii=False, indent=1)
    if args.list:
        for r in rows:
            print(f"{r['id']} [{r['category']}] {r['explanation']}")
    per: dict[str, Counter] = defaultdict(Counter)
    for r in rows:
        per[r['module']][r['category']] += 1
    for m in sorted(per):
        print(f'{m:28} {sum(per[m].values()):4}  {dict(per[m])}')
    print(f'{len(rows)} French explanations flagged as English')
    return 1 if rows else 0


if __name__ == '__main__':
    sys.exit(main())
