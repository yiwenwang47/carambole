"""Tests for the Exercise validator — the gate every generated exercise passes through.

The validator mirrors the Swift `Exercise` schema + drill invariants so malformed
LLM output never reaches the app.
"""
from content_pipeline.validate import validate_exercise


def _valid_mc() -> dict:
    return {
        "id": "eap_01",
        "topicID": "etre_avoir_present",
        "type": "conjugate",
        "prompt": "Tu ___ français. (être)",
        "cue": "être",
        "answerTokens": ["es"],
        "tokenBank": ["es", "est", "suis", "as"],
        "inputMode": "multipleChoice",
        "explanation": "tu form of être is 'es'.",
        "translation": "You are French.",
        "hint": "tu form of être -> es.",
    }


def _valid_build() -> dict:
    return {
        "id": "erv_04",
        "topicID": "er_verbs_present",
        "type": "wordOrder",
        "prompt": "Construis : « We speak French. »",
        "cue": None,
        "answerTokens": ["Nous", "parlons", "français"],
        "tokenBank": ["Nous", "parlons", "parlez", "français"],
        "inputMode": "buildFromTokens",
        "explanation": "nous -> -ons: parlons.",
        "translation": "We speak French.",
        "hint": "nous -> -ons.",
    }


def test_valid_multiple_choice_has_no_errors():
    assert validate_exercise(_valid_mc()) == []


def test_valid_build_from_tokens_has_no_errors():
    assert validate_exercise(_valid_build()) == []


def test_missing_required_key_is_reported():
    ex = _valid_mc()
    del ex["answerTokens"]
    errors = validate_exercise(ex)
    assert any("answerTokens" in e for e in errors)


def test_multiple_choice_answer_must_be_in_token_bank():
    ex = _valid_mc()
    ex["answerTokens"] = ["xxx"]  # not in bank
    errors = validate_exercise(ex)
    assert any("tokenBank" in e for e in errors)


def test_multiple_choice_answer_must_be_single_token():
    ex = _valid_mc()
    ex["answerTokens"] = ["es", "est"]  # MC must be exactly one
    errors = validate_exercise(ex)
    assert any("single" in e.lower() or "one" in e.lower() for e in errors)


def test_build_from_tokens_answer_must_be_subset_of_bank():
    ex = _valid_build()
    ex["answerTokens"] = ["Nous", "mange"]  # 'mange' not in bank
    errors = validate_exercise(ex)
    assert any("tokenBank" in e or "mange" in e for e in errors)


def test_empty_prompt_is_reported():
    ex = _valid_mc()
    ex["prompt"] = "   "
    errors = validate_exercise(ex)
    assert any("prompt" in e for e in errors)


def test_unknown_input_mode_is_reported():
    ex = _valid_mc()
    ex["inputMode"] = "freeText"
    errors = validate_exercise(ex)
    assert any("inputMode" in e for e in errors)


def test_unknown_type_is_reported():
    ex = _valid_mc()
    ex["type"] = "translation"
    errors = validate_exercise(ex)
    assert any("type" in e for e in errors)


def test_missing_translation_is_reported():
    # English ease-in: translation is required content for this app.
    ex = _valid_mc()
    ex["translation"] = ""
    errors = validate_exercise(ex)
    assert any("translation" in e for e in errors)


def test_hint_may_be_null():
    ex = _valid_mc()
    ex["hint"] = None
    assert validate_exercise(ex) == []
