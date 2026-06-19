"""Topic metadata for generated tenses, keyed by topic id.

Generated content groups by (mood, tense). Rule notes are English ease-in copy
(beginner-facing), matching the app's bilingual approach.
"""
from __future__ import annotations

TOPIC_META: dict[str, dict] = {
    "indicatif_present": {
        "title": "Le présent de l'indicatif",
        "sortOrder": 1,
        "ruleNote": "The present tense — what is happening now or habitually. "
        "Regular verbs follow -ER/-IR/-RE patterns; the most common verbs "
        "(être, avoir, aller, faire) are irregular.",
    },
    "indicatif_imparfait": {
        "title": "L'imparfait",
        "sortOrder": 2,
        "ruleNote": "The imparfait describes ongoing or habitual past actions "
        "('was doing', 'used to do'). Take the present 'nous' stem and add "
        "-ais, -ais, -ait, -ions, -iez, -aient.",
    },
    "indicatif_futur": {
        "title": "Le futur simple",
        "sortOrder": 3,
        "ruleNote": "The simple future — 'will do'. Usually the infinitive plus "
        "-ai, -as, -a, -ons, -ez, -ont.",
    },
    "conditionnel_present": {
        "title": "Le conditionnel présent",
        "sortOrder": 4,
        "ruleNote": "The conditional — 'would do'. Built from the future stem "
        "plus the imparfait endings.",
    },
    "subjonctif_present": {
        "title": "Le subjonctif présent",
        "sortOrder": 5,
        "ruleNote": "The subjunctive — used after wishes, doubt, emotion or "
        "necessity, often introduced by 'que'.",
    },
}

MOOD_TENSE_TO_ID: dict[tuple[str, str], str] = {
    ("indicatif", "présent"): "indicatif_present",
    ("indicatif", "imparfait"): "indicatif_imparfait",
    ("indicatif", "futur"): "indicatif_futur",
    ("conditionnel", "présent"): "conditionnel_present",
    ("subjonctif", "présent"): "subjonctif_present",
}


def topic_id_for(mood: str, tense: str) -> str:
    """Map a seed's (mood, tense) to its topic id."""
    return MOOD_TENSE_TO_ID[(mood, tense)]
