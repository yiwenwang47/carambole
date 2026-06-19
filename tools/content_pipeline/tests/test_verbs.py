"""Tests for the common-verb seed list."""
from content_pipeline.verbs import COMMON_VERBS


def test_non_empty():
    assert len(COMMON_VERBS) > 0


def test_reasonable_size():
    # ~80-120 common infinitives.
    assert 80 <= len(COMMON_VERBS) <= 120


def test_all_lowercase_non_empty_strings():
    for v in COMMON_VERBS:
        assert isinstance(v, str)
        assert v
        assert v == v.lower()
        assert v.strip() == v


def test_no_duplicates():
    assert len(COMMON_VERBS) == len(set(COMMON_VERBS))


def test_includes_core_auxiliaries():
    assert "être" in COMMON_VERBS
    assert "avoir" in COMMON_VERBS


def test_starts_with_high_frequency_verbs():
    # Frequency-ordered: the two auxiliaries lead.
    assert COMMON_VERBS[0] == "être"
    assert COMMON_VERBS[1] == "avoir"
