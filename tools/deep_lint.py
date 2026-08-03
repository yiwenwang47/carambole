#!/usr/bin/env python3
"""Deep content lint: run Grammalecte (vendored, offline) over the RENDERED
French sentence of every drill — the blank filled with the answer, scaffolding
stripped (reuses tools/tts/extract.py, the same builder the app's TTS uses).

This is Layer 2 of the content-quality net (see CLAUDE.md "Rendered-surface
grammar"): tools/lint_topics.py catches the deterministic classes (elision,
contraction, si+il); this catches the open classes (agreement, conjugation,
wrong participle) a hand rule can't enumerate. The canary below locks the exact
bug class that shipped once: « Je habitais » (h muet, missing elision).

Policy:
  - grammar-rule flags  = ERRORS (exit 1) unless listed in
    tools/deep_lint_suppressions.json — a reviewed known-noise list keyed
    {drill_id: [rule_id, ...]}, mostly metalinguistic mention-vs-use drills
    ("La terminaison pour 'je' est -ais.") that no checker can parse as prose.
  - unknown-word spelling flags = WARNINGS only (embedded ease-in English and
    verb-stem fragments like "parl-" are unknown to the FR dictionary by design).
  - typography options (apostrophe style, nbsp, …) are OFF — content JSON uses
    straight quotes on purpose.

Run:  python3 tools/deep_lint.py          # exit 0 = clean
Adding a suppression: run, read the flagged sentence ALOUD as final French;
only if it is genuinely correct (or a mention, not a use) add its
drill_id/rule_id pair to the suppressions file — never suppress wholesale.
"""
from __future__ import annotations

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, 'vendor'))   # vendored grammalecte
sys.path.insert(0, os.path.join(HERE, 'tts'))      # extract.py

import grammalecte                                  # noqa: E402
from extract import spoken_for_example, _self_test  # noqa: E402

TOPICS = os.path.join(os.path.dirname(HERE), 'carambole', 'Resources', 'Topics')
SUPPRESSIONS_FILE = os.path.join(HERE, 'deep_lint_suppressions.json')

# Pure-typography options — irrelevant to grammar, noisy on straight-quote JSON.
TYPO_OPTS_OFF = {'apos': False, 'typo': False, 'nbsp': False, 'esp': False,
                 'tab': False, 'unit': False, 'num': False, 'liga': False}


def build_checker() -> tuple[grammalecte.GrammarChecker, dict]:
    gc = grammalecte.GrammarChecker('fr')
    # gc_engine treats dOptions as a full REPLACEMENT, not a merge — always pass
    # the engine defaults with our overrides on top, or every unlisted rule
    # family silently turns off (which once made the canary pass vacuously).
    opts = {**gc.gce.getOptions(), **TYPO_OPTS_OFF}
    return gc, opts


def flags_for(gc: grammalecte.GrammarChecker, opts: dict, text: str) -> list[dict]:
    grammar, spelling = gc.getParagraphErrors(text, dOptions=opts)
    out = [{'rule_id': e.get('sRuleId', '?'), 'message': e.get('sMessage', ''),
            'kind': 'grammar'} for e in grammar]
    for e in spelling:
        word = e.get('sValue', '')
        if word[:1].isupper() and e.get('nStart', 0) > 0:
            continue                       # likely proper noun mid-sentence
        out.append({'rule_id': 'SPELL_unknown_word',
                    'message': f'Mot inconnu : {word}', 'kind': 'spelling'})
    return out


def canary(gc: grammalecte.GrammarChecker, opts: dict) -> bool:
    """The engine must flag the exact bug class that shipped once, and must not
    flag its correction. Guards against option-merge regressions going quiet."""
    bad = flags_for(gc, opts, 'Je habitais chez mes parents.')
    good = [f for f in flags_for(gc, opts, "J'habitais chez mes parents.")
            if f['kind'] == 'grammar']
    return bool(bad) and not good


def main() -> int:
    _self_test()
    gc, opts = build_checker()
    if not canary(gc, opts):
        print('deep_lint: CANARY FAILED — engine no longer flags « Je habitais » '
              'or wrongly flags « J\'habitais ». Do not trust this run.')
        return 2

    suppressions: dict[str, list[str]] = {}
    if os.path.exists(SUPPRESSIONS_FILE):
        suppressions = json.load(open(SUPPRESSIONS_FILE))

    manifest = json.load(open(os.path.join(TOPICS, 'manifest.json')))
    errors: list[str] = []
    warnings = 0
    n = 0
    for fname in manifest['moduleFiles']:
        mod = json.load(open(os.path.join(TOPICS, fname)))
        for el in mod.get('elements', []):
            for ex in el.get('examples', []):
                text = spoken_for_example(ex).strip()
                if not text:
                    continue
                n += 1
                for f in flags_for(gc, opts, text):
                    if f['kind'] == 'spelling':
                        warnings += 1
                        continue
                    if f['rule_id'] in suppressions.get(ex['id'], []):
                        continue
                    errors.append(f"  ✗ {fname}:{ex['id']}: {f['rule_id']}\n"
                                  f"      « {text} » — {f['message']}")
    if errors:
        print(f'DEEP LINT FAILED ({len(errors)} grammar flag(s) on {n} sentences):')
        print('\n'.join(errors))
        print('If a flag is genuine checker noise (read the sentence aloud '
              'first), add drill_id/rule_id to tools/deep_lint_suppressions.json.')
        return 1
    print(f'DEEP LINT OK — {n} rendered sentences, 0 grammar errors '
          f'({warnings} unknown-word warnings ignored)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
