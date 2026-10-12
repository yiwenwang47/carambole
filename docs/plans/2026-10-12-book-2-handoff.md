# Book 2 handoff — 2026-10-12 session (start here)

Supersedes `2026-10-11-book-2-next-session-handoff.md` as the starting point (its §2 decisions, §4 pipeline and §6 commands still apply). Working on `main`, not pushed.

## Progress this session
- [x] 1. Gap clips voiced complete (hard rule)
- [ ] 2. Test book reinstall + v7 verdict (needs user)
- [ ] 3. Production audio 07–10 (after v7 approval)
- [ ] 4. Ask user: gender decoys (« une / pull noire ») keep or drop?

## Log
- **Item 1 done.** `generate_audio.py`: `spoken_line()` fills `___` with the `complete` drill's correct choice (raises if a gap line has no complete drill). 30 stale clips deleted + regenerated (29 `sit_0[1-6]_*`, 1 `pilot2_sit_09_voicemail_s05_t0`), normalised. 9 module-09/07/08 gap clips were never generated — they come out right with the 07–10 production run. Tests: `test_gap_line_is_voiced_with_its_answer`, `test_no_shipped_clip_text_has_a_gap` (corpus-wide). App: play button on the gap line is disabled (dimmed) until the gap is settled, in `SituationSessionView` and the Test book pilot — the clip would otherwise speak the answer. No autoplay exists (replay only). Build EXIT 0, 77 Python tests OK, Swift model test PASS, lint `--no-audio` OK. Not checked on the simulator by eye.
