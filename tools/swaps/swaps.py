#!/usr/bin/env python3
"""One-word swaps over the course content, checked by Grammalecte.

Shared by two checks that ask the same mechanical question — "put word X in
slot i of this drill's sentence: is the result still French?":

  - tools/bank_lint.py   a distractor that leaves the sentence grammatical may
                         be a SECOND correct answer (amis/amies, là/ici).
  - tools/spot/          a swap that breaks the sentence in exactly one place
                         is a spot-the-error item.

Grammalecte is precise but misses ~30 % of real errors (2026-10-10 probe), so
it only ever *filters*; the final word on a candidate is a judge (LLM + human).

Drill shapes (the slot a distractor can take):
  - blank prompt ("Complète : « Je ___ là. »"): the blank, any distractor.
  - build (answerTokens = whole sentence): the answer token it pairs with
    (same closed class, or same-lemma-looking form). `all_positions=True` also
    tries a distractor that pairs with no token at EVERY word — catches
    synonyms like là/ici that no class list covers.
  - whole-sentence multiple choice: a distractor sentence differing in exactly
    one word.
"""
from __future__ import annotations

import json
import os
import re
import sys
from collections import Counter
from dataclasses import dataclass, field
from typing import Iterator

TOOLS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO = os.path.dirname(TOOLS)
sys.path.insert(0, os.path.join(TOOLS, 'vendor'))
sys.path.insert(0, os.path.join(TOOLS, 'tts'))
sys.path.insert(0, TOOLS)

from extract import (ELISION_GLUE, display_join, is_produced_punctuation,  # noqa: E402
                     spoken_french)

TOPICS = os.path.join(REPO, 'carambole', 'Resources', 'Topics')

CLASSES: dict[str, list[str]] = {
    'det': "le la les l' un une des du de d' au aux ce cet cette ces".split(),
    'poss': 'mon ma mes ton ta tes son sa ses notre nos votre vos leur leurs'.split(),
    'subj': "je j' tu il elle on nous vous ils elles".split(),
    'obj': "me m' te t' le la l' les lui leur nous vous y en se s'".split(),
    'rel': "qui que qu' dont où lequel laquelle lesquels lesquelles auquel duquel ce".split(),
    'prep': "à de d' en au aux chez dans sur pour par avec du des sans".split(),
    'neg': "ne n' pas jamais rien personne plus aucun aucune guère".split(),
    'cmp': ("plus moins aussi autant que qu' meilleur meilleure meilleurs meilleures "
            "mieux bien bon bonne pire").split(),
    'etre': ('suis es est sommes êtes sont étais était étions étiez étaient serai seras '
             'sera serons serez seront serais serait été sois soit soyons soyez soient').split(),
    'avoir': ('ai as a avons avez ont avais avait avions aviez avaient aurai auras aura '
              'aurons aurez auront aurais aurait eu aie aies ait ayons ayez aient').split(),
    'aller': ('vais vas va allons allez vont allais allait irai iras ira irons irez iront '
              'irais irait aille ailles aillent allé allée allés allées').split(),
    'faire': 'fais fait faisons faites font faisais faisait ferai fera ferais ferait fasse fasses'.split(),
}
TOKEN_CLASSES: dict[str, set[str]] = {}
for _c, _ws in CLASSES.items():
    for _w in _ws:
        TOKEN_CLASSES.setdefault(_w, set()).add(_c)
SUBJECT_PRONOUNS = set(CLASSES['subj'])

ELIDABLE = {'je', 'me', 'te', 'se', 'ce', 'le', 'la', 'de', 'ne', 'que'}
H_ASPIRE = ('hach', 'haie', 'haine', 'haïr', 'hall', 'halte', 'hamac', 'hamburger',
            'hameau', 'hamster', 'hanche', 'handicap', 'hangar', 'haricot', 'harpe',
            'hasard', 'hâte', 'haut', 'hérisson', 'héros', 'hêtre', 'hibou', 'hockey',
            'homard', 'honte', 'hoquet', 'hors', 'houx', 'huit', 'hurl')
# Grammar-terminology drills ("La terminaison pour 'je' est -ais.") are mentions,
# not French in use: no checker can judge a swap in them.
META = re.compile(r"(terminaison|radical|auxiliaire|participe|infinitif|on utilise|"
                  r"se forme|degré|conditionnel|subjonctif|imparfait|futur|présent|"
                  r"passé composé|masculin|féminin|pluriel|singulier|pronom|article|"
                  r"adjectif|verbe|on dit|signifie|veut dire|'[^' ]+'|^-|-$| -|- )", re.I)


def norm(t: str) -> str:
    return t.lower().replace('’', "'")


