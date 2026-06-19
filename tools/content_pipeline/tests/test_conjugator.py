"""Tests for the conjugator — the deterministic French-form oracle.

`conjugate_tense` wraps verbecc and returns bare verb forms (pronoun stripped,
elision handled) in canonical person order [je, tu, il, nous, vous, ils].
Expected values below were verified by hand against standard French grammar.
"""
import pytest

from content_pipeline.conjugator import (
    SUPPORTED_TENSES,
    conjugate_tense,
)


def test_parler_present():
    assert conjugate_tense("parler", "indicatif", "présent") == [
        "parle",
        "parles",
        "parle",
        "parlons",
        "parlez",
        "parlent",
    ]


def test_etre_imparfait_handles_elision():
    # j'étais -> étais (elision must be stripped, not just a leading "je ").
    assert conjugate_tense("être", "indicatif", "imparfait") == [
        "étais",
        "étais",
        "était",
        "étions",
        "étiez",
        "étaient",
    ]


def test_aller_present_irregular():
    assert conjugate_tense("aller", "indicatif", "présent") == [
        "vais",
        "vas",
        "va",
        "allons",
        "allez",
        "vont",
    ]


def test_aimer_present_elision_on_je():
    # j'aime -> aime
    assert conjugate_tense("aimer", "indicatif", "présent")[0] == "aime"


def test_parler_futur_friendly_name_maps_to_futur_simple():
    assert conjugate_tense("parler", "indicatif", "futur") == [
        "parlerai",
        "parleras",
        "parlera",
        "parlerons",
        "parlerez",
        "parleront",
    ]


def test_parler_conditionnel_present():
    assert conjugate_tense("parler", "conditionnel", "présent") == [
        "parlerais",
        "parlerais",
        "parlerait",
        "parlerions",
        "parleriez",
        "parleraient",
    ]


def test_parler_subjonctif_present_strips_que_and_elision():
    # que je parle / qu'il parle -> parle ...
    assert conjugate_tense("parler", "subjonctif", "présent") == [
        "parle",
        "parles",
        "parle",
        "parlions",
        "parliez",
        "parlent",
    ]


def test_returns_exactly_six_forms():
    assert len(conjugate_tense("finir", "indicatif", "présent")) == 6


def test_supported_tenses_contains_required_pairs():
    for pair in [
        ("indicatif", "présent"),
        ("indicatif", "imparfait"),
        ("indicatif", "futur"),
        ("conditionnel", "présent"),
        ("subjonctif", "présent"),
    ]:
        assert pair in SUPPORTED_TENSES


def test_unsupported_tense_raises():
    with pytest.raises(ValueError):
        conjugate_tense("parler", "indicatif", "passé-simple")
