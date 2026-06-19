"""Validate a generated exercise against the app's `Exercise` schema + drill invariants.

`validate_exercise` returns a list of human-readable error strings; an empty list
means the exercise is structurally sound and safe to ship into a topic JSON.
"""
from __future__ import annotations

TYPES = {"conjugate", "fillBlank", "genderArticle", "wordOrder"}
INPUT_MODES = {"multipleChoice", "buildFromTokens"}

# Keys that must be present and non-null. `cue` and `hint` are optional/nullable.
REQUIRED = (
    "id",
    "topicID",
    "type",
    "prompt",
    "answerTokens",
    "tokenBank",
    "inputMode",
    "explanation",
    "translation",
)


def validate_exercise(ex: dict) -> list[str]:
    errors: list[str] = []

    for key in REQUIRED:
        if key not in ex or ex[key] is None:
            errors.append(f"missing required key: {key}")
    if errors:
        # Don't probe deeper into a structurally incomplete exercise.
        return errors

    for key in ("id", "topicID", "explanation", "translation"):
        if not isinstance(ex[key], str) or not ex[key].strip():
            errors.append(f"{key} must be a non-empty string")

    if not isinstance(ex["prompt"], str) or not ex["prompt"].strip():
        errors.append("prompt must be a non-empty string")

    if ex["type"] not in TYPES:
        errors.append(f"unknown type: {ex['type']!r} (allowed: {sorted(TYPES)})")

    if ex["inputMode"] not in INPUT_MODES:
        errors.append(
            f"unknown inputMode: {ex['inputMode']!r} (allowed: {sorted(INPUT_MODES)})"
        )

    answer = ex["answerTokens"]
    bank = ex["tokenBank"]
    if not isinstance(answer, list) or not answer:
        errors.append("answerTokens must be a non-empty list")
        answer = []
    if not isinstance(bank, list) or not bank:
        errors.append("tokenBank must be a non-empty list")
        bank = []
    if any(not isinstance(t, str) or not t for t in answer):
        errors.append("answerTokens must contain only non-empty strings")

    if ex["inputMode"] == "multipleChoice":
        if len(answer) != 1:
            errors.append("multipleChoice answerTokens must be a single token")
        elif answer[0] not in bank:
            errors.append("multipleChoice answer is not present in tokenBank")
    elif ex["inputMode"] == "buildFromTokens":
        missing = [t for t in answer if t not in bank]
        if missing:
            errors.append(f"answerTokens not in tokenBank: {missing}")

    return errors
