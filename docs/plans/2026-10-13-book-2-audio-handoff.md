# Book 2 handoff: arc 4 audio

> **Superseded as the start point by [arc 5 handoff](2026-10-13-book-2-arc5-handoff.md).** §3–§4 stay binding.

**Written:** 2026-10-12, end of session.
**Repo:** `carambole/`, branch `main`, **not pushed**.
**Previous start point:** [arc 4 handoff](2026-10-13-book-2-arc4-handoff.md). Its §5 is this session's step-by-step log.
**Still binding:**
- [Next-session handoff](2026-10-13-book-2-next-session-handoff.md) §4–§5: pipeline, lessons, audio commands and zsh gotchas.
- [Content handoff](2026-10-11-book-2-content-handoff.md): the rulebook. §9 has the Test book build and phone install commands.
- `tools/situations/README.md`: tools, plus the gloss rule (below).

## 1. Start here: production audio for arc 4

The user approved review set v9 on the phone: "v9 works". The only step left for arc 4 is audio.

```sh
cd carambole
df -h /                                            # check space first
python3 tools/situations/generate_audio.py --dry-run   # expect 1,296 missing of 5,278
for m in 16 17 18 19 20; do until python3 tools/situations/generate_audio.py --module $m; do sleep 10; done; done
until python3 tools/situations/generate_audio.py; do sleep 10; done   # base words + new phrase keys (firstSeen null)
python3 tools/situations/lint.py                   # strict, with audio: must print "OK: 20 situation module(s)"
python3 tools/situations/normalize_audio.py --all --check
```

- **What's missing:** 972 clips for modules 16–20 (192–197 per module), plus about 324 `firstSeen: null` word clips. Those include the ~126 new phrase keys the two gloss passes added book-wide (*il y avait*, *ce n'est pas grave*, *à samedi*, *on est*, *chez moi*, *le dimanche*, …).
- **Why the plain run:** `--module NN` skips `firstSeen: null` words, so the plain run is required.
- **zsh:** don't put the command in `$cmd` (zsh doesn't word-split). Retry on the API's 503s with `until`, as above.
- **Settings are unchanged:** Chirp 3 HD cast voices, `speakingRate` 0.9, loudness normalised. Gap lines are voiced with the answer filled in (hard rule).
- **Speed question:** the user asked whether the v9 clips were sped up. They weren't: v9 measured 13.9–15.2 chars/s against a book average of 13.0, and earlier review sets ranged 11.9–16.1. The short exclamations simply read briskly. The user didn't ask for a change, so keep 0.9.
- **Afterwards:** listen to a few 16–20 clips, commit `carambole/Resources/Audio`, and update `CLAUDE.md`.

## 2. State

| Area | State |
|---|---|
| Content | 20 of 25 modules (2,400 items): authored, judged, fixed, assembled. |
| Checks | `lint.py --no-audio` OK. Grammalecte: 6,272 lines, 0 flags. 87 Python tests OK. Swift model test PASS. Pilot tests PASS. |
| Glosses | Two book-wide passes over modules 01–20 (below). Every MUST resolved. |
| Audio | 01–15 complete. 16–20 and the new keys are missing (§1). Strict lint fails only on missing audio. No 01–15 clip changed text this session (checked). |
| Review sets | v7, v8 and v9 approved. v9 is on the phone (Test book). |
| Phone | Test book: v9. Main Carambole app: NOT reinstalled; install it only when the user asks. |

## 3. What this session did (arc 4)

1. **Planner** → plan + 5 matrices. The user accepted all defaults.
2. **Prep** (`3702e9a`):
   - Added `modules.json` 16–20.
   - Added the lint roles « Agent immobilier / Agente immobilière ».
   - `MASC_SELF` now also catches « je me suis … » and *couché, tombé, épuisé, trempé, convaincu, sûr*.
3. **Authors** (10, about 7 at a time). Then the gloss conflict scan and assembly (`e28c8f2`).
   - Module 04 decoy « ça vous dit, » became « vous voulez », because module 19 now teaches *ça vous dit*.
