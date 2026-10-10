#!/usr/bin/env python3
"""Bank lint: no distractor may be a second correct answer.

Found 2026-10-10: `el_etre_negation_04` ("We are not friends.") offered both
`amis` and `amies`; `el_negation_personnes_03` ("They are not here.") both `là`
and `ici`. Both linters passed — each sentence on its own is fine French.

Method: put every distractor into its slot (tools/swaps). A swap Grammalecte
flags, or that breaks elision/contraction, is a real wrong answer. A swap that
stays CLEAN may be a second correct answer, so it needs a reviewed verdict in
tools/bank_lint_reviewed.json:

    {"<example id>": {"<sentence after the swap>": "<verdict>"}}

  verdict "wrong: <why>"         the prompt rules it out (meaning, gender, …)
  verdict "also-correct: <why>"  a real bug — fix the bank, then drop the entry

Exit 1 while any clean swap is unreviewed or any verdict is "also-correct".

Run:  python3 tools/bank_lint.py                    # lint (~1 min, all cores)
      python3 tools/bank_lint.py --export out.json  # unreviewed swaps + context, for judges
      python3 tools/bank_lint.py --prune            # drop reviewed entries content no longer has
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from multiprocessing import Pool

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, 'swaps'))

import swaps as S  # noqa: E402

REVIEWED = os.path.join(HERE, 'bank_lint_reviewed.json')
_checker: S.Checker | None = None


def _init() -> None:
    global _checker
    _checker = S.Checker()


def _clean_swaps(drill: S.Drill) -> list[dict]:
    out = []
    for sw in S.swaps_for(drill, _SUPP, all_positions=True):
        if sw.meta or sw.surface:
            continue
        grammar, spell = _checker.new_flags(sw)
        if grammar or spell:
            continue
        ex = drill.ex
        out.append({'exampleId': sw.example_id, 'module': sw.module, 'shape': sw.shape,
                    'pair': sw.pair, 'answer': sw.old, 'distractor': sw.new,
                    'original': sw.original, 'swapped': sw.text,
                    'prompt': ex['prompt'], 'cue': ex.get('cue'),
                    'translation': ex.get('translation'), 'hint': ex.get('hint')})
    return out


_SUPP: set[str] = set()


def clean_swaps() -> list[dict]:
    global _SUPP
    _SUPP = S.suppressions()
    drills = list(S.load_drills())
    with Pool(os.cpu_count(), initializer=_init) as pool:
        found = pool.map(_clean_swaps, drills, chunksize=16)
    return [c for cs in found for c in cs]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--export', help='write unreviewed clean swaps (with context) here')
    ap.add_argument('--prune', action='store_true', help='drop stale reviewed entries')
    args = ap.parse_args()

    reviewed = json.load(open(REVIEWED)) if os.path.exists(REVIEWED) else {}
    cands = clean_swaps()
    unreviewed = [c for c in cands
                  if c['swapped'] not in reviewed.get(c['exampleId'], {})]
    bugs = [(eid, s, v) for eid, m in reviewed.items() for s, v in m.items()
            if v.startswith('also-correct')]
    live = {(c['exampleId'], c['swapped']) for c in cands}
    stale = [(eid, s) for eid, m in reviewed.items() for s in m if (eid, s) not in live]

    if args.prune and stale:
        drop = set(stale)
        kept = {eid: {s: v for s, v in m.items() if (eid, s) not in drop}
                for eid, m in reviewed.items()}
        kept = {eid: dict(sorted(m.items())) for eid, m in sorted(kept.items()) if m}
        json.dump(kept, open(REVIEWED, 'w'), ensure_ascii=False, indent=1)
        open(REVIEWED, 'a').write('\n')
        print(f'pruned {len(stale)} stale entries')
        stale = []

    if args.export:
        json.dump(unreviewed, open(args.export, 'w'), ensure_ascii=False, indent=1)
        print(f'exported {len(unreviewed)} unreviewed clean swaps -> {args.export}')

    for eid, s, v in bugs:
        print(f'ERROR {eid}: second correct answer: « {s} » ({v})')
    for c in unreviewed[:40]:
        print(f"UNREVIEWED {c['exampleId']}: « {c['swapped']} »")
    if len(unreviewed) > 40:
        print(f'… {len(unreviewed) - 40} more unreviewed')
    if stale:
        print(f'note: {len(stale)} reviewed entries no longer match content (safe to drop)')
    print(f'{len(cands)} clean swaps; {len(unreviewed)} unreviewed; {len(bugs)} also-correct')
    return 1 if unreviewed or bugs else 0


if __name__ == '__main__':
    sys.exit(main())
