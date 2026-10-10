#!/usr/bin/env python3
"""Spot-the-error candidates from the existing course (no new sentences).

For every drill, try each grammar-trap distractor in its slot (tools/swaps) and
keep a swap only when ALL hold:

  1. surface ok — the swap breaks no elision/contraction around it, and the
     drill is French in use (not a grammar-terminology mention);
  2. Grammalecte flags the new sentence AND suggests the original word back
     (precise but ~70 % recall: misses are dropped, never rescued);
  3. one fix — no other single-word change at another position makes the
     sentence pass Grammalecte. Tier 2: the only other fixes change the subject
     pronoun ("Je lui parlent" → "Ils lui parlent"); those ship with the subject
     LOCKED (untappable), so the verb is the only fix left;
  4. 2 wrong options for the slot, each also flagged by Grammalecte.

One candidate per drill (tier 1 first, then one whose correct word the drill's
explanation names). Output is a judge spec, per module — a judge (LLM, then a
human spot check) decides; tools/spot/apply.py writes accepted items into the
topic JSON as `spot`.

Run:  python3 tools/spot/candidates.py OUT_DIR     # ~1 min, all cores
"""
from __future__ import annotations

import json
import os
import re
import sys
from multiprocessing import Pool

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), 'swaps'))

import swaps as S  # noqa: E402

_checker: S.Checker | None = None
_SUPP: set[str] = set()


def _init(supp: set[str]) -> None:
    global _checker, _SUPP
    _checker = S.Checker()
    _SUPP = supp


def _passes(text: str) -> bool:
    grammar, _ = _checker.flags(text)
    return not grammar


def _render(sw: S.Swap, toks: list[str]) -> str:
    return ' '.join(toks) if sw.shape == 'mc-sentence' else S.render(toks)


def _alt_fixes(sw: S.Swap, bank: list[str]) -> list[tuple[int, str]]:
    """Single-word changes at OTHER positions that make the swapped sentence pass."""
    toks = list(sw.tokens)
    grammar, _ = _checker.flags(sw.text)
    trials: set[tuple[int, str]] = set()
    for f in grammar:
        span = sw.text[f['start']:f['end']]
        for j, t in enumerate(toks):
            if j != sw.index and t == span:
                trials.update((j, s) for s in f['sugg'])
    for j, t in enumerate(toks):
        if j == sw.index or S.is_produced_punctuation(t) or ' ' in t:
            continue
        sib: set[str] = set()
        for cl in S.TOKEN_CLASSES.get(S.norm(t), set()):
            sib.update(S.CLASSES[cl])
        sib.update(b for b in bank if ' ' not in b and S.pairable(t, b))
        trials.update((j, S.match_case(s, t, j)) for s in sib)
    alts = []
    for j, s in sorted(trials):
        if S.norm(s) == S.norm(toks[j]):
            continue
        t1 = list(toks)
        t1[j] = s
        alt = _render(sw, t1)
        if alt != sw.original and _passes(alt):
            alts.append((j, s))
    return alts


def _wrong_options(sw: S.Swap, bank: list[str]) -> list[str]:
    """Other words for the slot that are also flagged — bank distractors first."""
    old = sw.old
    pool = [b for b in S.distractors_from_bank(bank, old) if S.norm(b) != S.norm(sw.new)]
    for cl in sorted(S.TOKEN_CLASSES.get(S.norm(old), set())):
        pool += [w for w in S.CLASSES[cl] if w not in pool]
    toks = list(sw.tokens)
    prev = toks[sw.index - 1] if sw.index > 0 else None
    nxt = toks[sw.index + 1] if sw.index + 1 < len(toks) else None
    out: list[str] = []
    for w in pool:
        w = S.match_case(w, old, sw.index)
        if S.norm(w) in (S.norm(old), S.norm(sw.new)) or w in out:
            continue
        if S.surface_problem(prev, w, nxt, old):
            continue
        t1 = list(toks)
        t1[sw.index] = w
        if not _passes(_render(sw, t1)):
            out.append(w)
        if len(out) == 2:
            break
    return out


def _on_target(sw: S.Swap, ex: dict) -> bool:
    txt = f"{ex.get('explanation', '')} {ex.get('explanationEN', '')}".lower()
    return re.search(r"(?<![\w'])" + re.escape(sw.old.lower()) + r'(?!\w)', txt) is not None


def _drill_candidates(drill: S.Drill) -> list[dict]:
    ex = drill.ex
    bank = ex['tokenBank']
    found = []
    for sw in S.swaps_for(drill, _SUPP):
        if sw.meta or sw.surface:
            continue
        og, _ = _checker.flags(sw.original)
        if og:
            continue
        grammar, _ = _checker.new_flags(sw)
        if not grammar or not any(S.norm(sw.old) in map(S.norm, f['sugg']) for f in grammar):
            continue
        alts = _alt_fixes(sw, bank)
        alt_idx = {j for j, _ in alts}
        if not alts:
            tier, locked = 1, []
        elif all(S.norm(sw.tokens[j]) in S.SUBJECT_PRONOUNS for j in alt_idx):
            tier, locked = 2, sorted(alt_idx)
        else:
            continue
        wrong = _wrong_options(sw, bank)
        if len(wrong) < 2:
            continue
        found.append((tier, not _on_target(sw, ex), sw, locked, wrong))
    if not found:
        return []
    tier, _, sw, locked, wrong = min(found, key=lambda f: (f[0], f[1], f[2].index))
    # Shown as a sentence: capital first word, every option cased for its slot.
    toks = list(sw.tokens)
    toks[0] = toks[0][:1].upper() + toks[0][1:]
    options = [S.match_case(w, sw.old, sw.index) for w in [sw.old] + wrong]
    return [{'exampleId': sw.example_id, 'module': sw.module, 'element': sw.element,
             'tier': tier, 'tokens': toks, 'wrongIndex': sw.index,
             'wrongToken': toks[sw.index], 'correctToken': options[0], 'options': options,
             'locked': locked, 'corrupted': sw.text, 'original': sw.original,
             'translation': ex.get('translation'), 'explanation': ex.get('explanation'),
             'explanationEN': ex.get('explanationEN')}]


def main() -> int:
    out_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out')
    os.makedirs(out_dir, exist_ok=True)
    drills = list(S.load_drills())
    with Pool(os.cpu_count(), initializer=_init, initargs=(S.suppressions(),)) as pool:
        found = [c for cs in pool.map(_drill_candidates, drills, chunksize=8) for c in cs]
    by_module: dict[str, list[dict]] = {}
    for c in found:
        by_module.setdefault(c['module'], []).append(c)
    for m, cs in sorted(by_module.items()):
        json.dump(cs, open(os.path.join(out_dir, f'{m}.json'), 'w'), ensure_ascii=False, indent=1)
        t1 = sum(c['tier'] == 1 for c in cs)
        print(f'{m:24} {len(cs):4}  (tier 1: {t1}, tier 2: {len(cs) - t1})')
    print(f'TOTAL {len(found)} drills with a candidate')
    return 0


if __name__ == '__main__':
    sys.exit(main())
