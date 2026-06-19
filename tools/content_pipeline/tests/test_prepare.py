"""Tests for batch preparation: attach topic id + stable exercise id to each seed."""
from content_pipeline.seeds import make_seeds
from content_pipeline.prepare import seed_record


def test_seed_record_attaches_topic_id_and_stable_id():
    seed = make_seeds("parler", "indicatif", "présent")[0]  # je
    rec = seed_record(seed)
    assert rec["topicID"] == "indicatif_present"
    assert rec["id"] == "indicatif_present_parler_0"
    # the seed payload is preserved for the contract echo
    assert rec["correct_form"] == "parle"
    assert rec["distractors"] == seed.distractors


def test_seed_record_ids_are_unique_across_persons():
    recs = [seed_record(s) for s in make_seeds("être", "indicatif", "imparfait")]
    ids = [r["id"] for r in recs]
    assert len(set(ids)) == len(ids) == 6