def vowel_start(w: str) -> bool:
    w = w.lower()
    if not w:
        return False
    if w[0] == 'h':
        return not w.startswith(H_ASPIRE)
    return w[0] in 'aeiouyàâäéèêëîïôöùûü'


def _cprefix(a: str, b: str) -> int:
    n = 0
    for x, y in zip(a, b):
        if x != y:
            break
        n += 1
    return n


def pairable(ans: str, dis: str) -> str | None:
    """Why `dis` may stand in `ans`'s slot ('class:…' / 'form'), or None."""
    a, d = norm(ans), norm(dis)
    if a == d:
        return None
    shared = TOKEN_CLASSES.get(a, set()) & TOKEN_CLASSES.get(d, set())
    if shared:
        return 'class:' + '/'.join(sorted(shared))
    if ' ' in a or ' ' in d:
        return None
    p = _cprefix(a, d)
    if p >= 3 or (p >= 2 and min(len(a), len(d)) <= 3):
        return 'form'
    return None


def match_case(new: str, old: str, idx: int) -> str:
    if idx == 0 or old[:1].isupper():
        return new[:1].upper() + new[1:]
    if new[:1].isupper() and new.lower() in TOKEN_CLASSES:
        return new[:1].lower() + new[1:]
    return new


def _words(t: str) -> list[str]:
    return [w for w in re.split(r'\s+', t.strip()) if w]


def surface_problem(prev: str | None, new: str, nxt: str | None, old: str) -> str | None:
    """A swap must not ALSO break elision/contraction around it (that would be a
    second error, or a malformed surface). Returns the reason, or None."""
    words = _words(new)
    if not words:
        return 'empty'
    first_new, last_new = norm(words[0]), norm(words[-1])
    if last_new.endswith("'"):
        if nxt is None or not vowel_start(nxt):
            return 'elided-before-consonant'
    elif last_new in ELIDABLE and nxt is not None and vowel_start(nxt):
        # "la école" is itself the target error only when the original was elided.
        if not norm(old).endswith("'"):
            return 'needs-elision'
    if prev is not None:
        p = norm(prev)
        if p.endswith("'") and not vowel_start(first_new):
            return 'prev-elided-before-consonant'
        if p in ELIDABLE and vowel_start(first_new):
            return 'prev-needs-elision'
        if p in ('à', 'de') and first_new in ('le', 'les'):
            return 'needs-contraction'
    if nxt is not None and norm(new) in ('à', 'de') and norm(nxt) in ('le', 'les'):
        return 'needs-contraction'
    return None


def split_display(tokens: list[str]) -> list[str]:
    """Trailing punctuation becomes its own token so every word is a tap target."""
    out: list[str] = []
    for t in tokens:
        m = re.match(r'^(.*?)([.,?!;:…]+)$', t)
        core, punct = (m.group(1), m.group(2)) if m and m.group(1) else (t, '')
        out.append(core)
        if punct:
            out.append(punct)
    return out


def tokenize_blank(prompt: str) -> tuple[list[str], int] | None:
    """Words of the rendered blank prompt + the blank's index; None for shapes a
    one-word swap can't express (two blanks, a blank glued inside a word)."""
    s = '\u0001'
    body = spoken_french(prompt, s, True)
    toks: list[str] = []
    slot = None
    for w in _words(body):
        if s in w:
            pre, post = w.split(s, 1)
            if s in post or slot is not None:
                return None              # two blanks
            if pre:
                toks.append(pre)
            slot = len(toks)
            toks.append(s)
            if post:
                m = re.match(r'^(.*?)([.,?!;:…»]*)$', post)
                if m.group(1):
                    return None
                toks.append(m.group(2))
        else:
            toks.append(w)
    if slot is None:
        return None
    out: list[str] = []
    slot_out = 0
    for j, t in enumerate(toks):
        if j == slot:
            slot_out = len(out)
            out.append(t)
        else:
            out.extend(split_display([t]))
    keep = [t for t in out if t]
    return keep, slot_out - sum(1 for t in out[:slot_out] if not t)


def render(tokens: list[str]) -> str:
    s = display_join(tokens)
    s = re.sub(ELISION_GLUE, r'\1\2', s)
    return re.sub(r'\s+', ' ', s).strip()


@dataclass(frozen=True)
class Swap:
    """`tokens` is the sentence AFTER the swap; `index` the swapped word."""
    module: str
    element: str
    example_id: str
    shape: str               # blank | build | mc-sentence
    pair: str                # why the distractor fits the slot
    tokens: tuple[str, ...]
    index: int
    old: str
    new: str
    original: str            # correct rendered sentence
    text: str                # rendered sentence after the swap
    surface: str | None      # surface_problem reason, if any
    meta: bool


