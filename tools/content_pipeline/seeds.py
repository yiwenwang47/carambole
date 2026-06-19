"""Seed generation — the deterministic core fed to the LLM-generation step.

A `Seed` describes one (verb, mood, tense, person) slot: its correct bare form
plus exactly three WRONG-but-real distractor forms. Distractors are drawn from
the same verb's other-person forms in the same tense and its forms in the other
supported tenses, then filtered so none accidentally equals the correct answer
(French syncretism, e.g. présent je/il "parle", makes that a real hazard).
"""
from __future__ import annotations

from dataclasses import dataclass, field

from content_pipeline.conjugator import SUPPORTED_TENSES, conjugate_tense

# Canonical subject pronouns, indexed 0..5.
PRONOUNS: tuple[str, ...] = ("je", "tu", "il", "nous", "vous", "ils")

# How many distractors each seed carries.
_NUM_DISTRACTORS = 3


@dataclass(frozen=True)
class Seed:
    """One drill slot with its answer and three wrong-but-real distractors."""

    verb: str
    mood: str
    tense: str
    person_index: int
    pronoun: str
    correct_form: str
    distractors: list[str] = field(default_factory=list)


def _distractor_pool(
    verb: str, mood: str, tense: str, correct_form: str
) -> list[str]:
    """Ordered, deduped real forms of ``verb`` that are NOT ``correct_form``.

    Priority order (most contrastive first):
      1. other-person forms in the *same* tense,
      2. forms from the other supported tenses (in SUPPORTED_TENSES order).
    """
    pool: list[str] = []
    seen: set[str] = {correct_form}

    def _add(forms: list[str]) -> None:
        for form in forms:
            if form not in seen:
                seen.add(form)
                pool.append(form)

    # 1. Same tense, other persons.
    _add(conjugate_tense(verb, mood, tense))

    # 2. Other supported tenses.
    for other_mood, other_tense in SUPPORTED_TENSES:
        if (other_mood, other_tense) == (mood, tense):
            continue
        _add(conjugate_tense(verb, other_mood, other_tense))

    return pool


def make_seeds(verb: str, mood: str, tense: str) -> list[Seed]:
    """Build six Seeds (one per person) for ``verb`` in ``(mood, tense)``."""
    forms = conjugate_tense(verb, mood, tense)
    seeds: list[Seed] = []
    for index, pronoun in enumerate(PRONOUNS):
        correct_form = forms[index]
        pool = _distractor_pool(verb, mood, tense, correct_form)
        distractors = pool[:_NUM_DISTRACTORS]
        seeds.append(
            Seed(
                verb=verb,
                mood=mood,
                tense=tense,
                person_index=index,
                pronoun=pronoun,
                correct_form=correct_form,
                distractors=distractors,
            )
        )
    return seeds


def all_seeds(
    verbs: list[str], tenses: list[tuple[str, str]]
) -> list[Seed]:
    """Flatten ``make_seeds`` over every (verb, tense) combination."""
    out: list[Seed] = []
    for verb in verbs:
        for mood, tense in tenses:
            out.extend(make_seeds(verb, mood, tense))
    return out
