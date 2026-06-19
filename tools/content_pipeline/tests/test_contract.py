"""Tests for the seed-consistency contract.

The LLM generation step may ONLY write the natural sentence, translation and hint.
It must never alter the grammar: the answer + the option bank are locked to the
deterministic seed. `check_against_seed` enforces that, so a hallucinated
conjugation can never reach the app.
"""
from content_pipeline.contract import check_against_seed


def _seed() -> dict:
    return {
        "verb": "parler",
        "mood": "indicatif",
        "tense": "présent",
        "person_index": 0,
        "pronoun": "je",
        "correct_form": "parle",
        "distractors": ["parles", "parlons", "parlez"],
    }


def _conforming_exercise() -> dict:
    return {
        "id": "indicatif_present_parler_0",
        "topicID": "indicatif_present",
        "type": "conjugate",
        "prompt": "Je ___ avec mes amis. (parler)",
        "cue": "parler",
        "answerTokens": ["parle"],
        "tokenBank": ["parlons", "parle", "parlez", "parles"],  # any order, same set
        "inputMode": "multipleChoice",
        "explanation": "je form of parler in the present is 'parle'.",
        "translation": "I talk with my friends.",
        "hint": "je -> -e.",
    }


def test_conforming_exercise_has_no_errors():
    assert check_against_seed(_conforming_exercise(), _seed()) == []


def test_answer_must_equal_seed_correct_form():
    ex = _conforming_exercise()
    ex["answerTokens"] = ["parles"]  # a distractor, not the seed's correct form
    errors = check_against_seed(ex, _seed())
    assert any("answer" in e.lower() for e in errors)


def test_token_bank_must_be_exactly_the_seed_forms():
    ex = _conforming_exercise()
    ex["tokenBank"] = ["parle", "parles", "parlons", "parlait"]  # 'parlait' invented
    errors = check_against_seed(ex, _seed())
    assert any("tokenBank" in e or "bank" in e.lower() for e in errors)


def test_prompt_must_contain_the_blank():
    ex = _conforming_exercise()
    ex["prompt"] = "Je parle avec mes amis. (parler)"  # no ___
    errors = check_against_seed(ex, _seed())
    assert any("blank" in e.lower() or "___" in e for e in errors)


def test_prompt_must_contain_the_subject_pronoun():
    ex = _conforming_exercise()
    ex["prompt"] = "___ avec mes amis. (parler)"  # pronoun missing
    errors = check_against_seed(ex, _seed())
    assert any("pronoun" in e.lower() for e in errors)


def test_cue_must_be_the_infinitive():
    ex = _conforming_exercise()
    ex["cue"] = "aimer"
    errors = check_against_seed(ex, _seed())
    assert any("cue" in e.lower() or "infinitive" in e.lower() for e in errors)


def test_invalid_exercise_also_surfaces_schema_errors():
    # check_against_seed should also run the base schema validator.
    ex = _conforming_exercise()
    ex["translation"] = ""
    errors = check_against_seed(ex, _seed())
    assert any("translation" in e for e in errors)
