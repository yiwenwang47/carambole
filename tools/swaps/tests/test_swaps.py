import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest  # noqa: E402

import swaps as S  # noqa: E402


@pytest.mark.unit
def test_pairable_by_class_and_form() -> None:
    assert S.pairable('la', 'le').startswith('class:')
    assert S.pairable('amis', 'amies') == 'form'
    assert S.pairable('ici', 'là') is None          # synonyms: only all_positions catches them
    assert S.pairable('la', 'la') is None


@pytest.mark.unit
def test_surface_problem_blocks_second_errors() -> None:
    assert S.surface_problem('Je', "l'", 'livre', 'le') == 'elided-before-consonant'
    assert S.surface_problem('Je', 'le', 'ai', "l'") is None        # « le ai » is the target error
    assert S.surface_problem('Je', 'la', 'aime', 'le') == 'needs-elision'
    assert S.surface_problem('Il', 'à', 'le', 'dans') == 'needs-contraction'
    assert S.surface_problem("J'", 'suis', None, 'ai') == 'prev-elided-before-consonant'
    assert S.surface_problem('Il', 'mange', None, 'mangent') is None


@pytest.mark.unit
def test_match_case() -> None:
    assert S.match_case('un', 'Une', 0) == 'Un'
    assert S.match_case('La', 'le', 2) == 'la'


@pytest.mark.unit
def test_tokenize_blank_marks_slot() -> None:
    toks, slot = S.tokenize_blank('Complète : « Nous ___ ici. »')
    assert toks[slot] == '\u0001'
    assert toks[:slot] == ['Nous'] and toks[slot + 1:] == ['ici', '.']
    assert S.tokenize_blank('Complète : « ___ et ___ »') is None


@pytest.mark.unit
def test_swaps_for_finds_gender_twin() -> None:
    d = S.Drill('m', 'e', {'id': 'x', 'prompt': 'Construis : « We are not friends. »',
                           'answerTokens': ['nous', 'ne', 'sommes', 'pas', 'amis'],
                           'tokenBank': ['nous', 'ne', 'sommes', 'pas', 'amis', 'amies'],
                           'inputMode': 'buildFromTokens'})
    texts = {sw.text for sw in S.swaps_for(d, set())}
    assert 'nous ne sommes pas amies' in texts
