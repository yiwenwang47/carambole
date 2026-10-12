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
- [ ] Author (2 agents/module)  - [ ] Gloss scan + assemble  - [ ] Judges  - [ ] Fixers  - [ ] Vocab audit  - [ ] 9-card review set v8
