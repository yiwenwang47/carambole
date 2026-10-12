# Book 2 handoff — 2026-10-12 session (start here)

Supersedes `2026-10-11-book-2-next-session-handoff.md` as the starting point (its §2 decisions, §4 pipeline and §6 commands still apply). Working on `main`, not pushed.

## Progress this session
- [x] 1. Gap clips voiced complete (hard rule)
- [x] 2. Test book reinstall (done) — v7 verdict still pending
- [x] 3. Production audio 07–10: 799 clips + 248 glossed base-word clips (firstSeen null, missed by `--module`); strict lint OK, 10 modules
- [x] 4. Ask user: gender decoys (« une / pull noire ») keep or drop?

## Log
- **Item 1 done.** `generate_audio.py`: `spoken_line()` fills `___` with the `complete` drill's correct choice (raises if a gap line has no complete drill). 30 stale clips deleted + regenerated (29 `sit_0[1-6]_*`, 1 `pilot2_sit_09_voicemail_s05_t0`), normalised. 9 module-09/07/08 gap clips were never generated — they come out right with the 07–10 production run. Tests: `test_gap_line_is_voiced_with_its_answer`, `test_no_shipped_clip_text_has_a_gap` (corpus-wide). App: play button on the gap line is disabled (dimmed) until the gap is settled, in `SituationSessionView` and the Test book pilot — the clip would otherwise speak the answer. No autoplay exists (replay only). Build EXIT 0, 77 Python tests OK, Swift model test PASS, lint `--no-audio` OK. Not checked on the simulator by eye.
- **User answers (2026-10-12):** gender decoys (« une / pull noire ») → **keep** (item 4 closed). v7 → not reviewed yet (item 3 waits). Test book reinstall → yes, now.
- **Item 2:** Test book installed on the iPhone 18 Pro (2026-10-12): v7 + calmer Théo + complete gap clips + locked gap play button. Sim frames checked first (card 9 voicemail: play dimmed while gap empty, active after « bip »). Main Carambole app NOT reinstalled.