@dataclass
class Drill:
    module: str
    element: str
    ex: dict
    tokens: list[str] = field(default_factory=list)   # correct sentence, display tokens
    shape: str = ''


def load_drills() -> Iterator[Drill]:
    manifest = json.load(open(os.path.join(TOPICS, 'manifest.json')))
    for fname in manifest['moduleFiles']:
        mod = json.load(open(os.path.join(TOPICS, fname)))
        for el in mod['elements']:
            for ex in el['examples']:
                yield Drill(fname.split('.')[0], el['id'], ex)


def distractors(ex: dict) -> list[str]:
    return sorted(set((Counter(ex['tokenBank']) - Counter(ex['answerTokens'])).elements()))


def distractors_from_bank(bank: list[str], old: str) -> list[str]:
    """Bank words that could stand in `old`'s slot, in bank order."""
    return [b for b in dict.fromkeys(bank) if ' ' not in b and pairable(old, b)]


def swaps_for(d: Drill, suppressed: set[str], all_positions: bool = False) -> list[Swap]:
    ex = d.ex
    ans = ex['answerTokens']
    blank = '_' in ex['prompt']
    slots: list[tuple[list[str], int, str, str, str]] = []
    if blank:
        tb = tokenize_blank(ex['prompt'])
        if tb is None or len(ans) != 1:
            return []
        toks, slot = tb
        toks = list(toks)
        toks[slot] = ans[0]
        shape = 'blank'
        for dis in distractors(ex):
            slots.append((toks, slot, ans[0], dis, 'blank'))
    elif ex['inputMode'] == 'multipleChoice':
        aw = _words(ans[0])
        toks = aw
        shape = 'mc-sentence'
        for dis in distractors(ex):
            dw = _words(dis)
            if len(dw) != len(aw):
                continue
            diff = [i for i, (x, y) in enumerate(zip(aw, dw)) if x != y]
            if len(diff) == 1:
                slots.append((aw, diff[0], aw[diff[0]], dw[diff[0]], 'mc-sentence'))
    else:
        toks = list(ans)
        shape = 'build'
        words = [i for i, a in enumerate(toks) if not is_produced_punctuation(a)]
        for dis in distractors(ex):
            paired = [(i, p) for i in words if (p := pairable(toks[i], dis))]
            if paired:
                slots.extend((toks, i, toks[i], dis, p) for i, p in paired)
            elif all_positions:
                slots.extend((toks, i, toks[i], dis, 'unpaired') for i in words)
    if not slots:
        return []
    original = (spoken_french(ex['prompt'], ans[0], True) if blank
                else ' '.join(toks) if shape == 'mc-sentence' else render(toks))
    meta = bool(META.search(original)) or ex['id'] in suppressed
    out: list[Swap] = []
    for toks, i, old, new, pair in slots:
        new_c = match_case(new, old, i)
        if norm(new_c) == norm(old):
            continue
        prev = toks[i - 1] if i > 0 else None
        nxt = (toks[i + 1] if i + 1 < len(toks) and not is_produced_punctuation(toks[i + 1])
               else None)
        t1 = list(toks)
        t1[i] = new_c
        if shape == 'mc-sentence':
            text = ' '.join(t1)
        elif blank:
            text = spoken_french(ex['prompt'], new_c, True)
        else:
            text = render(t1)
        out.append(Swap(d.module, d.element, ex['id'], shape, pair, tuple(t1), i, old,
                        new_c, original, text, surface_problem(prev, new_c, nxt, old), meta))
    return out


class Checker:
    """Grammalecte with the same options as tools/deep_lint.py."""

    def __init__(self) -> None:
        from deep_lint import build_checker
        self.gc, self.opts = build_checker()

    def flags(self, text: str) -> tuple[list[dict], list[str]]:
        g, sp = self.gc.getParagraphErrors(text, dOptions=self.opts)
        grammar = [{'rule': e['sRuleId'], 'start': e['nStart'], 'end': e['nEnd'],
                    'sugg': list(e.get('aSuggestions', []))[:5]} for e in g]
        return grammar, [e['sValue'] for e in sp]

    def new_flags(self, swap: Swap) -> tuple[list[dict], list[str]]:
        """Flags the swap ADDS over the original sentence."""
        og, osp = self.flags(swap.original)
        g, sp = self.flags(swap.text)
        rules = {f['rule'] for f in og}
        return [f for f in g if f['rule'] not in rules], [w for w in sp if w not in osp]


def suppressions() -> set[str]:
    return set(json.load(open(os.path.join(TOOLS, 'deep_lint_suppressions.json'))))
