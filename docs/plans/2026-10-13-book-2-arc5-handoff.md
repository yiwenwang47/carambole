# Book 2 handoff: start here (arc 5)

**Written:** 2026-10-13, end of session.
**Repo:** `carambole/`, branch `main`, **not pushed**.
**Previous start point:** [audio handoff](2026-10-13-book-2-audio-handoff.md). Arc 4 is complete (its §6).
**Still binding:**
- [Audio handoff](2026-10-13-book-2-audio-handoff.md) §3–§4: the gloss rule, the gloss decisions in `words.json`, the tools and lessons.
- [Next-session handoff](2026-10-13-book-2-next-session-handoff.md) §4–§5: pipeline lessons, audio commands and zsh gotchas.
- [Content handoff](2026-10-11-book-2-content-handoff.md): the rulebook. §9 has the Test book build and phone install commands.
- `tools/situations/README.md` and `tools/situations/agents/*.md`.

## 1. Start here: arc 5 (modules 21–25), the last arc

The planner is done. Its output:
- [Arc 5 plan](2026-10-13-book-2-arc5-plan.md): §11 is the step-by-step batch procedure, §12 the open questions.
- Matrices: [21](2026-10-13-book-2-arc5-module-21-matrix.md), [22](2026-10-13-book-2-arc5-module-22-matrix.md), [23](2026-10-13-book-2-arc5-module-23-matrix.md), [24](2026-10-13-book-2-arc5-module-24-matrix.md), [25](2026-10-13-book-2-arc5-module-25-matrix.md).
- The planner's validator passed all 600 rows: 0 errors, 0 unglossed tokens.

**First step next session:** ask the user to OK the plan §12 defaults (or change some). They have not answered yet, except question 8 (below). Then follow plan §11:

1. Coordinator prep: `modules.json` 21–25, *déçu* in `MASC_SELF` with a test, base keys *s'il fait beau / s'il pleut / plus tôt*.
2. 2 authors per module (10), about 7 at a time. Authors run the gloss self-check (`gloss_dump.py`) and report "gloss dump read: N lines, M fixes".
3. Gloss conflict scan, `assemble.py 21 22 23 24 25`, lints and tests.
4. 4 judges per module (20), each given its moves' gloss dump.
5. Fixers, then one coordinator gloss pass book-wide, the *Fondations* audit, a gloss-dump spot check.
6. Review set v11 (9 cards, plan §11 step 6), simulator frames, phone only if asked, user verdict.
7. Production audio: `--module` 21–25, then a plain run; strict `lint.py`; `normalize_audio.py`.

**Usage limit:** the planner hit the monthly spend limit once this session (the user raised it). Resume a stopped agent with SendMessage; it keeps its context.

### Module overview

| # | Title | Moves |
|---|---|---|
| 21 | *Donner son avis* | opinion, film, food, area, ask, strong, mixed, formal |
| 22 | *D'accord ou pas* | chores, agree, disagree, soften, turns, deal, complain, settle |
| 23 | *Expliquer pourquoi* | why, because, so, example, purpose, explain, lyon, refuse |
| 24 | *Et si… ?* | pont, etsi, weather, planb, book, dream, budget, decide |
| 25 | *Un week-end qui déraille* | annonce, repair, gite, lost, home, group, bright, tell |

25 new words per module (125 in all). No word from 01–20 moves. Inside arc 5, *au cas où* is taught in 23, not 24.

### Question 8, answered: grammar outside *Fondations*

The user asked why arc 5 leaves out the past conditional, the passive and *ne… que*, then accepted the answer:
- Book 2 uses only *Fondations* grammar (Book 1's 25 topics). None of these is taught there. The plus-que-parfait, the gérondif, *venir de* and *le mien / le tien* are left out for the same reason.
- *ne… que* also breaks the gloss rule: *n'est* = "is (n'est pas = isn't)" and *que* = "that / which / than" are both wrong in « ce n'est qu'un week-end », and no single key can carry "only".

## 2. State

| Area | State |
|---|---|
| Content | 20 of 25 modules (2,400 items): authored, judged, fixed, assembled. |
| Audio | Complete for 01–20: 5,278/5,278 clips (`aab4732e`). Strict lint OK. All 7,933 clips tagged as normalised. |
| Review sets | v7–v10 approved. v10 (`5ee04c7e`) has production clips from 16–20: "sounds ok". |
| Phone | Test book: v10. Main Carambole app: NOT reinstalled; install it only when the user asks. |
| Checks | 87 Python tests OK (run with `python3 -m unittest discover -s tools/situations -p "test_*.py"`; pytest collects nothing). Pilot tests PASS. |

## 3. Lessons this session

- **Review sets can play production audio.** The Test book plays `pilot2_<id>_…` clips. After production audio exists, copy the production clips byte for byte to the `pilot2_` names instead of running `generate_audio.py --review` (TTS gives a different take each time). Import with `from tools.situations.generate_audio import …` from the repo root; a bare `import generate_audio` clashes with `tools/pilot/generate_audio.py`.
- **`normalize_audio.py --all --check` ignores the tag.** It re-measures processed clips and reports small drifts (0.5–0.7 dB) as "would re-encode". To check, count untagged clips with `is_tagged()` instead; this session found 0.
- **`gloss_dump.py` wants a module JSON.** For a review set, wrap the dialogues in `{"id", "elements": [{"items": [...]}]}`. The words file is `carambole/Resources/Situations/words.json`.

## 4. After arc 5: what is left for Book 2

Arc 5 finishes the **content** (25 of 25 modules). The release work (action plan, Task 7) is still open:
- Release verification: old DB, new install, offline, both books' learn/review/history/settings, audio interruption, small screens.
- The History page doesn't show attempt-log rows yet.
- VoiceOver is only partly labelled.
- Main Carambole app reinstall on the phone (only when the user asks).
- Push `main`.
- The Écrire typing drill: later, in its own session.
