"""Tests for the topic assembler — the final gate before content ships.

`build_topic` shapes a GrammarTopic dict and routes every exercise through the
shared `validate_exercise`, refusing to assemble a topic that contains malformed
exercises. `write_topics` serialises topics + a manifest to disk.
"""
import json

import pytest

from content_pipeline.assemble import build_topic, write_topics


def _valid_exercise() -> dict:
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


def test_build_topic_shape_and_keys():
    topic = build_topic(
        topic_id="etre_avoir_present",
        title="Être & Avoir — Présent",
        sort_order=1,
        prerequisite_id=None,
        rule_note="Memorise the two auxiliaries.",
        exercises=[_valid_exercise()],
    )
    assert set(topic.keys()) == {
        "id",
        "title",
        "sortOrder",
        "prerequisiteID",
        "ruleNote",
        "exercises",
    }
    assert topic["id"] == "etre_avoir_present"
    assert topic["title"] == "Être & Avoir — Présent"
    assert topic["sortOrder"] == 1
    assert topic["prerequisiteID"] is None
    assert topic["ruleNote"] == "Memorise the two auxiliaries."
    assert topic["exercises"] == [_valid_exercise()]


def test_build_topic_preserves_prerequisite_id():
    topic = build_topic(
        topic_id="er_verbs_present",
        title="-ER Verbs",
        sort_order=2,
        prerequisite_id="etre_avoir_present",
        rule_note="Drop -er, add endings.",
        exercises=[_valid_exercise()],
    )
    assert topic["prerequisiteID"] == "etre_avoir_present"


def test_build_topic_rejects_invalid_exercise():
    bad = _valid_exercise()
    bad["answerTokens"] = ["xxx"]  # MC answer not in tokenBank
    with pytest.raises(ValueError):
        build_topic(
            topic_id="etre_avoir_present",
            title="Être & Avoir",
            sort_order=1,
            prerequisite_id=None,
            rule_note="note",
            exercises=[bad],
        )


def test_build_topic_error_names_the_offending_exercise():
    bad = _valid_exercise()
    bad["id"] = "broken_99"
    bad["answerTokens"] = ["xxx"]
    with pytest.raises(ValueError) as exc:
        build_topic(
            topic_id="t",
            title="T",
            sort_order=1,
            prerequisite_id=None,
            rule_note="note",
            exercises=[bad],
        )
    assert "broken_99" in str(exc.value)


def test_write_topics_creates_files_and_manifest(tmp_path):
    topic = build_topic(
        topic_id="etre_avoir_present",
        title="Être & Avoir",
        sort_order=1,
        prerequisite_id=None,
        rule_note="note",
        exercises=[_valid_exercise()],
    )
    result = write_topics([topic], str(tmp_path))

    expected_name = "01_etre_avoir_present.json"
    assert result == {"topicFiles": [expected_name]}

    topic_file = tmp_path / expected_name
    assert topic_file.exists()
    loaded = json.loads(topic_file.read_text(encoding="utf-8"))
    assert loaded["id"] == "etre_avoir_present"

    manifest = tmp_path / "manifest.json"
    assert manifest.exists()
    assert json.loads(manifest.read_text(encoding="utf-8")) == {
        "topicFiles": [expected_name]
    }


def test_write_topics_keeps_unicode_unescaped(tmp_path):
    topic = build_topic(
        topic_id="accents",
        title="Être",
        sort_order=3,
        prerequisite_id=None,
        rule_note="Garde les accents : é à ç.",
        exercises=[_valid_exercise()],
    )
    write_topics([topic], str(tmp_path))
    raw = (tmp_path / "03_accents.json").read_text(encoding="utf-8")
    assert "é à ç" in raw  # ensure_ascii=False keeps real accents