## Next session
1. Ask the user for the v7 verdict (they hadn't reviewed it on 2026-10-12).
2. On approval: production audio 07–10 — `for m in 7 8 9 10; do until python3 tools/situations/generate_audio.py --module $m; do sleep 5; done; done` (503 retries); then strict `lint.py` must pass. This also produces the 9 gap clips for 07–09 (complete by construction).
3. Then arc 3 (modules 11–15), pipeline in the 2026-10-11 handoff §4.
4. Main app reinstall only when the user says so.
- **2026-10-12: user said v7 "works" → approved.** Production audio 07–10 started.

## Arc 3 (modules 11–15) — started 2026-10-12
Pipeline = 2026-10-11 handoff §4. Status:
- [x] Plan: `docs/plans/2026-10-12-book-2-arc3-plan.md` + 5 matrices (126 new words, 600 rows checked by planner script). Open questions in plan §12 (defaults given); `modules.json` entries in plan, not pasted yet
- [x] Prep (`ae2a4a9`): modules.json 11–15, « mal » gloss widened, « t'inquiète » spoken, arc-3 roles
- [x] Author (2 agents/module) — all 10 halves done, drafts committed; 10 agents launched 2026-10-12; outputs `tools/situations/drafts/1[1-5]_*_{first,second}_half{,_words}.json`. If interrupted: rerun only halves whose files are missing/fail `lint.py --draft`  - [x] Gloss scan (0 conflicts; fixed audio clash `annules` → `sitw_annules_verb`) + assemble: 15 modules / 1,800 items; lint --no-audio OK, Grammalecte 4,713 lines 0 flags (13 late_d04 split « …minutes. Désolée ! »), tests OK, Swift model PASS. Strict lint fails only on missing 11–15 audio (waits for v8 approval)  - [ ] Judges  - [ ] Fixers  - [ ] Vocab audit  - [ ] 9-card review set v8
- User 2026-10-12: accept all arc-3 plan defaults; author all 5 modules then v8.
- 2026-10-12 17:10: all 10 authors hit the usage limit mid-run; partial drafts on disk (11 both halves, 13 second, 14 first, 14 second w/o words, 15 first). Resumed all 10 with context. Drafts are untracked until assemble — if lost again, relaunch only halves whose files fail `lint.py --draft`.
- 11 first half DONE (lint/full lint/Grammalecte OK). Coordinator todo: `partie` new base gloss; Compléter answer-slot bias (13/24 in slot 1) matters only for Test book pilot (no shuffle) — check before v8.
- 14 first half DONE (all checks OK). New base: `j'étais`. Cross-module entries copied (t'inquiète, prends soin de toi, j'espère, soin, réunion, cet après-midi) — verify against 11/12/13 drafts in gloss scan.
- 12 first half DONE (all OK). Matrix audio-key clash répare/réparé → `sitw_repare_past`; told 12b to do `sitw_derange_past`. New base: chaudes, chauds, couler, coulez, après-midi.
- 11 second half DONE (all OK). New base: `télétravail` "remote work (en télétravail = working from home)".
- 13 first half DONE. New base: `ne t'inquiète pas` (not spoken), bloqués/bloquer/ratés; audio-key clash commence/commencé → `sitw_commence_past`. Grammalecte false positive `late_d04` « Plutôt vingt minutes, désolée ! » (Robin) → needs a deep_lint suppression entry at assemble. Judges: « il y a une grève » vs 11's « il y a grève ».
- 12 second half DONE (all OK; glosses consistent with 11 + 12a). 
- Coordinator todo: lint `MASC_SELF` flags the masculine error word inside Corriger error lines, though decision §2.1 says Corriger may target Robin's agreement. Three authors worked around it (11 arrive_s03, 13 wait_s03, 12 landlady_s03 « vraiment désolé »). Plan: exempt the turn's `error` token from MASC_SELF (+ test); optionally restore matrix wording in fixer pass.
- 14 second half DONE (all OK). New base: l'apportes, l'apporter, guéries. Judges: sick_s03 « mal » choice marginal.
- 13 second half DONE (all OK). New base: pourrai, obligés, obliger, espères, espérer, reportez, reportée.
- 15 second half DONE (all OK). New base: réparée, crevés, pareilles, gratuits, gratuites; `sitw_remplace_past`.
- Lint: MASC_SELF now checks Corriger error lines with the fix applied (`corrected()`, test added). Workarounds in 11/12/13 may be restored to matrix wording by fixers (optional).
- 15 first half DONE. New base key « pas trop court » (else « pas trop » swallows it, « court » = runs); `sitw_coupe_past`.
- [x] Judges: all 20 done (findings in docs/plans/arc3-judges/); 20 launched; findings → scratchpad/judges/NN_<m1>_<m2>.md, copied to docs/plans/arc3-judges/ when done
- 2026-10-12 ~22:10: all 20 judges hit the usage limit before writing findings; resumed. If lost: relaunch judges per tools/situations/agents/judge.md, 2 moves each (list: 11 strike/cancelled, delay/desk, group/another, work/arrive; 12 boiler/leak, plumber/keys, neighbour/broken, landlady/visit; 13 late/sorry, reason/wait, cancel/newplan, react/formal; 14 symptom/cold, pharmacy/advice, appointment/doctor, sick/better; 15 parcel/wrong, complain/haircut, bike/repair, again/fix). Consider batches of ~7 to stay under limits.
- Note: 13 late_d04 « Désolée ! Plutôt vingt minutes. » now buildable after my sentence split → fixer must add to accepted (judge MUST).
- Fixers launched for 11, 12, 14 (both halves; judge reports in docs/plans/arc3-judges/). 13 + 15 fixers wait on remaining judges (13 reason/wait, 15 ×4).
- Coordinator gloss todos (apply book-wide after fixers): « place » → add seat/room; « regarder/regarde/regardes » → add "look (at), check"; « (wrong form of j'espère/t'inquiète) » → "(wrong form)"; « rapporte » narrow. Plus fixer reports' lists.
- 15 second half: 15 Comprendre drills had correct=1 pointing at the false choice (author moved the index, not the choices). Coordinator swapped choices+why → true answer now at slot 1. Judges' MUSTs on these are DONE.
- Gloss todo add: « fait » → add "done, made"; « un tout petit peu » key.
- Fixer 14a DONE (23 findings applied, lint+Grammalecte clean).
- Fixer 12a DONE (all findings; leak now always in kitchen; new base `écrire`). Gloss notes: « de » partitive, « l' » pronoun.