4. **Judges** (20) → findings in `docs/plans/arc4-judges/`. **Fixers** (10) → `e57fcd2` and the module 20 commit.
5. **Book-wide gloss pass 1** (`763b66b`): `docs/plans/arc4-judges/gloss_spec.json`.
6. **Gloss sweep of all 20 modules** (one checker per module) → `docs/plans/gloss-sweep/NN.md`.
   - It found 24 MUST findings and about 140 SHOULD findings.
   - **Pass 2** (`abfbf56`): `docs/plans/gloss-sweep/spec2.json` + `spec2_notes.md`. 57 widenings, 84 new keys, 1 rewrite (02 morning_d07 « Non ! Plus ___ »).
7. **Vocab audit:** of the new base entries, 115 single words are not literally in *Fondations*. All are inflections of taught words, decoys, parts of taught phrases or proper nouns. No action.
8. **Review set v9** (`d56babc`): checked on the simulator, installed on the phone, approved.

### Gloss rule (user, 2026-10-12): every gloss must be correct in every drill

**How the app splits lines.** Each key has one book-wide gloss.
- The app (`SituationText.segments`) matches the longest key first, left to right.
- A key can span a comma, but not a free-standing « ! » « ? » « : » or a `___` gap.

**Tools:**
- `tools/situations/gloss_dump.py` prints every tappable line with each token's gloss, split the same way.
- `tools/situations/apply_gloss_spec.py` applies `{"widen", "add"}` specs to all draft words files and `words.json`. Rewrites stay manual. Run `assemble.py` afterwards.

**Decisions now in `words.json`:**
- **Negation:** *n'*-forms show the plain verb with a note, e.g. *n'est* = "is (n'est pas = isn't)". *ne* and *pas* carry negation notes. There is no bare « pas de » key, because « pas de Lyon » means "not from".
- **Past tense with *être*:** être forms note the passé composé, e.g. *suis* = "am (je suis allée = I went)".
- ***à* + weekday:** literal sense first: *à samedi* = "to Saturday (À samedi ! = see you Saturday)".
- **Phrase keys:** *on est / on a / on fait / on dit*, *le dimanche* (= on Sundays), *le matin*, *chez moi/toi/lui*, *il faut*, *il y avait*, *il n'y a pas (de)* / *plus (de)*, *si j'étais vous/toi* and others.
- **No `de la` key:** it would swallow « de la voir ». *de* is widened instead.
- **Comma-spanning keys:** only *moi c'est* is intended. *non plus* and *merci de* were fixed: the first by a line rewrite, the second by the new key *non merci*.

**In the agent prompts:** `judge.md` check 8, plus `author.md` and `fixer.md`, now carry this rule.

## 4. Lessons

- **Judges and the dump:** give judges the gloss dump. Before it, glosses were checked loosely; with it, they found about 20 wrong glosses per module group.
- **The dump must split exactly like the app.** Two dump bugs, now fixed, caused false flags: matching across `___` and across a free-standing « ! ».
- **One coordinator for book-wide gloss changes:** fixers rewrite lines, and the coordinator applies widenings and keys in one pass, so drafts don't conflict.
- **Usage limits:** about 7 agents at a time again ran without hitting limits.

## 5. Open / later

- Arc 5 (modules 21–25): same pipeline. The planner must use the new gloss decisions (§3) and give authors the gloss-dump self-check.
- Main Carambole app reinstall: only when the user asks.
- Écrire typing drill: later, in its own session.
- History page does not show attempt-log rows yet. VoiceOver is only partly labelled.
- `main` is not pushed.

## 6. Done (2026-10-13)

- Production audio for arc 4: `aab4732e`. 5,278/5,278 clips; strict lint OK; every clip tagged as normalised (median -18.1 LUFS, same as 01–15).
- Review set v10 (`5ee04c7e`): sit_17_cheer_d06 sit_19_compromise_d08 sit_17_galere_s04 sit_16_out_d02 sit_20_should_d10 sit_18_better_s02 sit_18_rent_d03 sit_16_dinner_d04 sit_17_react_s05. The `pilot2_*` clips are byte copies of the production clips. Installed in the Test book; user verdict: "sounds ok".
- Arc 4 is complete. Next: arc 5 (§5).
