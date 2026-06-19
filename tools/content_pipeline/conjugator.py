"""Deterministic French conjugation oracle, wrapping verbecc.

`conjugate_tense` returns the six bare verb forms (pronoun stripped, elision and
the subjunctive ``que``/``qu'`` prefix removed) in canonical person order
``[je, tu, il, nous, vous, ils]``. Friendly ``(mood, tense)`` names are mapped to
verbecc's internal enum string values (e.g. ``futur`` -> ``futur-simple``).
"""
from __future__ import annotations

from functools import lru_cache

from verbecc import CompleteConjugator

# Friendly (mood, tense) -> verbecc internal (mood_value, tense_value).
# verbecc keys its `moods`/tense dicts by enums whose `.value` is the string here.
_TENSE_MAP: dict[tuple[str, str], tuple[str, str]] = {
    ("indicatif", "présent"): ("indicatif", "présent"),
    ("indicatif", "imparfait"): ("indicatif", "imparfait"),
    ("indicatif", "futur"): ("indicatif", "futur-simple"),
    ("conditionnel", "présent"): ("conditionnel", "présent"),
    ("subjonctif", "présent"): ("subjonctif", "présent"),
}

# Public, frozen list of the friendly (mood, tense) pairs we support.
SUPPORTED_TENSES: list[tuple[str, str]] = list(_TENSE_MAP.keys())

# The six canonical persons, in order, identified by verbecc's PronounFr value.
_CANONICAL_PRONOUNS: tuple[str, ...] = ("je", "tu", "il", "nous", "vous", "ils")


@lru_cache(maxsize=1)
def _conjugator() -> CompleteConjugator:
    return CompleteConjugator("fr")


def _strip_to_bare_form(conjugated: str) -> str:
    """Return the bare verb form from a verbecc conjugated string.

    Examples: ``je parle`` -> ``parle``, ``j'aime`` -> ``aime``,
    ``que nous parlions`` -> ``parlions``, ``qu'il aime`` -> ``aime``.
    No French simple-tense form contains an internal space or apostrophe, so the
    bare form is the final whitespace-or-apostrophe-delimited token.
    """
    token = conjugated.strip()
    for sep in (" ", "'", "’"):  # space, ASCII apostrophe, right single quote
        token = token.rsplit(sep, 1)[-1]
    return token


def conjugate_tense(verb: str, mood: str, tense: str) -> list[str]:
    """Conjugate ``verb`` and return six bare forms in canonical person order.

    Raises ``ValueError`` if ``(mood, tense)`` is not in ``SUPPORTED_TENSES``.
    """
    key = (mood, tense)
    if key not in _TENSE_MAP:
        raise ValueError(
            f"unsupported (mood, tense): {key!r} "
            f"(supported: {SUPPORTED_TENSES})"
        )
    mood_value, tense_value = _TENSE_MAP[key]

    data = _conjugator().conjugate(verb).get_data()
    moods = data["moods"]
    mood_key = next(k for k in moods if k.value == mood_value)
    tenses = moods[mood_key]
    tense_key = next(k for k in tenses if k.value == tense_value)
    entries = tenses[tense_key]

    # Index each entry by its pronoun value; pick the canonical six.
    by_pronoun: dict[str, str] = {}
    for entry in entries:
        pronoun_value = entry["pr"].value
        if pronoun_value in _CANONICAL_PRONOUNS and pronoun_value not in by_pronoun:
            by_pronoun[pronoun_value] = _strip_to_bare_form(entry["c"][0])

    return [by_pronoun[p] for p in _CANONICAL_PRONOUNS]
