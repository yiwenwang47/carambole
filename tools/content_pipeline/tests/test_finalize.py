"""Tests for finalize: turn raw LLM output into validated, grouped topic JSON."""
from content_pipeline.topic_meta import topic_id_for, TOPIC_META
from content_pipeline.finalize import accept, group_topics


def _seed() -> dict:
    return {
        "verb": "parler", "mood": "indicatif", "tense": "présent",
        "person_index": 0, "pronoun": "je",
        "correct_form": "parle", "distractors": ["parles", "parlons", "parlez"],
    }


def _good_line() -> dict:
    return {
        "id": "indicatif_present_parler_0",
        "topicID": "indicatif_present",
        "type": "conjugate",
        "prompt": "Je ___ avec mes amis. (parler)",
        "cue": "parler",
        "answerTokens": ["parle"],
        "tokenBank": ["parle", "parles", "parlons", "parlez"],
        "inputMode": "multipleChoice",
        "explanation": "je form of parler is 'parle'.",
        "translation": "I talk with my friends.",
        "hint": "je -> -e.",
        "_seed": _seed(),
    }


def test_topic_id_for_maps_mood_tense():
    assert topic_id_for("indicatif", "présent") == "indicatif_present"
    assert topic_id_for("subjonctif", "présent") in TOPIC_META


def test_accept_keeps_conforming_line():
    good, rejected = accept([_good_line()])
    assert len(good) == 1 and rejected == []
    assert "_seed" not in good[0]  # the seed echo is stripped from the exercise


def test_accept_drops_line_that_violates_its_seed():
    bad = _good_line()
    bad["answerTokens"] = ["parles"]  # not the seed's correct form
    good, rejected = accept([bad])
    assert good == [] and len(rejected) == 1
    assert "answer" in " ".join(rejected[0]["errors"]).lower()


def test_group_topics_groups_by_topic_and_validates():
    ex_a = {k: v for k, v in _good_line().items() if k != "_seed"}
    ex_b = dict(ex_a)
    ex_b["id"] = "indicatif_imparfait_etre_2"
    ex_b["topicID"] = "indicatif_imparfait"
    ex_b["prompt"] = "Il ___ content. (être)"
    ex_b["cue"] = "être"
    ex_b["answerTokens"] = ["était"]
    ex_b["tokenBank"] = ["était", "étais", "étions", "étiez"]
    ex_b["translation"] = "He was happy."

    topics = group_topics([ex_a, ex_b])
    ids = {t["id"] for t in topics}
    assert ids == {"indicatif_present", "indicatif_imparfait"}
    for t in topics:
        assert t["title"] and isinstance(t["sortOrder"], int)
        assert len(t["exercises"]) == 1
