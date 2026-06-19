"""Seed-consistency contract for LLM-generated exercises.

The generation step is allowed to write only the natural sentence, the English
translation and the hint. The answer and the option bank are LOCKED to the
deterministic seed, so a hallucinated conjugation can never ship.

`check_against_seed` returns a list of error strings (empty = the exercise both
passes the base schema AND faithfully reflects its seed).
"""
from __future__ import annotations

import re

from content_pipeline.validate import validate_exercise


def check_against_seed(ex: dict, seed: dict) -> list[str]:
    errors = list(validate_exercise(ex))

    correct = seed["correct_form"]
    expected_bank = {correct, *seed["distractors"]}

    if ex.get("answerTokens") != [correct]:
        errors.append(
            f"answer must equal the seed correct_form {correct!r}, "
            f"got {ex.get('answerTokens')!r}"
        )

    if set(ex.get("tokenBank", [])) != expected_bank:
        errors.append(
            f"tokenBank must be exactly the seed forms {sorted(expected_bank)}, "
            f"got {sorted(set(ex.get('tokenBank', [])))}"
        )

    prompt = ex.get("prompt", "")
    if "___" not in prompt:
        errors.append("prompt must contain the blank '___'")

    pronoun = seed["pronoun"]
    if not re.search(rf"\b{re.escape(pronoun)}\b", prompt, flags=re.IGNORECASE):
        errors.append(f"prompt must contain the subject pronoun {pronoun!r}")

    if ex.get("cue") != seed["verb"]:
        errors.append(
            f"cue must be the infinitive {seed['verb']!r}, got {ex.get('cue')!r}"
        )

    return errors
