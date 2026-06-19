"""Tests for the Seed generator — the core of the deterministic pipeline.

A Seed pairs a (verb, mood, tense, person) slot with its correct bare form and
exactly three WRONG-but-real distractor forms. The distractor invariants below
guard against shipping an exercise whose "wrong" answers are accidentally right
(French syncretism makes this a real hazard).
"""
import dataclasses

import pytest

from content_pipeline.seeds import Seed, all_seeds, make_seeds


def test_make_seeds_returns_one_per_person():
    seeds = make_seeds("parler", "indicatif", "présent")
    assert len(seeds) == 6


def test_seed_is_frozen_dataclass():
    seeds = make_seeds("parler", "indicatif", "présent")
    assert dataclasses.is_dataclass(Seed)
    with pytest.raises(dataclasses.FrozenInstanceError):
        seeds[0].verb = "autre"  # type: ignore[misc]


def test_person_index_and_pronoun_are_canonical():
    seeds = make_seeds("parler", "indicatif", "présent")
    pronouns = ["je", "tu", "il", "nous", "vous", "ils"]
    for i, seed in enumerate(seeds):
        assert seed.person_index == i
        assert seed.pronoun == pronouns[i]


def test_correct_form_matches_conjugation():
    seeds = make_seeds("parler", "indicatif", "présent")
    forms = ["parle", "parles", "parle", "parlons", "parlez", "parlent"]
    assert [s.correct_form for s in seeds] == forms


def test_exactly_three_distractors():
    for seed in make_seeds("parler", "indicatif", "présent"):
        assert len(seed.distractors) == 3


def test_distractors_never_equal_correct_form():
    # Covers syncretism: présent je/il "parle" are identical, so the il-form
    # must NOT slip in as a distractor for the je-slot.
    for seed in make_seeds("parler", "indicatif", "présent"):
        for d in seed.distractors:
            assert d != seed.correct_form


def test_distractors_are_distinct_from_each_other():
    for seed in make_seeds("être", "indicatif", "présent"):
        assert len(set(seed.distractors)) == len(seed.distractors)


def test_distractors_are_real_forms_of_the_verb():
    # Every distractor must be an actual bare form of this verb in some
    # supported tense (i.e. real French, just wrong for this slot).
    from content_pipeline.conjugator import conjugate_tense, SUPPORTED_TENSES

    real_forms = set()
    for mood, tense in SUPPORTED_TENSES:
        real_forms.update(conjugate_tense("parler", mood, tense))

    for seed in make_seeds("parler", "indicatif", "présent"):
        for d in seed.distractors:
            assert d in real_forms


def test_syncretism_heavy_verb_still_gets_valid_distractors():
    # imparfait je/tu forms are identical (étais), and several persons collide.
    # The generator must still produce 3 distinct, non-answer distractors.
    for seed in make_seeds("être", "indicatif", "imparfait"):
        assert len(seed.distractors) == 3
        assert len(set(seed.distractors)) == 3
        assert seed.correct_form not in seed.distractors


def test_all_seeds_iterates_verbs_and_tenses():
    seeds = all_seeds(
        ["parler", "aimer"],
        [("indicatif", "présent"), ("indicatif", "imparfait")],
    )
    # 2 verbs x 2 tenses x 6 persons.
    assert len(seeds) == 24
    assert {s.verb for s in seeds} == {"parler", "aimer"}
    assert {s.tense for s in seeds} == {"présent", "imparfait"}
