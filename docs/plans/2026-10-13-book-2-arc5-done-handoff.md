# Book 2 handoff: start here (arc 5 content done)

**Written:** 2026-10-13, end of session.
**Repo:** `carambole/`, branch `main`, **not pushed**.
**Previous start point:** [arc 5 handoff](2026-10-13-book-2-arc5-handoff.md). Its plan §11 steps 1–6 are now done.
**Still binding:**
- [Audio handoff](2026-10-13-book-2-audio-handoff.md) §3–§4: the gloss rule, the gloss decisions in `words.json`, the tools and lessons.
- [Next-session handoff](2026-10-13-book-2-next-session-handoff.md) §4–§5: pipeline lessons, audio commands and zsh gotchas.
- [Content handoff](2026-10-11-book-2-content-handoff.md): the rulebook. §9 has the Test book build and phone install commands.
- [Arc 5 plan](2026-10-13-book-2-arc5-plan.md) §12: the user approved all its defaults this session.

## 1. Start here: production audio for 21–25

The user played review set v11 in the simulator and said "works". The next step is plan §11 step 7:

1. Run `generate_audio.py --module NN` for 21, 22, 23, 24 and 25 (193–194 clips each).
2. Run one plain `generate_audio.py`. It makes the remaining word clips: the arc 5 base keys, inflections and decoys, and the new book-wide phrase keys (§3).
3. Run strict `lint.py` (no `--no-audio`).
4. Run `normalize_audio.py`. Check for untagged clips with `is_tagged()`, not `--all --check` (see the audio handoff).
5. Optional: copy the new production clips byte for byte over the v11 `pilot2_` clips, as the v10 set did, and ask the user to listen.

The dry run before this step: 5,278 of 6,459 clips present, 1,181 missing (967 module clips plus about 214 word clips).

Before a big audio job, check `df -h /`. Resume a stopped agent with SendMessage.

## 2. State

| Area | State |
|---|---|
| Content | **25 of 25 modules** (3,000 items, 200 moves): authored, judged, fixed, assembled. `words.json` has 2,194 entries. |
| Audio | 01–20 complete. 21–25 have only the 12 review clips (`pilot2_sit_2x_…`). |
| Review sets | v7–v11 approved. v11 = `sit_24_pont_d01 sit_23_lyon_d03 sit_21_formal_s03 sit_22_chores_d04 sit_25_annonce_d02 sit_24_dream_s04 sit_22_turns_d06 sit_25_repair_d05 sit_23_purpose_s03`. |
| Simulator | Test book v11 installed on the iPhone 18 Pro sim (iOS 27.0). |
| Phone | Test book still v10. Main Carambole app not reinstalled. Install either only when the user asks. |
| Checks | `lint.py --no-audio`: OK, 25 modules. 88 Python tests OK. Swift model test PASS (3,000 items). Grammalecte: 0 flags in 21–25. Pilot tests PASS. |

## 3. What changed this session

**Coordinator prep (step 1):**
- `modules.json`: entries 21–25, arc « Échanger ».
- `MASC_SELF` in `lint.py` now includes *déçu*, with a test.
- *s'il pleut* is a base key, placed in module 18's words (18 `decide d09` uses it).
- *s'il fait beau* and *plus tôt* could not be pre-added (see §4). Authors added them when used.

**Authoring, judging, fixing (steps 2–5):**
- 10 authors, then 20 judges, then 10 fixers.
- The judges found 13 MUSTs: mostly hidden valid replies, untaught built words, « autrement dit » with nothing to rephrase, and logic errors.
- All judge findings are applied except the skips each fixer reported (all optional NITs, or NITs that would break line limits).

**Book-wide gloss pass (one `apply_gloss_spec.py` run):**
- Widened:
  - *repose*, *propriétaire* ("owner, landlord / landlady"), *congé*, *vous prenez* ("(vous)", not "(polite)");
  - *fermait, prenait, allait, faisait* (with an « et si on … = how about we … » note);
  - *exagérez*, *ensembles*, *ça va mieux*, *envoie*;
  - *souvenir* (its old note gave away « bon »).
- New keys (`firstSeen: null`): *vous a plu, vous avez tort, à quoi, à côté du, c'est dommage, on avait, sous la pluie, t'as raison*.
  - *t'as raison* is `spoken: true` and is now in `SPOKEN` in `lint.py`.
  - *à côté du* and *c'est dommage* also change tap glosses in shipped modules 01, 04, 05, 07, 10, 16, 18, 19 and 23. All of these were re-read and are correct.
- Not done on purpose:
  - Widening *à* book-wide. Only one line needed « à quoi », so it got a key.
  - *maison* = "house, home". It is in 117 lines, and "home" reads correctly.

**Gender-cue audit:** six items whose answer depends on Robin's feminine form now have "You're a woman." in the cue: 12 `neighbour_d08`, 13 `cancel_d01`, 13 `cancel_d10`, 18 `decide_s04`, 23 `refuse_d08` and 24 `pont_s01`. The audit was a script over all choices and banks.

***Fondations* audit:** 214 new `firstSeen: null` entries.
- Most are inflections of taught words, wrong-form decoys ("(wrong form of …)", an established convention) or phrase keys built from base words.
- The judges replaced the untaught words that weren't near misses: *gars, muse, partout, drôlement, quinze, dedans*.
- Kept, because the planner's matrices approved them:
  - look-alike decoys: *plaine, domaine, dommages, biens, idéal, rapidement*;
  - printed words: *bars, connus, vide, date, mai, portables, recommence, impossible, seulement*.
- Raise this with the user if they ask.

## 4. Lessons this session

- **Subagents can't write report files.** The harness blocks Write ("Subagents should return findings as text"), and most judges refused to route around it with Bash. Ask judges to put the full findings list in their final message, and have the coordinator save it for the fixers.
- **`apply_gloss_spec.py` can't add a key that no draft line uses yet.** It reports "unused". Base keys planned for new modules go to the authors instead, as exact entries to copy into their words file.
- **`apply_gloss_spec.py` writes new keys with `spoken: false`.** For a spoken key, flip it in the draft words file and add it to `SPOKEN` in `lint.py`, or lint fails.
- **Judge fixes can break line limits.** These are 10 words per dialogue line and 8–14 per standalone. Fixers must re-count and adapt. Several did (`explain d01/d10`, `bright_s04`, `gite_s01`, `decide_d09`).
- **`deep_lint.py` only runs on manifest modules.** Fixers ran Grammalecte through its renderer on a scratch module.
- **Plan-sanctioned decoys still trip judges.** Next time, ask the planner to use only *Fondations* words or near-miss inflections for decoys.

## 5. After audio: what is left for Book 2

Release work (action plan, Task 7):
- Release verification: old DB, new install, offline, both books' learn/review/history/settings, audio interruption, small screens.
- The History page doesn't show attempt-log rows yet.
- VoiceOver is only partly labelled.
- Main Carambole app reinstall on the phone (only when the user asks).
- Push `main`.
- The Écrire typing drill: later, in its own session.
