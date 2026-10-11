# Planner spec: one batch (arc) of Book 2 modules

You plan a batch of 4–6 Book 2 (*En situation*) modules on paper, before anyone writes French.

**Repo:** `/Users/yiwenwang/Documents/CMU/research/personal/carambole/carambole`

**You write only:**
- `docs/plans/<date>-book-2-<arc>-module-NN-matrix.md`, one per module
- `docs/plans/<date>-book-2-<arc>-plan.md`, one overview

Everything else is read-only. Don't commit.

## Read first

- The current batch handoff
- `docs/plans/2026-10-11-book-2-content-handoff.md` §3–§8
- `docs/plans/2026-10-11-book-2-cafe-handoff.md` §3
- The syllabus table in `docs/plans/2026-10-11-book-2-action-plan.md`
- The arc 1 plan and matrices (`docs/plans/2026-10-11-book-2-arc1-*.md`): copy their format
- `tools/situations/README.md`
- `tools/situations/modules.json`
- `carambole/Resources/Situations/words.json`: what is already taught, and where

## Each module

- **Size.** 8 moves (`sit_NN_<move>`, move names in lowercase a–z only). Each move has 10 dialogues and 5 standalones, one of each: Construire, Choisir le ton, Corriger, Transformer, Mot en retour.
- **Drill mix per move:**
  - at least 4 drill types;
  - Répondre + Compléter make up at least half the dialogue drills;
  - at least 1 clarification or repetition dialogue (never "repeat" for a text or voicemail);
  - at least 2 dialogues on another channel or making a social move.
- **Per dialogue.** 1–2 drills, no repeated type, no Répondre + Choisir together, and no same type back to back across item boundaries.
- **Splitting the work.** Split the moves into a first half (moves 1–4) and a second half (5–8), one author agent each. Each new word is owned by the half where it first appears. Keep each word's recurrences and its Mot drill inside its own move, so the halves never depend on each other.

## Vocabulary

- **Base words** are *Fondations* words (grep `carambole/Resources/Topics/*.json`).
- **Load.** About 25–40 new words per module, and at most 1–2 new words per server line.
- **Book order.** Words taught in earlier modules are known. A word first taught in a later module must not be used at all.
- **Café clash.** If a word café (06) teaches would be needed in a module before 06, plan where it moves earlier.
- **Glosses.** Reuse the `en` / `spoken` / `audio` values in `words.json` exactly for shared words.

## Cast and fixed facts

- **Robin, the learner:** a woman from Eugene, Oregon. The first mention is « Eugene, dans l'Oregon ». Her lines are feminine only.
- **Léa, Inès, Théo:** *tu*.
- **M. Ferrand, Mme Dumas:** *vous* always.
- **Karim:** *vous* until café move `usual`, *tu* after it.
- **Canonical `name` strings:** "Léa", "Inès", "Théo", "Karim", "M. Ferrand", "Mme Dumas". One-off people have no name; they may use `voice: "female"`.
- **Register.** Spoken forms appear mainly in *tu* exchanges. No slang, no verlan, no texting abbreviations.

## Design against the known judge-found error classes

- cue leaks and answer echo
- follow-ups that ignore the learner
- hidden valid replies
- false errors
- logic puzzles
- untaught words used early
- place labels that don't match the cue
- masculine forms for Robin

## Overview doc

It covers:
- each module's move list, with a one-line rationale per move;
- the word progression across modules;
- any café or earlier-module words that move;
- the *Fondations* grammar each module recycles;
- the `modules.json` entries, ready to paste;
- open questions for the user.

## Report

Move lists, word changes, per-module totals, and open questions.
