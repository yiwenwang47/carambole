# Book 2 handoff: start here next session

**Date:** 2026-10-11, end of session
**Repo:** `/Users/yiwenwang/Documents/CMU/research/personal/carambole/carambole`, branch `main`, **not pushed** (many commits ahead of origin).
**Supersedes as the starting point:**
- the [arc-1 handoff](2026-10-11-book-2-arc1-handoff.md), which has the detail of how arc 1 was built;
- the [café handoff](2026-10-11-book-2-cafe-handoff.md).

The rulebook is still the [content handoff](2026-10-11-book-2-content-handoff.md). §3 was updated this session: Robin is a woman, and her lines are feminine only.

## 1. State

| Area | State |
|---|---|
| Content | 6 of 25 modules are authored, reviewed and in `situations_manifest.json`: 01–05 (arc « Arriver à Lyon ») and 06 *Au café*. That is 720 items and 700 glossed words, 159 of them taught. |
| Audio | Complete for all 6 modules: 1,751 clips, and the strict lint passes. This session used about 40k API characters, roughly $1–2 at list price; Google's free monthly allowance may cover it, which is unverified. |
| App | *En situation* is on the shelf, with per-book progress and settings (schema v5, additive). `SituationSessionView` loads every manifest module. A Corriger error word inside a set phrase is now tappable. |
| Test book | Review set v5 (9 arc-1 cards, all six engines, the new voices). It is installed on the iPhone 18 Pro, but in a build from before the Robin rename: card 1 still says Alex. The user said no need to reinstall. |
| Checks | `lint.py` (strict) OK · 70 Python tests OK · Grammalecte 1,927 lines, 0 flags · `SituationModelTests` PASS (720 items) · Test book pilot tests PASS. |

## 2. User decisions (binding)

These come on top of the content handoff §3.

1. **The learner is Robin, a woman, from Eugene, Oregon.**
   - The first mention in French is « Eugene, dans l'Oregon »; later mentions use « Eugene » or « l'Oregon ».
   - Her own lines use **feminine forms only**. Masculine forms are wrong answers and may appear as decoys.
   - Corriger may target her agreement. Others may call her « madame ».
   - When an answer hinges on her gender, the cue says "You're a woman." `lint.py` flags masculine self-forms.
2. **Voices.** Karim = Charon, Léa = Aoede, Théo = Achird, **M. Ferrand = Orus**, Inès = Despina, Mme Dumas = Gacrux (all Chirp3-HD). Anonymous male = Neural2-G; anonymous female = Neural2-F (`voice: "female"`).
   - M. Ferrand's voice was Algenib until this session. It left 1–1.6 s between sentences, and the user noticed.
   - When auditioning a voice, measure the gaps between sentences.
   - A one-word sentence (« Alex. ») makes any voice pause.
3. **The *tu* partners in module 03 stay unnamed.** There is no seventh cast voice.
4. **Underlines mean "new word here" only.** A word already taught is never underlined again; the café re-underlines were removed.
5. ***tout le monde, ah, oh, pas de problème, bonne journée, ça me va*** are glossed base words. They are not taught.
6. **The channel mix in 02, 04 and 05 stays** (42, 51 and 66 of 80 dialogues are not face to face), because the syllabus sets those modules in texts, group chat and calls.
7. **Karim** switches to *tu* inside café move `usual`, and uses *vous* everywhere before that.
8. **Review content in small sets** of about 9 cards. Author in bulk only after the user approves the batch's sample.
9. **Phone:** install only when the user asks; never test or record on the phone.

## 3. Not done yet

- **The user hasn't reviewed review set v5 in full.** So far they confirmed the new M. Ferrand voice works and made the decisions above. Ask whether the rest of v5 is approved before authoring the next batch, which memory says must wait.
- **19 modules:** 07–10 (the rest of « Le quartier »), then arcs 3–5 (11–25). See the syllabus in the [action plan](2026-10-11-book-2-action-plan.md).
- **Not checked by ear:**
  - The TTS may pronounce *Eugene* the French way, as « Eugène ».
  - The user hasn't spot-listened to the café audio or the arc-1 audio.
- **App gaps** (from Tasks 2–3):
  - Book 2's History page doesn't show the mistake log.
  - VoiceOver labels are only partly done.
  - After a wrong reply, Vérifier is enabled again straight away, so pressing it unchanged counts as the second try.
