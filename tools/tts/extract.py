#!/usr/bin/env python3
"""Extract the speakable French sentence for every drill example.

Faithful Python port of the Swift `Exercise.spokenFrench` / `displayJoin` /
`seed64` builders (carambole/Models/Exercise.swift). The audio filename key is
the FNV-1a 64-bit hash of the spoken sentence (hex, 16 chars) — identical to the
Swift `audioKey`, so the generated files line up with what the app looks up, and
identical sentences across drills dedup to one file.

Run:  python3 tools/tts/extract.py            # writes spoken_manifest.json + stats
The golden self-test (--selftest, also run on every invocation) locks the port
to the exact input/output pairs asserted in Exercise.swift `_selfTest()`.
"""
from __future__ import annotations

import json
import os
import re
import sys

# --- ports of the Swift builders (keep byte-for-byte equivalent) -------------

UNTYPEABLE = set(['.', ',', '?', '!', ';', ':', '«', '»', '…', '"', '(', ')'])
OPENING = set(['«', '(', '"'])

MASK64 = 0xFFFFFFFFFFFFFFFF


def seed64(s: str) -> int:
    """FNV-1a 64-bit over UTF-8 bytes (== Swift Exercise.seed64)."""
    h = 1469598103934665603
    for b in s.encode('utf-8'):
        h ^= b
        h = (h * 1099511628211) & MASK64
    return h


def audio_key(text: str) -> str:
    return '%016x' % seed64(text)


def prompt_has_blank(prompt: str) -> bool:
    return '_' in prompt


def is_produced_punctuation(token: str) -> bool:
    if not token:
        return False
    return all(c in UNTYPEABLE for c in token)


def display_join(tokens: list[str]) -> str:
    """Join, hugging bare-punctuation tokens to a neighbour (== Swift displayJoin)."""
    out = ''
    hug_next = False
    for token in tokens:
        punct = is_produced_punctuation(token)
        opening = punct and all(c in OPENING for c in token)
        if out == '':
            out = token
        elif hug_next or (punct and not opening):
            out += token
        else:
            out += ' ' + token
        hug_next = opening
    return out


def spoken_french(prompt: str, answer: str, has_blank: bool) -> str:
    """== Swift Exercise.spokenFrench(prompt:answer:hasBlank:)."""
    if has_blank:
        body = prompt
        idx = body.find(' : ')               # drop a leading "instruction :"
        if idx != -1:
            body = body[idx + 3:]
        body = re.sub(r'\([^)]*\)', '', body)        # strip parenthetical cues
        body = body.replace('«', '').replace('»', '')
        body = re.sub(r'_+', lambda m: answer, body)  # fill blanks (literal answer)
    else:
        # No blank → the assembled answer is the whole French sentence.
        body = answer
    # Tidy (both shapes): glue elisions ("C' est" → "C'est"), collapse spaces, trim.
    body = body.replace("' ", "'").replace('’ ', '’')
    body = re.sub(r'\s+', ' ', body)
    return body.strip()


def spoken_for_example(ex: dict) -> str:
    answer = display_join(ex['answerTokens'])
    return spoken_french(ex['prompt'], answer, prompt_has_blank(ex['prompt']))


# --- golden self-test (mirrors Exercise.swift _selfTest) ---------------------

def _self_test() -> None:
    eq = lambda got, want, msg: (_ for _ in ()).throw(AssertionError(
        f'{msg}\n  got:  {got!r}\n  want: {want!r}')) if got != want else None

    # spokenFrench builder
    eq(spoken_french('Construis : « He has a dog. »', 'Il a un chien', False),
       'Il a un chien', 'build prompt speaks the answer sentence')
    eq(spoken_french('Construis : « It is a dog. »', "C' est un chien", False),
       "C'est un chien", 'build prompt glues a split elision')
    eq(spoken_french("Choisis l'article : ___ café", 'un', True),
       'un café', 'article blank filled, instruction prefix stripped')
    eq(spoken_french('Complète : « Vous ne ___ pas. » (parler)', 'parlez', True),
       'Vous ne parlez pas.', 'guillemets + parenthetical cue stripped')
    eq(spoken_french('Complète (never) : « Je ne parle ___. »', 'jamais', True),
       'Je ne parle jamais.', 'pre-colon cue dropped with the prefix')
    eq(spoken_french("Choisis l'article : ___ école", "l'", True),
       "l'école", 'elision answer glued to the noun')

    # displayJoin
    eq(display_join(['Non', ',', 'je', 'ne', 'mange', 'pas']), 'Non, je ne mange pas',
       'displayJoin hugs the comma')
    eq(display_join(["C'est", 'mon', 'chien', '.']), "C'est mon chien.",
       'displayJoin hugs the terminal period')
    eq(display_join(['je', 'suis', 'là']), 'je suis là', 'displayJoin spaces words')
    eq(display_join(['Tu aimes le café?']), 'Tu aimes le café?',
       'displayJoin leaves a whole MC sentence intact')

    # is_produced_punctuation
    assert is_produced_punctuation(',') and is_produced_punctuation('…')
    assert not is_produced_punctuation('') and not is_produced_punctuation("C'est")
    assert not is_produced_punctuation('(rien)') and not is_produced_punctuation('café?')

    # prompt_has_blank
    assert prompt_has_blank('Il ___ content.')
    assert not prompt_has_blank('Construis : « Do you speak French? »')

    # hash stability sanity (deterministic, non-zero)
    assert audio_key('Il a un chien') == audio_key('Il a un chien')
    assert len(audio_key('x')) == 16
    print('extract.py self-test: OK')


# --- driver ------------------------------------------------------------------

def repo_root() -> str:
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.dirname(os.path.dirname(here))


def topics_dir() -> str:
    return os.path.join(repo_root(), 'carambole', 'Resources', 'Topics')


def collect() -> list[dict]:
    tdir = topics_dir()
    manifest = json.load(open(os.path.join(tdir, 'manifest.json')))
    files = manifest['moduleFiles']
    by_key: dict[str, dict] = {}
    n_examples = 0
    for fname in files:
        mod = json.load(open(os.path.join(tdir, fname)))
        for el in mod.get('elements', []):
            for ex in el.get('examples', []):
                n_examples += 1
                text = spoken_for_example(ex)
                if not text.strip():
                    continue
                key = audio_key(text)
                if key not in by_key:
                    by_key[key] = {'key': key, 'text': text,
                                   'example_id': ex['id'], 'module': fname,
                                   'count': 1}
                else:
                    by_key[key]['count'] += 1
    rows = list(by_key.values())
    rows.sort(key=lambda r: (r['module'], r['example_id']))
    print(f'examples scanned: {n_examples} | unique sentences: {len(rows)} | '
          f'total chars (unique): {sum(len(r["text"]) for r in rows)}')
    return rows


def main(argv: list[str]) -> int:
    _self_test()
    if '--selftest' in argv:
        return 0
    rows = collect()
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       'spoken_manifest.json')
    json.dump(rows, open(out, 'w'), ensure_ascii=False, indent=1)
    print(f'wrote {out}')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