- **Still open from content handoff §10:** whether to build the Écrire typing drill in Swift, and whether to port the swipe-up "trop facile" change to the main app.
- **Module 03 teaches 24 words**, one under the ~25 floor (minor).

## 4. Pipeline for the next batch (tested on arc 1)

Prompts are in the repo: `tools/situations/agents/{planner,author,judge,fixer}.md`. Paste one into each agent's task with the specifics: module, half, files and output path.

1. **Plan.** One planner agent (`agents/planner.md`) writes the batch overview and one 120-row matrix per module. Read it, then add the `modules.json` entries.
2. **Author.** Two author agents per module (`agents/author.md`), one per half. Each writes only its own `drafts/NN_<slug>_{first,second}_half{,_words}.json`.
3. **Assemble (coordinator only).**
   - Harmonise glosses first: run a conflict scan over all `drafts/*_words.json` and `words.json`, comparing `en`, `spoken` and `audio` per `fr` key and checking audio-key collisions, then pick one wide gloss for each conflict.
   - Arc 1 had 33 conflicts; giving authors the shared base glosses up front would cut that.
   - Run `assemble.py`, then lint, the tests, `deep_lint.py` and the Swift model test.
4. **Judge.** Four judges per module (`agents/judge.md`), two moves each, read-only. They write findings to scratch files.
5. **Fix.** One fixer per draft half (`agents/fixer.md`). Fixers never edit existing glosses; the coordinator applies gloss changes to every `_words.json` (café drafts included), then reassembles.
6. **Audit vocabulary.** Grep every `firstSeen: null` word against `Resources/Topics/*.json`. Most misses are inflections or names; decide the rest.
7. **Review set.** `review_set.py <9 IDs>` in D D S order. Drill types must differ across item boundaries, and adjacent dialogues must have different drill pairs. Then run `generate_audio.py --review`, the pilot tests and a simulator check (look at frames).
8. **Production audio** only after the user approves the sample.
   - Run `generate_audio.py` in a retry loop; the API returns transient 503s.
   - **When a line changes, its clip must be deleted first**, because the generator skips existing files. Compare clip texts before and after (snippet in §6).

The judges' recurring finds, so authors can avoid them:
- hidden valid replies, mostly a reply without « Pardon ? » or with clauses swapped;
- standalone place labels set to the move's home place instead of the cue's setting;
- cue leaks and answer echo;
- a speaker answering their own question;
- « repeat » asked of a text message;
- glosses wrong in context;
- a phrase key matching across a comma (« avec moi, c'est tu » matches *moi c'est*).

## 5. Commits this session (on `main`)

`f7b36ac` café audio · `593f505` book-wide tooling · `a84aa97`/`f253a2e` production view (merged) · `9918c0e` arc-1 plan · `23e4010` arc-1 drafts · `fee8a7a` Corriger split + glosses · `64a520c` review fixes · `f01e03f` review set v5 · `a2b4c23` M. Ferrand = Orus · `6dcbd85` arc-1 audio · `7ac0bec` Robin / Eugene · `8284a72` feminine-only · plus docs commits.

## 6. Commands

```sh
rtk python3 tools/situations/assemble.py [NN …]
rtk python3 tools/situations/lint.py            # strict, with audio; --no-audio while drafting
rtk python3 -m unittest tools/situations/test_lint.py tools/situations/test_tools.py tools/pilot/test_content.py
rtk python3 tools/situations/deep_lint.py
swiftc carambole/Models/Situation.swift tools/situations/SituationModelTests.swift -o /tmp/cb-sit-model-tests && /tmp/cb-sit-model-tests carambole/Resources/Situations
rtk python3 tools/situations/review_set.py <nine IDs> && rtk python3 tools/situations/generate_audio.py --review
rtk python3 tools/situations/generate_audio.py --dry-run [--module NN]
# Test book: simulator build/launch flags and phone install commands are in the content handoff §9
```

Stale-clip check: map each audio key to its text with `item_clips()` from `tools/situations/generate_audio.py` (plus `words.json` for `sitw_*` keys). Map before and after editing, then delete `Resources/Audio/<key>.mp3` for every key whose text changed or disappeared.
